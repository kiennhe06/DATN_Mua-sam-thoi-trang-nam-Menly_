import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/core/utils/app_logger.dart';

/// Log phai giu lai du noi dung, khu vuc, muc do va doi tuong loi — vi ca muc
/// dich cua no la de lai dau vet khi co chuyen.
void main() {
  late List<BanGhiLog> daGhi;

  setUp(() {
    daGhi = [];
    AppLogger.nhanThem = daGhi.add;
  });

  tearDown(() {
    AppLogger.nhanThem = null;
  });

  test('ở bản gỡ lỗi thì log luôn được bật', () {
    expect(AppLogger.dangBat, isTrue);
  });

  test('ghi thông tin giữ đúng nội dung, khu vực và mức độ', () {
    AppLogger.thongTin('Tải xong danh sách', khuVuc: 'ThuNghiem');

    expect(daGhi, hasLength(1));
    expect(daGhi.single.noiDung, 'Tải xong danh sách');
    expect(daGhi.single.khuVuc, 'ThuNghiem');
    expect(daGhi.single.mucDo, MucDoLog.thongTin);
  });

  test('ghi lỗi thì kèm cả đối tượng lỗi lẫn stack trace', () {
    final loi = Exception('mạng hỏng');
    final stack = StackTrace.current;

    AppLogger.loi(
      'Không gọi được máy chủ',
      khuVuc: 'API',
      loi: loi,
      stackTrace: stack,
    );

    final banGhi = daGhi.single;
    expect(banGhi.mucDo, MucDoLog.loi);
    expect(banGhi.loi, same(loi), reason: 'phải giữ nguyên đối tượng lỗi');
    expect(banGhi.stackTrace, same(stack));
  });

  test('cảnh báo nằm giữa thông tin và lỗi', () {
    AppLogger.canhBao('Làm mới token thất bại', khuVuc: 'API', loi: 'hết hạn');

    expect(daGhi.single.mucDo, MucDoLog.canhBao);
    expect(daGhi.single.loi, 'hết hạn');
    expect(MucDoLog.canhBao.so, greaterThan(MucDoLog.thongTin.so));
    expect(MucDoLog.canhBao.so, lessThan(MucDoLog.loi.so));
  });

  test('không truyền khu vực thì có tên mặc định, không để trống', () {
    AppLogger.thongTin('Không ghi khu vực');

    expect(daGhi.single.khuVuc, isNotEmpty);
  });

  test('nơi nhận thêm mà hỏng thì không làm văng lỗi ra ngoài', () {
    // Ham log hay duoc goi tu trong khoi catch. No ma tu nem loi thi chinh
    // cho ghi loi lai sinh ra loi moi, che mat loi that.
    AppLogger.nhanThem = (_) => throw StateError('nơi nhận hỏng');

    expect(
      () => AppLogger.loi('Có lỗi thật', loi: Exception('lỗi gốc')),
      returnsNormally,
    );
  });

  test('bỏ nơi nhận thì không ghi thêm vào danh sách cũ nữa', () {
    AppLogger.thongTin('Dòng đầu');
    AppLogger.nhanThem = null;
    AppLogger.thongTin('Dòng sau');

    expect(daGhi, hasLength(1));
    expect(daGhi.single.noiDung, 'Dòng đầu');
  });

  test('toString đọc được để dán vào báo cáo lỗi', () {
    AppLogger.canhBao('Giữ danh sách cũ', khuVuc: 'DonHang', loi: 'timeout');

    expect(daGhi.single.toString(), contains('DonHang'));
    expect(daGhi.single.toString(), contains('Giữ danh sách cũ'));
    expect(daGhi.single.toString(), contains('timeout'));
  });
}
