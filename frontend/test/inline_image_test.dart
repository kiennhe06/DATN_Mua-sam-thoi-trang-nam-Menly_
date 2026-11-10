import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/core/utils/image_url.dart';
import 'package:menly_app/core/widgets/app_image.dart';

void main() {
  // Anh GIF 1x1 hop le, du de kiem tra viec giai ma base64.
  const anhNhung =
      'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';

  test('Doc duoc anh nhung dang base64 ma quan tri dan vao', () {
    final duLieu = decodeInlineImage(anhNhung);
    expect(duLieu, isNotNull);
    expect(duLieu!.isNotEmpty, isTrue);
  });

  test('Duong dan mang binh thuong thi khong coi la anh nhung', () {
    expect(decodeInlineImage('https://images.unsplash.com/photo-123?w=800'), isNull);
    expect(decodeInlineImage(''), isNull);
  });

  test('Chuoi base64 hong thi tra ve null chu khong nem loi', () {
    expect(decodeInlineImage('data:image/png;base64,@@@khong-hop-le@@@'), isNull);
    expect(decodeInlineImage('data:image/png,thieu-base64'), isNull);
  });

  test('Khong man hinh nao duoc tu ve anh mang ngoai AppImage', () {
    // Quet ma nguon tim cac cho goi thang thu vien anh. Muc dich: sau nay ai
    // them mot cho hien anh moi ma quen dung AppImage thi bai kiem thu nay do
    // ngay, vi cho do se khong doc duoc anh nhung base64 va hien o trong.
    final mauGoiThang = RegExp(r'\b(Image\.network|CachedNetworkImage|NetworkImage)\s*\(');
    const tepDuocPhep = 'lib/core/widgets/app_image.dart';

    final viPham = <String>[];
    for (final tep in Directory('lib').listSync(recursive: true)) {
      if (tep is! File || !tep.path.endsWith('.dart')) continue;
      if (tep.path.replaceAll(r'\', '/').endsWith(tepDuocPhep)) continue;
      if (mauGoiThang.hasMatch(tep.readAsStringSync())) viPham.add(tep.path);
    }

    expect(
      viPham,
      isEmpty,
      reason: 'Cac tep sau dang tu ve anh mang, hay doi sang AppImage: '
          '${viPham.join(', ')}',
    );
  });

  test('Anh unsplash la anh that cua kho hang nen phai duoc giu lai', () {
    // Truoc day ca may chu lan ung dung deu coi unsplash la anh gia va xoa di,
    // khien gio hang, don hang va danh gia hien o trong trong khi trang chu
    // van co anh. Chi dia chi sinh anh ngau nhien moi bi bo.
    expect(
      duongDanAnhThat('https://images.unsplash.com/photo-123?w=600'),
      'https://images.unsplash.com/photo-123?w=600',
    );
    expect(laAnhSinhNgauNhien('https://images.unsplash.com/photo-123'), isFalse);

    expect(duongDanAnhThat('https://picsum.photos/seed/1/600'), '');
    expect(duongDanAnhThat('https://via.placeholder.com/600'), '');
    expect(duongDanAnhThat(null), '');
    expect(duongDanAnhThat('   '), '');
  });

  test('Anh nhung base64 cung duoc coi la anh that', () {
    expect(duongDanAnhThat(anhNhung), anhNhung);
  });
}
