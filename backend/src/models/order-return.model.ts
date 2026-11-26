import { supabase } from '../config/supabase.js';
import {
  OrderModel,
  SO_NGAY_DUOC_TRA_HANG,
  thoiDiemNhanHang,
  type OrderRow,
} from './order.model.js';

export interface OrderReturnRow {
  id: string;
  order_id: string;
  user_id: string;
  shop_id?: string | null;
  reason: string;
  proof_images: string[];
  status: string;
  refund_amount: number;
  rejection_reason?: string | null;
  admin_resolution_note?: string | null;
  /** true: hang con ban duoc va da nhap lai kho; false: hang loi. */
  restocked?: boolean | null;
  /** 'refund' doi lai tien, 'exchange' chi doi size. */
  request_type?: string;
  exchange_variant_id?: string | null;
  returned_variant_id?: string | null;
  created_at: string;
  resolved_at?: string | null;
}

export interface CreateOrderReturnInput {
  orderId: string;
  userId: string;
  reason: string;
  proofImages?: string[];
  files?: Express.Multer.File[];
  refundAmount?: number;
  shopId?: string | null;
  /** 'refund' doi lai tien, 'exchange' chi doi size. Mac dinh 'refund'. */
  requestType?: string;
  /** Size khach muon doi sang. Bat buoc khi requestType = 'exchange'. */
  exchangeVariantId?: string | null;
  /** Size khach dang giu va muon tra lai. */
  returnedVariantId?: string | null;
}

const RETURN_BUCKET = 'review-images';
const MAX_PROOF_IMAGES = 5;
const RETURNABLE_STATUSES = ['delivered', 'completed'];
/**
 * Do dai toi thieu cua ly do tra hang.
 *
 * Chan truong hop khach chon "Khác" roi khong ghi gi, luc do ly do gui len
 * dung mot chu "Khác" va nguoi duyet khong biet hang bi sao. Moi ly do co san
 * khac deu dai hon nguong nay.
 *
 * De nguong thap vua du chan "Khác" (4 ky tu) chu khong dat cao hon: ung dung
 * da chan ky o man hinh roi, day chi la luoi do cho ai goi thang API, khong
 * nen tu choi nham mot mo ta ngan nhung that nhu "Khác: bẩn".
 */
const DO_DAI_LY_DO_TOI_THIEU = 8;
const OPEN_RETURN_STATUSES = ['requested', 'shop_approved', 'admin_dispute_review'];

// Lop truy cap du lieu cho: Tra hang
export class OrderReturnModel {
  protected db = supabase;
  private orderModel = new OrderModel();
  private bucketEnsured = false;

  async createReturnRequest(input: CreateOrderReturnInput): Promise<OrderReturnRow> {
    const reason = input.reason?.trim();
    if (!reason) {
      throw new Error('Vui lòng nhập lý do trả hàng');
    }
    if (reason.length < DO_DAI_LY_DO_TOI_THIEU) {
      throw new Error(
        `Lý do trả hàng quá ngắn, vui lòng mô tả rõ hơn (ít nhất ${DO_DAI_LY_DO_TOI_THIEU} ký tự)`,
      );
    }

    const order = await this.orderModel.getOrderById(input.orderId, input.userId);
    if (!order) {
      throw new Error('Không tìm thấy đơn hàng của bạn');
    }
    if (!RETURNABLE_STATUSES.includes(order.status)) {
      throw new Error('Chỉ có thể trả hàng khi đơn đã giao');
    }

    // Qua han thi khong nhan nua. Phai chan o day chu khong chi an nut trong
    // ung dung, vi goi thang API van tao duoc yeu cau.
    const nhanHangLuc = thoiDiemNhanHang(order.order_status_history);
    if (nhanHangLuc) {
      const han = new Date(nhanHangLuc).getTime() + SO_NGAY_DUOC_TRA_HANG * 24 * 60 * 60 * 1000;
      if (Date.now() > han) {
        throw new Error(
          `Đã quá ${SO_NGAY_DUOC_TRA_HANG} ngày kể từ khi nhận hàng nên không gửi được yêu cầu trả hàng`,
        );
      }
    }

    const openReturn = await this.findOpenByOrder(input.orderId, input.userId);
    if (openReturn) {
      throw new Error('Đơn hàng này đã có yêu cầu trả hàng đang xử lý');
    }

    // Don da hoan tien mot lan roi thi khong nhan yeu cau thu hai: trang thai
    // don van la 'delivered' nen khong co gi chan, ma duyet lan nua se hoan
    // tien lan hai va cong kho lan hai cho cung mot lo hang.
    const { data: daHoanTien, error: loiKiemTra } = await this.db
      .from('order_returns')
      .select('id')
      .eq('order_id', input.orderId)
      .eq('status', 'refunded')
      .limit(1);
    if (loiKiemTra) throw new Error(loiKiemTra.message);
    if ((daHoanTien ?? []).length > 0) {
      throw new Error('Đơn hàng này đã được hoàn tiền trả hàng trước đó');
    }

    const loaiYeuCau = input.requestType === 'exchange' ? 'exchange' : 'refund';
    const bienTheMuonDoi = input.exchangeVariantId?.trim() || null;
    const bienTheTra = input.returnedVariantId?.trim() || null;

    if (loaiYeuCau === 'exchange') {
      if (!bienTheMuonDoi) {
        throw new Error('Đổi size thì phải chọn size muốn đổi sang');
      }
      if (bienTheMuonDoi === bienTheTra) {
        throw new Error('Size muốn đổi phải khác size đang có');
      }
      await this.kiemTraBienTheDoiDuoc(input.orderId, bienTheMuonDoi, bienTheTra);
    }

    const uploaded = await this.uploadImages(input.userId, input.files ?? []);
    const images = [...(Array.isArray(input.proofImages) ? input.proofImages : []), ...uploaded]
      .map((url) => String(url).trim())
      .filter(Boolean);

    if (images.length === 0) {
      throw new Error('Vui lòng đính kèm ít nhất 1 hình ảnh minh chứng');
    }
    if (images.length > MAX_PROOF_IMAGES) {
      throw new Error(`Chỉ được đính kèm tối đa ${MAX_PROOF_IMAGES} ảnh`);
    }

    const { data, error } = await this.db
      .from('order_returns')
      .insert({
        order_id: order.id,
        user_id: input.userId,
        shop_id: input.shopId ?? null,
        reason,
        proof_images: images,
        refund_amount: Number(order.total ?? input.refundAmount ?? 0),
        status: 'requested',
        request_type: loaiYeuCau,
        exchange_variant_id: bienTheMuonDoi,
        returned_variant_id: bienTheTra,
      })
      .select()
      .single();

    if (error || !data) {
      throw new Error(error?.message ?? 'Không thể tạo yêu cầu trả hàng');
    }

    await this.notifyReturnCreated(order);
    return this.normalize(data);
  }

  /**
   * Size khach muon doi sang co doi duoc that khong.
   *
   * Ba dieu kien, thieu cai nao cung thanh ra duyet xong khong lay hang ra gui
   * duoc:
   *   - Bien the do con ton kho.
   *   - No thuoc cung san pham voi mon khach da mua, khong phai doi sang mon
   *     khac gia.
   *   - Mon khach tra lai that su nam trong don nay.
   */
  private async kiemTraBienTheDoiDuoc(
    orderId: string,
    bienTheMuonDoi: string,
    bienTheTra: string | null,
  ): Promise<void> {
    const { data: dongTrongDon, error: loiDon } = await this.db
      .from('order_items')
      .select('variant_id, product_variants(product_id)')
      .eq('order_id', orderId);
    if (loiDon) throw new Error(loiDon.message);

    const cacDong = dongTrongDon ?? [];
    if (bienTheTra && !cacDong.some((dong: any) => dong.variant_id === bienTheTra)) {
      throw new Error('Sản phẩm muốn trả không có trong đơn hàng này');
    }

    const { data: bienThe, error: loiBienThe } = await this.db
      .from('product_variants')
      .select('id, stock, product_id, size, color')
      .eq('id', bienTheMuonDoi)
      .maybeSingle();
    if (loiBienThe) throw new Error(loiBienThe.message);
    if (!bienThe) throw new Error('Không tìm thấy size muốn đổi sang');

    if ((bienThe.stock ?? 0) <= 0) {
      throw new Error(`Size ${bienThe.size} đã hết hàng, không đổi sang được`);
    }

    const cacSanPhamTrongDon = cacDong
      .map((dong: any) => dong.product_variants?.product_id)
      .filter(Boolean);
    if (
      cacSanPhamTrongDon.length > 0 &&
      !cacSanPhamTrongDon.includes(bienThe.product_id)
    ) {
      throw new Error('Chỉ đổi được sang size khác của cùng sản phẩm');
    }
  }

  /**
   * Chuyen kho khi duyet doi size: tra lai mon cu, lay ra mon moi.
   *
   * Hai dong nhat ky deu mang ly do 'exchange' va cung order_id, nen sau nay
   * nhin vao kho la biet hai lan chuyen nay thuoc cung mot viec doi size chu
   * khong phai hai lan chinh kho roi rac.
   */
  private async chuyenKhoDoiSize(
    yeuCau: { id: string; order_id: string; exchange_variant_id?: string | null; returned_variant_id?: string | null },
    hangTraConBanDuoc: boolean,
    actorId?: string,
  ): Promise<void> {
    const bienTheMoi = yeuCau.exchange_variant_id;
    if (!bienTheMoi) {
      throw new Error('Yêu cầu đổi size này không ghi size muốn đổi sang');
    }

    // Chua tung chuyen kho cho lan doi size nay thi moi lam, bam duyet hai lan
    // khong duoc tru kho hai lan.
    const { data: daChuyen, error: loiKiemTra } = await this.db
      .from('inventory_movements')
      .select('id')
      .eq('order_id', yeuCau.order_id)
      .eq('reason', 'exchange')
      .limit(1);
    if (loiKiemTra) throw new Error(loiKiemTra.message);
    if ((daChuyen ?? []).length > 0) return;

    // Lay size moi ra giao cho khach.
    await this.congTonKho(bienTheMoi, -1, yeuCau.order_id, actorId, 'exchange',
      'Đổi size: lấy hàng size mới ra giao');

    // Size cu nhan lai: con ban duoc thi cong vao kho, hong thi chi ghi nhat ky
    // de con truy, khong cong so luong.
    const bienTheCu = yeuCau.returned_variant_id;
    if (!bienTheCu) return;

    if (hangTraConBanDuoc) {
      await this.congTonKho(bienTheCu, 1, yeuCau.order_id, actorId, 'exchange',
        'Đổi size: nhận lại hàng size cũ, còn bán được');
    } else {
      await this.ghiNhatKyKhongDoiKho(bienTheCu, yeuCau.order_id, actorId,
        'Đổi size: hàng size cũ bị lỗi, không nhập lại kho');
    }
  }

  async findByUser(userId: string): Promise<OrderReturnRow[]> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => this.normalize(row));
  }

  async findOpenByOrder(orderId: string, userId: string): Promise<OrderReturnRow | null> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .eq('order_id', orderId)
      .eq('user_id', userId)
      .in('status', OPEN_RETURN_STATUSES)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data ? this.normalize(data) : null;
  }

  async findById(id: string, userId?: string): Promise<OrderReturnRow | null> {
    let query = this.db.from('order_returns').select('*').eq('id', id);
    if (userId) query = query.eq('user_id', userId);

    const { data, error } = await query.maybeSingle();
    if (error) throw new Error(error.message);
    return data ? this.normalize(data) : null;
  }

  async listAll(): Promise<OrderReturnRow[]> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => this.normalize(row));
  }

  /**
   * Cong lai kho cho tung mon trong don tra hang.
   *
   * Chi goi khi nguoi duyet xac nhan hang con ban duoc. Hang loi thi khong
   * goi ham nay: so hang do da bi tru luc khach dat va khong quay lai kho.
   */
  private async nhapLaiKho(orderId: string, actorId?: string): Promise<void> {
    // Nhat ky kho la bang chung don nay da duoc nhap lai hay chua. Nho no ma
    // bam duyet lai, hoac luu trang thai that bai roi thu lai, deu khong cong
    // kho them lan nua.
    const { data: daNhap, error: loiKiemTra } = await this.db
      .from('inventory_movements')
      .select('id')
      .eq('order_id', orderId)
      .eq('reason', 'return')
      .limit(1);
    if (loiKiemTra) throw new Error(loiKiemTra.message);
    if ((daNhap ?? []).length > 0) return;

    const { data: items, error } = await this.db
      .from('order_items')
      .select('variant_id, quantity')
      .eq('order_id', orderId);
    if (error) throw new Error(error.message);

    for (const item of items ?? []) {
      // Bien the co the da bi xoa khoi danh muc, luc do variant_id la null va
      // khong con cho nao de cong vao.
      if (!item.variant_id) continue;
      await this.congTonKho(item.variant_id, item.quantity, orderId, actorId);
    }
  }

  /**
   * Cong them mot so luong vao ton kho cua mot bien the.
   *
   * Doc roi ghi de thang se nuot mat don hang dat xen vao giua, nen lenh ghi
   * phai kem dieu kien "ton kho van dung bang so vua doc". Khong khop thi doc
   * lai va thu lai, giong cach man Kho dang lam.
   */
  private async congTonKho(
    variantId: string,
    soLuong: number,
    orderId: string,
    actorId?: string,
    lyDo: 'return' | 'exchange' | 'damaged' = 'return',
    ghiChu = 'Hàng trả còn bán được, nhập lại kho',
  ): Promise<void> {
    for (let lan = 0; lan < 3; lan += 1) {
      const { data: bienThe, error: loiDoc } = await this.db
        .from('product_variants')
        .select('stock')
        .eq('id', variantId)
        .maybeSingle();
      if (loiDoc) throw new Error(loiDoc.message);
      if (!bienThe) return;

      const tonMoi = bienThe.stock + soLuong;
      if (tonMoi < 0) {
        throw new Error('Tồn kho không đủ để thực hiện thao tác này');
      }

      const { data: daGhi, error: loiCong } = await this.db
        .from('product_variants')
        .update({ stock: tonMoi })
        .eq('id', variantId)
        .eq('stock', bienThe.stock)
        .select('id')
        .maybeSingle();
      if (loiCong) throw new Error(loiCong.message);
      if (!daGhi) continue; // Co thao tac khac vua doi ton kho, doc lai roi thu lai.

      const { error: loiNhatKy } = await this.db.from('inventory_movements').insert({
        variant_id: variantId,
        change: soLuong,
        reason: lyDo,
        order_id: orderId,
        created_by: actorId || null,
        note: ghiChu,
      });
      if (loiNhatKy) throw new Error(loiNhatKy.message);
      return;
    }

    throw new Error('Tồn kho đang được thao tác bởi người khác, vui lòng thử lại');
  }

  /**
   * Ghi mot dong nhat ky kho ma khong doi so luong ton.
   *
   * Dung cho hang tra ve bi loi: no da roi kho tu luc khach dat, khong quay
   * lai nua nen ton kho khong doi. Nhung neu khong ghi gi thi mon hang do bien
   * mat khong dau vet - cuoi thang khong biet hong bao nhieu, va cung khong
   * doi chieu duoc khi kiem ke thieu hang.
   */
  private async ghiNhatKyKhongDoiKho(
    variantId: string,
    orderId: string,
    actorId: string | undefined,
    ghiChu: string,
  ): Promise<void> {
    const { error } = await this.db.from('inventory_movements').insert({
      variant_id: variantId,
      change: 0,
      reason: 'damaged' as const,
      order_id: orderId,
      created_by: actorId || null,
      note: ghiChu,
    });
    // Co so du lieu chua chay 13_hang_hong_va_doi_size.sql thi chua co ly do
    // 'damaged'. Van cho luong duyet chay tiep, chi thieu dong nhat ky.
    if (error) {
      const thieuLyDo = error.message.toLowerCase().includes('damaged');
      if (!thieuLyDo) throw new Error(error.message);
      console.error('Chua co ly do kho "damaged", bo qua ghi nhat ky hang hong');
    }
  }

  /**
   * Ghi nhat ky "hang hong" cho tung mon trong don tra hang.
   *
   * Goi khi nguoi duyet xac nhan hang loi: kho khong cong them mon nao, nhung
   * moi mon deu co mot dong de sau nay con truy ra.
   */
  private async ghiNhatKyHangHongCuaDon(
    orderId: string,
    actorId?: string,
  ): Promise<void> {
    const { data: daGhi, error: loiKiemTra } = await this.db
      .from('inventory_movements')
      .select('id')
      .eq('order_id', orderId)
      .eq('reason', 'damaged')
      .limit(1);
    // Chua co ly do 'damaged' trong co so du lieu thi thoi, khong chan viec duyet.
    if (loiKiemTra) return;
    if ((daGhi ?? []).length > 0) return;

    const { data: items, error } = await this.db
      .from('order_items')
      .select('variant_id, quantity')
      .eq('order_id', orderId);
    if (error) throw new Error(error.message);

    for (const item of items ?? []) {
      if (!item.variant_id) continue;
      await this.ghiNhatKyKhongDoiKho(
        item.variant_id,
        orderId,
        actorId,
        `Hàng trả bị lỗi, không nhập lại kho (${item.quantity} cái)`,
      );
    }
  }

  async updateStatus(
    id: string,
    payload: {
      status: string;
      rejectionReason?: string | null;
      adminResolutionNote?: string | null;
      /** Hang tra con ban duoc khong. Chi co nghia khi chuyen sang 'refunded'. */
      restock?: boolean;
      actorId?: string;
    }
  ): Promise<OrderReturnRow | null> {
    const { data: hienTai, error: loiDoc } = await this.db
      .from('order_returns')
      .select(
        'id, order_id, status, request_type, exchange_variant_id, returned_variant_id',
      )
      .eq('id', id)
      .maybeSingle();
    if (loiDoc) throw new Error(loiDoc.message);
    if (!hienTai) return null;

    // Chi nhap lai kho dung mot lan, ngay khi don chuyen sang da hoan tien.
    // Bam duyet lai lan nua se khong cong them nua.
    const laLanHoanTienDauTien =
      payload.status === 'refunded' && hienTai.status !== 'refunded';
    if (laLanHoanTienDauTien) {
      if (payload.restock === true) {
        await this.nhapLaiKho(hienTai.order_id, payload.actorId);
      } else if (payload.restock === false) {
        // Hang loi: kho khong cong them, nhung van phai de lai dau vet. Truoc
        // day nhanh nay khong ghi gi ca nen hang hong bien mat khong vet.
        await this.ghiNhatKyHangHongCuaDon(hienTai.order_id, payload.actorId);
      }
    }

    // Duyet doi size: khong dong den tien, chi chuyen hang giua hai bien the.
    const laLanDoiSizeDauTien =
      payload.status === 'exchanged' && hienTai.status !== 'exchanged';
    if (laLanDoiSizeDauTien) {
      if (hienTai.request_type !== 'exchange') {
        throw new Error('Yêu cầu này là đòi hoàn tiền, không phải đổi size');
      }
      await this.chuyenKhoDoiSize(
        hienTai as any,
        payload.restock !== false,
        payload.actorId,
      );
    }

    const thayDoi: Record<string, string | boolean | null> = {
      status: payload.status,
      rejection_reason: payload.rejectionReason ?? null,
      admin_resolution_note: payload.adminResolutionNote ?? null,
      resolved_at: ['refunded', 'rejected', 'exchanged'].includes(payload.status)
        ? new Date().toISOString()
        : null,
    };
    if (
      ['refunded', 'exchanged'].includes(payload.status) &&
      payload.restock !== undefined
    ) {
      thayDoi.restocked = payload.restock;
    }

    const { data, error } = await this.db
      .from('order_returns')
      .update(thayDoi)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      // Co so du lieu chua chay 09_tra_hang_nhap_kho.sql thi chua co cot
      // restocked. Van luu duoc trang thai, chi thieu ghi chu con ban duoc.
      const thieuCot = error.message.toLowerCase().includes('restocked');
      if (!thieuCot) throw new Error(error.message);

      delete thayDoi.restocked;
      const { data: lanHai, error: loiLanHai } = await this.db
        .from('order_returns')
        .update(thayDoi)
        .eq('id', id)
        .select()
        .single();
      if (loiLanHai) throw new Error(loiLanHai.message);
      return lanHai ? this.normalize(lanHai) : null;
    }

    return data ? this.normalize(data) : null;
  }

  private async uploadImages(userId: string, files: Express.Multer.File[]): Promise<string[]> {
    if (!files.length) return [];

    await this.ensureBucketExists();

    const urls: string[] = [];
    for (const file of files.slice(0, MAX_PROOF_IMAGES)) {
      const extMatch = file.originalname.match(/\.([a-zA-Z0-9]+)$/);
      const ext = extMatch ? extMatch[1].toLowerCase() : file.mimetype.split('/')[1] || 'jpg';
      const fileName = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
      const filePath = `returns/${userId}/${fileName}`;

      const { error } = await this.db.storage.from(RETURN_BUCKET).upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

      if (error) {
        throw new Error(`Không tải được ảnh minh chứng: ${error.message}`);
      }

      const { data } = this.db.storage.from(RETURN_BUCKET).getPublicUrl(filePath);
      urls.push(data.publicUrl);
    }

    return urls;
  }

  private async ensureBucketExists() {
    if (this.bucketEnsured) return;
    try {
      const { data: buckets } = await this.db.storage.listBuckets();
      const exists = buckets?.some((b) => b.name === RETURN_BUCKET);
      if (!exists) {
        await this.db.storage.createBucket(RETURN_BUCKET, {
          public: true,
          fileSizeLimit: 5 * 1024 * 1024,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
        });
      }
      this.bucketEnsured = true;
    } catch {
      this.bucketEnsured = true;
    }
  }

  private async notifyReturnCreated(order: OrderRow): Promise<void> {
    const { error } = await this.db.from('notifications').insert({
      user_id: order.user_id,
      title: 'Đã gửi yêu cầu trả hàng',
      body: `Yêu cầu trả hàng cho đơn #${order.code} đã được ghi nhận. Menly sẽ phản hồi sớm.`,
      type: 'order',
      data: { order_id: order.id, code: order.code },
    });
    if (error) {
      console.error('Khong tao duoc thong bao tra hang:', error.message);
    }
  }

  private normalize(row: Record<string, unknown>): OrderReturnRow {
    const rawImages = row.proof_images;
    let proofImages: string[] = [];
    if (Array.isArray(rawImages)) {
      proofImages = rawImages.map((item) => String(item)).filter(Boolean);
    } else if (typeof rawImages === 'string' && rawImages.trim()) {
      try {
        const parsed = JSON.parse(rawImages);
        proofImages = Array.isArray(parsed) ? parsed.map((item) => String(item)).filter(Boolean) : [rawImages];
      } catch {
        proofImages = [rawImages];
      }
    }

    return {
      ...(row as unknown as OrderReturnRow),
      proof_images: proofImages,
      refund_amount: Number(row.refund_amount ?? 0),
    };
  }
}
