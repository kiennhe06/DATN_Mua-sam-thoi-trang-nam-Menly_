'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Header } from '../../components/Header';
import {
  AlertCircle,
  CheckCheck,
  ChevronUp,
  Clock,
  MessagesSquare,
  Search,
  Send,
  User,
} from 'lucide-react';
import {
  SupportConversation,
  SupportMessage,
  closeSupportConversation,
  fetchSupportConversations,
  fetchSupportMessages,
  pingSupportTyping,
  sendSupportMessage,
} from '../../lib/api';
import { docNguoiDangNhap } from '../../lib/admin-session';

/**
 * Hoi thoai va tin nhan tu lam moi theo nhip nay.
 *
 * 2 giay de tin nhan va dong "dang soan" den gan nhu tuc thi. Vong lam moi chi
 * xin nhung tin moi nen tang nhip van nhe.
 */
const NHIP_LAM_MOI_MS = 2000;

/** Go phim thi bao len may chu, nhung nhieu nhat bay nhieu mili giay mot lan. */
const GIAN_CACH_BAO_SOAN_MS = 3000;

/** So tin tai moi lan, ca lan mo man lan khi bam xem tin cu hon. */
const SO_TIN_MOI_LAN = 50;

/** Cach day duoi bao nhieu pixel thi van coi la dang xem tin moi nhat. */
const NGUONG_SAT_DAY_PX = 120;

/** Tien to ma cua tin dang cho may chu xac nhan. */
const TIEN_TO_TIN_TAM = 'tam_';

function dinhDangGio(iso: string): string {
  if (!iso) return '';
  const thoiDiem = new Date(iso);
  if (Number.isNaN(thoiDiem.getTime())) return '';
  return thoiDiem.toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
  });
}

function tenKhach(hoiThoai: SupportConversation): string {
  return hoiThoai.customerName || hoiThoai.customerEmail || 'Khách hàng';
}

function laBenShop(tin: SupportMessage): boolean {
  return tin.senderRole === 'staff' || tin.senderRole === 'admin';
}

/** Bo dau tieng Viet de go "duc kien" van tim ra "Đức Kiên". */
function boDau(chuoi: string): string {
  return chuoi
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase();
}

/**
 * Gop tin moi vao danh sach dang co, loai trung theo id.
 *
 * May chu lay tin bang >= moc nen tin o ranh gioi se ve hai lan; gop theo id
 * vua loai trung vua cap nhat duoc trang thai da doc cua tin cu.
 */
function gopTin(dangCo: SupportMessage[], veThem: SupportMessage[]): SupportMessage[] {
  if (veThem.length === 0) return dangCo;
  const theoId = new Map(dangCo.map((tin) => [tin.id, tin]));
  for (const tin of veThem) theoId.set(tin.id, tin);
  return [...theoId.values()].sort((a, b) => a.createdAt.localeCompare(b.createdAt));
}

/**
 * Moc thoi gian de xin tin moi.
 *
 * Thuong la tin cuoi cung. Nhung neu minh con tin chua duoc doc thi phai lui
 * moc ve tin do, khong thi nhan "Da xem" cua no se khong bao gio sang.
 */
function mocXinTinMoi(danhSach: SupportMessage[]): string | undefined {
  if (danhSach.length === 0) return undefined;
  const cuoi = danhSach[danhSach.length - 1].createdAt;
  const chuaDoc = danhSach
    .filter((tin) => laBenShop(tin) && !tin.isRead)
    .map((tin) => tin.createdAt);
  if (chuaDoc.length === 0) return cuoi;
  return [...chuaDoc, cuoi].sort()[0];
}

export default function ChatPage() {
  const [hoiThoaiList, setHoiThoaiList] = useState<SupportConversation[]>([]);
  const [dangChon, setDangChon] = useState<string | null>(null);
  const [tinNhan, setTinNhan] = useState<SupportMessage[]>([]);
  const [noiDung, setNoiDung] = useState('');
  const [tuKhoa, setTuKhoa] = useState('');
  const [dangTaiDanhSach, setDangTaiDanhSach] = useState(true);
  const [dangTaiTinNhan, setDangTaiTinNhan] = useState(false);
  const [dangTaiTinCu, setDangTaiTinCu] = useState(false);
  const [conTinCu, setConTinCu] = useState(false);
  const [dangGui, setDangGui] = useState(false);
  const [dangDong, setDangDong] = useState(false);
  const [loi, setLoi] = useState<string | null>(null);
  const [idCuaToi, setIdCuaToi] = useState<string | null>(null);
  const [khachDangSoan, setKhachDangSoan] = useState(false);

  const khungTin = useRef<HTMLDivElement | null>(null);
  const lanBaoSoan = useRef(0);
  const dangXemTinMoi = useRef(true);

  // Vong lam moi chay trong setInterval nen khong nhin thay state moi nhat.
  // Giu ban sao o ref de no biet dang co nhung tin nao ma xin dung doan.
  const tinNhanRef = useRef<SupportMessage[]>([]);
  useEffect(() => {
    tinNhanRef.current = tinNhan;
  }, [tinNhan]);

  useEffect(() => {
    setIdCuaToi(docNguoiDangNhap()?.id ?? null);
  }, []);

  const taiDanhSach = useCallback(async (im = false) => {
    if (!im) setDangTaiDanhSach(true);
    try {
      const danhSach = await fetchSupportConversations();
      setHoiThoaiList(danhSach);
      setLoi(null);
      setDangChon((truoc) => truoc ?? danhSach[0]?.id ?? null);
    } catch (error) {
      setLoi(error instanceof Error ? error.message : 'Không tải được danh sách hội thoại.');
    } finally {
      if (!im) setDangTaiDanhSach(false);
    }
  }, []);

  /** Mo mot hoi thoai: lay cac tin moi nhat, thay sach danh sach cu. */
  const moHoiThoai = useCallback(async (hoiThoaiId: string) => {
    setDangTaiTinNhan(true);
    try {
      const ketQua = await fetchSupportMessages(hoiThoaiId, { limit: SO_TIN_MOI_LAN });
      setTinNhan(ketQua.messages);
      setKhachDangSoan(ketQua.typing.customer);
      setConTinCu(ketQua.conTinCu);
      dangXemTinMoi.current = true;
      setLoi(null);
    } catch (error) {
      setLoi(error instanceof Error ? error.message : 'Không tải được tin nhắn.');
    } finally {
      setDangTaiTinNhan(false);
    }
  }, []);

  /** Vong lam moi: chi xin nhung tin tu moc cuoi tro di. */
  const lamMoiTin = useCallback(async (hoiThoaiId: string) => {
    try {
      const ketQua = await fetchSupportMessages(hoiThoaiId, {
        tuMoc: mocXinTinMoi(tinNhanRef.current),
        limit: SO_TIN_MOI_LAN,
      });
      setTinNhan((truoc) => gopTin(truoc, ketQua.messages));
      setKhachDangSoan(ketQua.typing.customer);
      setLoi(null);
    } catch (error) {
      setLoi(error instanceof Error ? error.message : 'Không tải được tin nhắn.');
    }
  }, []);

  /** Bam "xem tin cũ hơn": lay them mot doan phia truoc tin dau tien dang co. */
  async function taiTinCu() {
    const dauTien = tinNhan[0];
    if (!dangChon || !dauTien || dangTaiTinCu) return;
    setDangTaiTinCu(true);
    try {
      const ketQua = await fetchSupportMessages(dangChon, {
        truocMoc: dauTien.createdAt,
        limit: SO_TIN_MOI_LAN,
      });
      // Giu nguyen cho dang doc, khong keo man hinh ve day.
      dangXemTinMoi.current = false;
      setTinNhan((truoc) => gopTin(truoc, ketQua.messages));
      setConTinCu(ketQua.conTinCu);
    } catch (error) {
      setLoi(error instanceof Error ? error.message : 'Không tải được tin cũ.');
    } finally {
      setDangTaiTinCu(false);
    }
  }

  useEffect(() => {
    taiDanhSach();
    const dongHo = setInterval(() => taiDanhSach(true), NHIP_LAM_MOI_MS);
    return () => clearInterval(dongHo);
  }, [taiDanhSach]);

  useEffect(() => {
    if (!dangChon) return;
    setTinNhan([]);
    tinNhanRef.current = [];
    moHoiThoai(dangChon);
    const dongHo = setInterval(() => lamMoiTin(dangChon), NHIP_LAM_MOI_MS);
    return () => clearInterval(dongHo);
  }, [dangChon, moHoiThoai, lamMoiTin]);

  // Chi keo xuong khi nguoi dung dang doc tin moi nhat. Dang doc nguoc len
  // lich su ma cu 2 giay bi keo ve day thi khong doc duoc gi.
  useEffect(() => {
    if (!dangXemTinMoi.current) return;
    const khung = khungTin.current;
    if (khung) khung.scrollTop = khung.scrollHeight;
  }, [tinNhan, khachDangSoan]);

  function khiCuon() {
    const khung = khungTin.current;
    if (!khung) return;
    const conLai = khung.scrollHeight - khung.scrollTop - khung.clientHeight;
    dangXemTinMoi.current = conLai < NGUONG_SAT_DAY_PX;
  }

  /** Go phim thi bao len may chu, co gian cach de khong goi lien tuc. */
  function khiGoPhim(gia: string) {
    setNoiDung(gia);
    if (!dangChon || !gia.trim()) return;
    const bayGio = Date.now();
    if (bayGio - lanBaoSoan.current < GIAN_CACH_BAO_SOAN_MS) return;
    lanBaoSoan.current = bayGio;
    void pingSupportTyping(dangChon);
  }

  /**
   * Gui tin: hien bong chat ngay roi moi goi may chu.
   *
   * Truoc day phai cho may chu tra loi xong tin moi hien ra, moi lan gui treo
   * gan mot giay nhin nhu bi don. Gio hien truoc voi dau dong ho, nhan duoc
   * phan hoi thi thay bang tin that; that bai thi go ra va tra lai chu da go.
   */
  async function gui(su: React.FormEvent) {
    su.preventDefault();
    const chuoi = noiDung.trim();
    const hoiThoaiId = dangChon;
    if (!chuoi || !hoiThoaiId || dangGui) return;

    const maTam = `${TIEN_TO_TIN_TAM}${Date.now()}`;
    const tinTam: SupportMessage = {
      id: maTam,
      conversationId: hoiThoaiId,
      senderId: idCuaToi ?? '',
      senderRole: docNguoiDangNhap()?.role ?? 'staff',
      content: chuoi,
      createdAt: new Date().toISOString(),
      isRead: false,
    };

    setDangGui(true);
    dangXemTinMoi.current = true;
    setTinNhan((truoc) => gopTin(truoc, [tinTam]));
    setNoiDung('');
    lanBaoSoan.current = 0;

    try {
      const moi = await sendSupportMessage(hoiThoaiId, chuoi);
      setTinNhan((truoc) => gopTin(truoc.filter((tin) => tin.id !== maTam), [moi]));
      void taiDanhSach(true);
    } catch (error) {
      setTinNhan((truoc) => truoc.filter((tin) => tin.id !== maTam));
      setNoiDung(chuoi);
      setLoi(error instanceof Error ? error.message : 'Không gửi được tin nhắn.');
    } finally {
      setDangGui(false);
    }
  }

  /** Ket thuc hoi thoai dang mo, hoi lai mot cau truoc khi lam. */
  async function ketThucHoiThoai() {
    if (!hoiThoaiDangMo || dangDong) return;
    const dong = window.confirm(
      `Kết thúc hội thoại với ${tenKhach(hoiThoaiDangMo)}?\n\n` +
        'Hội thoại sẽ rời khỏi danh sách nhưng tin nhắn vẫn được giữ lại. ' +
        'Khách nhắn tiếp sẽ mở một hội thoại mới.',
    );
    if (!dong) return;

    setDangDong(true);
    try {
      await closeSupportConversation(hoiThoaiDangMo.id);
      setDangChon(null);
      setTinNhan([]);
      await taiDanhSach(true);
    } catch (error) {
      setLoi(error instanceof Error ? error.message : 'Không kết thúc được hội thoại.');
    } finally {
      setDangDong(false);
    }
  }

  const hoiThoaiDangMo = hoiThoaiList.find((item) => item.id === dangChon) ?? null;

  // Chi gan "Da xem" o tin cuoi cung cua ben shop, giong cac ung dung nhan tin.
  const idTinCuoiCuaShop =
    [...tinNhan].reverse().find(laBenShop)?.id ?? null;

  // Loc theo tu khoa roi dua hoi thoai con tin chua doc len dau, de nhan vien
  // truc khong phai doc het ca danh sach moi biet ai dang doi.
  const danhSachHienThi = useMemo(() => {
    const tu = boDau(tuKhoa.trim());
    const loc = tu
      ? hoiThoaiList.filter((item) =>
          boDau(`${item.customerName ?? ''} ${item.customerEmail ?? ''}`).includes(tu),
        )
      : hoiThoaiList;
    return [...loc].sort((a, b) => {
      if (a.unreadStaffCount !== b.unreadStaffCount) {
        return b.unreadStaffCount - a.unreadStaffCount;
      }
      return b.lastMessageAt.localeCompare(a.lastMessageAt);
    });
  }, [hoiThoaiList, tuKhoa]);

  const soKhachDangDoi = hoiThoaiList.filter((item) => item.unreadStaffCount > 0).length;

  return (
    <>
      <Header
        title="Chat CSKH"
        subtitle="Trả lời tin nhắn khách gửi từ ứng dụng Menly"
        onRefresh={() => {
          taiDanhSach();
          if (dangChon) moHoiThoai(dangChon);
        }}
      />

      <main className="flex-1 p-4 sm:p-6">
        {loi && (
          <div className="mb-3 flex items-center gap-2 rounded-xl border border-danger-line bg-danger-bg px-4 py-2.5 text-xs text-danger">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{loi}</span>
          </div>
        )}

        <div className="grid gap-4 lg:grid-cols-[300px_minmax(0,1fr)]">
          {/* Cot trai: danh sach hoi thoai */}
          <section className="flex max-h-[76vh] flex-col overflow-hidden rounded-2xl border border-line bg-panel shadow-xl">
            <div className="border-b border-line px-3.5 py-3">
              <h2 className="flex items-center gap-2 text-sm font-bold text-ink">
                <MessagesSquare className="h-4 w-4 text-camel-dark" />
                Hội thoại
                <span className="ml-auto text-[11px] font-semibold text-ink-muted">
                  {hoiThoaiList.length}
                </span>
              </h2>
              {soKhachDangDoi > 0 && (
                <p className="mt-0.5 text-[11px] font-semibold text-danger">
                  {soKhachDangDoi} khách đang chờ trả lời
                </p>
              )}
              <div className="relative mt-2">
                <Search className="absolute left-2.5 top-2 h-3.5 w-3.5 text-ink-muted" />
                <input
                  type="text"
                  value={tuKhoa}
                  onChange={(su) => setTuKhoa(su.target.value)}
                  placeholder="Tìm theo tên hoặc email..."
                  className="w-full rounded-lg border border-line bg-panel py-1.5 pl-8 pr-2.5 text-xs text-ink placeholder:text-ink-muted focus:border-camel focus:outline-none"
                />
              </div>
            </div>

            {dangTaiDanhSach ? (
              <p className="px-4 py-10 text-center text-xs text-ink-muted">Đang tải hội thoại...</p>
            ) : danhSachHienThi.length === 0 ? (
              <p className="px-4 py-10 text-center text-xs text-ink-muted">
                {tuKhoa.trim() ? 'Không tìm thấy khách nào.' : 'Chưa có khách nào nhắn tin.'}
              </p>
            ) : (
              <ul className="flex-1 divide-y divide-line overflow-y-auto">
                {danhSachHienThi.map((item) => {
                  const dangXem = item.id === dangChon;
                  return (
                    <li key={item.id}>
                      <button
                        type="button"
                        onClick={() => setDangChon(item.id)}
                        className={`w-full cursor-pointer px-3.5 py-2.5 text-left transition-colors ${
                          dangXem ? 'bg-tint-strong' : 'hover:bg-tint'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="truncate text-xs font-bold text-ink">
                            {tenKhach(item)}
                          </span>
                          <span className="shrink-0 text-[10px] text-ink-muted">
                            {dinhDangGio(item.lastMessageAt)}
                          </span>
                        </div>
                        <div className="mt-0.5 flex items-center gap-2">
                          <p className="min-w-0 flex-1 truncate text-[11px] text-ink-muted">
                            {item.typing.customer ? (
                              <span className="font-semibold italic text-camel-dark">
                                Đang soạn tin...
                              </span>
                            ) : (
                              item.lastMessage || 'Chưa có tin nhắn'
                            )}
                          </p>
                          {item.unreadStaffCount > 0 && (
                            <span className="shrink-0 rounded-full bg-danger px-1.5 py-0.5 text-[10px] font-bold text-white">
                              {item.unreadStaffCount}
                            </span>
                          )}
                        </div>
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>

          {/* Cot phai: khung chat */}
          <section className="flex max-h-[76vh] min-h-[60vh] flex-col overflow-hidden rounded-2xl border border-line bg-panel shadow-xl">
            <div className="flex items-center gap-2.5 border-b border-line px-4 py-2.5">
              <span className="flex h-8 w-8 items-center justify-center rounded-full bg-tint text-camel-dark">
                <User className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-ink">
                  {hoiThoaiDangMo ? tenKhach(hoiThoaiDangMo) : 'Chọn một hội thoại'}
                </p>
                <p className="truncate text-[11px] text-ink-muted">
                  {hoiThoaiDangMo?.customerEmail ?? 'Danh sách bên trái'}
                </p>
              </div>
              {hoiThoaiDangMo && (
                <button
                  type="button"
                  onClick={ketThucHoiThoai}
                  disabled={dangDong}
                  title="Hội thoại rời khỏi danh sách, tin nhắn vẫn được giữ lại"
                  className="inline-flex shrink-0 cursor-pointer items-center gap-1.5 rounded-lg border border-line px-2.5 py-1.5 text-[11px] font-semibold text-ink-mid transition-colors hover:border-danger-line hover:bg-danger-bg hover:text-danger disabled:opacity-50"
                >
                  <CheckCheck className="h-3.5 w-3.5" />
                  {dangDong ? 'Đang kết thúc...' : 'Kết thúc'}
                </button>
              )}
            </div>

            <div
              ref={khungTin}
              onScroll={khiCuon}
              className="flex-1 space-y-1.5 overflow-y-auto bg-tint/40 px-4 py-3"
            >
              {!dangChon ? (
                <p className="py-16 text-center text-xs text-ink-muted">
                  Chọn một khách ở danh sách bên trái để bắt đầu trả lời.
                </p>
              ) : dangTaiTinNhan ? (
                <p className="py-16 text-center text-xs text-ink-muted">Đang tải tin nhắn...</p>
              ) : tinNhan.length === 0 ? (
                <p className="py-16 text-center text-xs text-ink-muted">
                  Hội thoại chưa có tin nhắn nào.
                </p>
              ) : (
                <>
                  {conTinCu && (
                    <div className="flex justify-center pb-1">
                      <button
                        type="button"
                        onClick={taiTinCu}
                        disabled={dangTaiTinCu}
                        className="inline-flex cursor-pointer items-center gap-1 rounded-full border border-line bg-panel px-3 py-1 text-[11px] font-semibold text-ink-mid transition-colors hover:bg-tint disabled:opacity-50"
                      >
                        <ChevronUp className="h-3 w-3" />
                        {dangTaiTinCu ? 'Đang tải...' : 'Xem tin cũ hơn'}
                      </button>
                    </div>
                  )}

                  {tinNhan.map((item) => {
                    const cuaToi = Boolean(idCuaToi) && item.senderId === idCuaToi;
                    const benShop = laBenShop(item);
                    const dangCho = item.id.startsWith(TIEN_TO_TIN_TAM);
                    return (
                      <div
                        key={item.id}
                        className={`flex ${benShop ? 'justify-end' : 'justify-start'}`}
                      >
                        <div
                          className={`max-w-[72%] rounded-xl border px-3 py-1.5 text-xs leading-relaxed ${
                            dangCho ? 'opacity-60' : ''
                          } ${
                            cuaToi
                              ? 'border-camel/30 bg-camel/20 text-ink'
                              : benShop
                                ? 'border-line bg-tint-strong text-ink'
                                : 'border-line bg-panel text-ink'
                          }`}
                        >
                          <p className="whitespace-pre-wrap break-words">{item.content}</p>
                          <p className="mt-0.5 flex items-center justify-end gap-1 text-[10px] text-ink-muted">
                            {!cuaToi && benShop ? 'NV khác · ' : ''}
                            {dangCho ? (
                              <>
                                <Clock className="h-2.5 w-2.5" />
                                Đang gửi
                              </>
                            ) : (
                              dinhDangGio(item.createdAt)
                            )}
                            {benShop && item.isRead && item.id === idTinCuoiCuaShop && (
                              <span className="font-semibold text-ok">✓✓ Đã xem</span>
                            )}
                          </p>
                        </div>
                      </div>
                    );
                  })}
                </>
              )}

              {khachDangSoan && (
                <div className="flex justify-start">
                  <div className="flex items-center gap-2 rounded-xl border border-line bg-panel px-3 py-1.5 text-[11px] italic text-ink-muted">
                    <span className="flex gap-0.5">
                      <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-ink-muted" />
                      <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-ink-muted [animation-delay:120ms]" />
                      <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-ink-muted [animation-delay:240ms]" />
                    </span>
                    Khách đang soạn tin...
                  </div>
                </div>
              )}
            </div>

            <form onSubmit={gui} className="flex items-center gap-2 border-t border-line px-4 py-2.5">
              <input
                type="text"
                value={noiDung}
                onChange={(su) => khiGoPhim(su.target.value)}
                disabled={!dangChon || dangGui}
                maxLength={2000}
                placeholder={dangChon ? 'Nhập câu trả lời cho khách...' : 'Chọn hội thoại trước'}
                className="flex-1 rounded-xl border border-line bg-panel px-3.5 py-2 text-xs text-ink placeholder:text-ink-muted focus:border-camel focus:outline-none disabled:opacity-50"
              />
              <button
                type="submit"
                disabled={!dangChon || dangGui || !noiDung.trim()}
                className="inline-flex cursor-pointer items-center gap-1.5 rounded-xl bg-camel px-4 py-2 text-xs font-bold text-ink transition-colors hover:bg-camel-hover disabled:cursor-not-allowed disabled:opacity-50"
              >
                <Send className="h-3.5 w-3.5" />
                {dangGui ? 'Đang gửi...' : 'Gửi'}
              </button>
            </form>
          </section>
        </div>
      </main>
    </>
  );
}
