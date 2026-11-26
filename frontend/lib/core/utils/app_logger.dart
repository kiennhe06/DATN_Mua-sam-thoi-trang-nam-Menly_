import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Muc do nghiem trong cua mot ban ghi log.
///
/// So di kem theo quy uoc cua package:logging de DevTools to mau cho dung.
enum MucDoLog {
  thongTin(800),
  canhBao(900),
  loi(1000);

  const MucDoLog(this.so);

  final int so;
}

/// Mot ban ghi log.
class BanGhiLog {
  const BanGhiLog({
    required this.noiDung,
    required this.khuVuc,
    required this.mucDo,
    this.loi,
    this.stackTrace,
  });

  final String noiDung;
  final String khuVuc;
  final MucDoLog mucDo;
  final Object? loi;
  final StackTrace? stackTrace;

  @override
  String toString() => '[$khuVuc] ${mucDo.name}: $noiDung'
      '${loi != null ? ' | $loi' : ''}';
}

/// Ghi log cho ung dung.
///
/// Truoc day app khong ghi gi ca, ma lai co rat nhieu cho `catch (_)` nuot
/// loi im lang. Hong cai gi la khong con dau vet de lan ra.
///
/// Dung `dart:developer` chu khong dung `print`:
///   - `print` bi Android cat bot dong khi log day, con `developer.log` thi
///     khong, va no hien dung muc do trong DevTools.
///   - Kem duoc ca doi tuong loi va stack trace, khong phai noi chuoi bang tay.
///
/// Mac dinh tat o ban phat hanh: log chi de nguoi lam app xem, nguoi dung cuoi
/// khong can, va cang khong nen de lo duong dan API hay noi dung du lieu tren
/// may ho.
class AppLogger {
  AppLogger._();

  /// Bat log o ban phat hanh hay khong. Chay:
  /// flutter run --dart-define=LOG_O_BAN_PHAT_HANH=true
  static const bool _batOBanPhatHanh =
      bool.fromEnvironment('LOG_O_BAN_PHAT_HANH');

  /// Co ghi log luc nay khong.
  static bool get dangBat => !kReleaseMode || _batOBanPhatHanh;

  /// Noi nhan them moi ban ghi, ngoai dart:developer.
  ///
  /// Dat de chuyen log di cho khac — vi du gui len dich vu bao loi tu xa khi
  /// phat hanh that — hoac de bai test doc duoc nhung gi da ghi. Dat lai
  /// thanh null de thoi nhan.
  static void Function(BanGhiLog banGhi)? nhanThem;

  /// Viec binh thuong dang chu y: dang nhap xong, tai xong danh sach.
  static void thongTin(String noiDung, {String khuVuc = 'Menly'}) {
    _ghi(BanGhiLog(
      noiDung: noiDung,
      khuVuc: khuVuc,
      mucDo: MucDoLog.thongTin,
    ));
  }

  /// Co chuyen khong nhu mong doi nhung app van chay tiep duoc.
  static void canhBao(String noiDung, {String khuVuc = 'Menly', Object? loi}) {
    _ghi(BanGhiLog(
      noiDung: noiDung,
      khuVuc: khuVuc,
      mucDo: MucDoLog.canhBao,
      loi: loi,
    ));
  }

  /// Co loi that su. Luon kem doi tuong loi va stack trace neu co.
  static void loi(
    String noiDung, {
    String khuVuc = 'Menly',
    Object? loi,
    StackTrace? stackTrace,
  }) {
    _ghi(BanGhiLog(
      noiDung: noiDung,
      khuVuc: khuVuc,
      mucDo: MucDoLog.loi,
      loi: loi,
      stackTrace: stackTrace,
    ));
  }

  static void _ghi(BanGhiLog banGhi) {
    if (!dangBat) return;

    // Hai duong ra, vi moi duong thieu mot cho:
    //   - developer.log cho DevTools: giu duoc muc do, doi tuong loi va stack
    //     trace thanh cac o rieng. Nhung no di qua kenh VM service, nen khi
    //     chay `flutter run` ma khong o che do tuong tac (vi du ghi ra file,
    //     chay trong CI) thi KHONG thay dong nao, va logcat cung khong co.
    //   - debugPrint cho cua so dong lenh va logcat: cho nao cung thay, va
    //     Flutter tu chia nho dong de Android khong cat mat chu.
    developer.log(
      banGhi.noiDung,
      name: banGhi.khuVuc,
      level: banGhi.mucDo.so,
      error: banGhi.loi,
      stackTrace: banGhi.stackTrace,
    );

    debugPrint(banGhi.toString());
    if (banGhi.stackTrace != null && banGhi.mucDo == MucDoLog.loi) {
      debugPrint(banGhi.stackTrace.toString());
    }

    // Noi nhan them khong duoc phep lam hong luong chay: ham log thuong duoc
    // goi tu trong khoi catch, no ma nem loi o day thi thanh ra chinh cho ghi
    // loi lai sinh loi moi.
    final nhan = nhanThem;
    if (nhan == null) return;
    try {
      nhan(banGhi);
    } catch (_) {
      // Co y nuot: khong con cho nao de bao loi nay nua.
    }
  }
}
