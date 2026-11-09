/// Cac dia chi sinh anh ngau nhien: moi lan goi tra ve mot tam khac nen khong
/// phai anh cua san pham, hien ra chi gay hieu nham.
///
/// Anh unsplash KHONG nam trong danh sach nay. Do la anh that cua kho hang,
/// dang hien o trang chu va trang chi tiet; loc no di thi don hang va danh gia
/// tro thanh o trong trong khi cac man khac van co anh.
const _diaChiSinhAnhNgauNhien = ['picsum', 'placeholder'];

/// Dia chi nay co phai cho sinh anh ngau nhien khong.
bool laAnhSinhNgauNhien(String url) {
  final thuong = url.toLowerCase();
  return _diaChiSinhAnhNgauNhien.any(thuong.contains);
}

/// Duong dan anh dung duoc, hoac chuoi rong neu khong co anh that.
///
/// Day la noi duy nhat dinh nghia the nao la anh that, de may chu va ung dung
/// khong loc theo hai bo quy tac khac nhau.
String duongDanAnhThat(dynamic raw) {
  final url = raw?.toString().trim() ?? '';
  if (url.isEmpty || laAnhSinhNgauNhien(url)) return '';
  return url;
}
