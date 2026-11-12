import addressData from 'vietnam-address-database';
import type { Province, Ward, WardMapping, DatabaseItem } from 'vietnam-address-database';

/**
 * Service quản lý cơ sở dữ liệu địa chỉ hành chính Việt Nam
 * Nguồn: quangtam/vietnam-address-database (Nghị quyết 202/2025/QH15)
 * - 34 Tỉnh / Thành phố
 * - 3.321 Phường / Xã
 * - 10.977 quy tắc mapping từ đơn vị cũ sang mới
 */
export class VietnamAddressService {
  private static provinces: Province[] = [];
  private static wards: Ward[] = [];
  private static wardMappings: WardMapping[] = [];
  private static initialized = false;

  private static init(): void {
    if (this.initialized) return;
    const raw = addressData as unknown as DatabaseItem[];
    for (const item of raw) {
      if (item.type === 'table') {
        if (item.name === 'provinces') {
          this.provinces = (item.data ?? []) as Province[];
        } else if (item.name === 'wards') {
          this.wards = (item.data ?? []) as Ward[];
        } else if (item.name === 'ward_mappings') {
          this.wardMappings = (item.data ?? []) as WardMapping[];
        }
      }
    }
    this.initialized = true;
  }

  /**
   * Lấy danh sách 34 Tỉnh / Thành phố mới
   */
  static getProvinces(): Province[] {
    this.init();
    return this.provinces;
  }

  /**
   * Lấy danh sách 3.321 Phường / Xã
   */
  static getWards(): Ward[] {
    this.init();
    return this.wards;
  }

  /**
   * Lấy toàn bộ danh sách 10.977 quy tắc mapping
   */
  static getWardMappings(): WardMapping[] {
    this.init();
    return this.wardMappings;
  }

  /**
   * Tìm tỉnh theo mã tỉnh (vd: "01", "79", "HNI", "HCM")
   */
  static getProvinceByCode(code: string): Province | undefined {
    this.init();
    const clean = code.trim().toLowerCase();
    return this.provinces.find(
      (p) => p.province_code.toLowerCase() === clean || p.code.toLowerCase() === clean
    );
  }

  /**
   * Lấy danh sách Phường / Xã theo mã tỉnh
   */
  static getWardsByProvinceCode(provinceCode: string): Ward[] {
    this.init();
    const clean = provinceCode.trim();
    return this.wards.filter((w) => w.province_code === clean);
  }

  /**
   * Lấy danh sách Phường / Xã theo tên tỉnh
   */
  static getWardsByProvinceName(provinceName: string): Ward[] {
    this.init();
    const clean = provinceName.trim().toLowerCase();
    const p = this.provinces.find(
      (prov) =>
        prov.name.toLowerCase() === clean ||
        prov.short_name.toLowerCase() === clean ||
        prov.code.toLowerCase() === clean
    );
    if (!p) return [];
    return this.getWardsByProvinceCode(p.province_code);
  }

  /**
   * Chuyển đổi địa chỉ cũ sang địa chỉ mới theo 10.977 quy tắc mapping
   */
  static convertOldAddress(params: {
    oldWard?: string;
    oldDistrict?: string;
    oldProvince?: string;
  }): { newProvinceName: string; newWardName: string; matched: boolean } | null {
    this.init();
    const { oldWard, oldDistrict, oldProvince } = params;
    if (!oldProvince && !oldWard) return null;

    const norm = (str?: string) => (str ?? '').trim().toLowerCase();
    const targetWard = norm(oldWard);
    const targetDistrict = norm(oldDistrict);
    const targetProv = norm(oldProvince);

    const match = this.wardMappings.find(
      (m) =>
        (!targetWard || norm(m.old_ward_name).includes(targetWard) || targetWard.includes(norm(m.old_ward_name))) &&
        (!targetDistrict || norm(m.old_district_name).includes(targetDistrict) || targetDistrict.includes(norm(m.old_district_name))) &&
        (!targetProv || norm(m.old_province_name).includes(targetProv) || targetProv.includes(norm(m.old_province_name)))
    );

    if (match) {
      return {
        newProvinceName: match.new_province_name,
        newWardName: match.new_ward_name,
        matched: true,
      };
    }

    return null;
  }

  /**
   * Tìm kiếm đơn vị hành chính thông minh theo từ khóa
   */
  static search(keyword: string, limit = 20) {
    this.init();
    const q = keyword.trim().toLowerCase();
    if (!q) return { provinces: [], wards: [], mappings: [] };

    const matchedProvinces = this.provinces.filter(
      (p) => p.name.toLowerCase().includes(q) || p.code.toLowerCase().includes(q)
    );

    const matchedWards = this.wards
      .filter((w) => w.name.toLowerCase().includes(q))
      .slice(0, limit);

    const matchedMappings = this.wardMappings
      .filter(
        (m) =>
          m.old_ward_name.toLowerCase().includes(q) ||
          m.old_district_name.toLowerCase().includes(q) ||
          m.new_ward_name.toLowerCase().includes(q)
      )
      .slice(0, limit);

    return {
      provinces: matchedProvinces,
      wards: matchedWards,
      mappings: matchedMappings,
    };
  }
}

