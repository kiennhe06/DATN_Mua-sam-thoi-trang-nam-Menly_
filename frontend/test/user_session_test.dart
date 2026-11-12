import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';

/// Khoa dung chung cho ca ung dung, khong gan voi nguoi dung nao.
/// Doi tai khoan thi KHONG xoa nhung khoa nay.
const khoaDungChung = <String>{};

void main() {
  test('Moi khoa luu tren may deu nam trong danh sach xoa khi doi tai khoan', () {
    // Quet ma nguon tim cac lenh ghi SharedPreferences co khoa viet thang.
    // Muc dich: sau nay ai them mot cho luu moi ma quen khai bao vao
    // perUserKeys thi bai kiem thu nay do ngay, khong de du lieu nguoi truoc
    // lot sang tai khoan nguoi sau.
    final mauKhoa = RegExp(r"prefs\.set[A-Za-z]+\(\s*'([^']+)'");
    final khoaTimDuoc = <String>{};

    for (final tep in Directory('lib').listSync(recursive: true)) {
      if (tep is! File || !tep.path.endsWith('.dart')) continue;
      for (final khop in mauKhoa.allMatches(tep.readAsStringSync())) {
        khoaTimDuoc.add(khop.group(1)!);
      }
    }

    expect(khoaTimDuoc, isNotEmpty,
        reason: 'Khong quet duoc khoa nao, bieu thuc tim kiem co the da hong');

    final chuaKhaiBao =
        khoaTimDuoc.difference(AuthProvider.perUserKeys.toSet()).difference(khoaDungChung);

    expect(
      chuaKhaiBao,
      isEmpty,
      reason: 'Cac khoa sau duoc luu tren may nhung khong duoc xoa khi doi tai '
          'khoan: $chuaKhaiBao. Them vao AuthProvider.perUserKeys, hoac them '
          'vao khoaDungChung neu that su khong gan voi nguoi dung nao.',
    );
  });

  test('Danh sach xoa phai gom ca ba khoa phien dang nhap', () {
    expect(AuthProvider.perUserKeys, containsAll(<String>[
      'access_token',
      'refresh_token',
      'user_profile',
    ]));
  });
}
