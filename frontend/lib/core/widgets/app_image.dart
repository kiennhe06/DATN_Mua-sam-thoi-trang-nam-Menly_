import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Giai ma anh nhung dang `data:image/...;base64,...`.
///
/// Tra ve null neu chuoi khong phai dang do hoac khong giai ma duoc.
Uint8List? decodeInlineImage(String url) {
  if (!url.startsWith('data:image/')) return null;
  final viTriDauPhay = url.indexOf(',');
  if (viTriDauPhay < 0) return null;
  if (!url.substring(0, viTriDauPhay).contains('base64')) return null;
  try {
    return base64Decode(url.substring(viTriDauPhay + 1));
  } catch (_) {
    return null;
  }
}

/// Nguon anh dung cho cac cho can ImageProvider (vi du DecorationImage).
///
/// Tra ve null khi chuoi rong, de noi goi tu quyet dinh hien gi thay the.
ImageProvider? appImageProvider(String url) {
  if (url.trim().isEmpty) return null;
  final duLieuAnh = decodeInlineImage(url);
  if (duLieuAnh != null) return MemoryImage(duLieuAnh);
  return CachedNetworkImageProvider(url);
}

/// Anh tai ve tu may chu, nhan duoc ca duong dan mang lan anh nhung base64.
///
/// Day la cho duy nhat ung dung ve anh tu may chu. Quan tri co the dan thang
/// anh vao o "Anh dai dien" thay vi dan duong dan, luc do gia tri luu lai la
/// mot chuoi `data:image/...;base64,...`. Trinh duyet doc duoc chuoi nay nen
/// trang quan tri van hien anh, con CachedNetworkImage chi tai duoc dia chi
/// http nen man hinh nao goi thang no se hien o trong. Dung widget nay o moi
/// cho de khong man nao bi sot.
class AppImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Hien khi dang tai anh tu mang. Anh nhung khong can toi.
  final WidgetBuilder? placeholder;

  /// Hien khi khong co anh hoac tai that bai.
  final WidgetBuilder? errorWidget;

  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  Widget _khiLoi(BuildContext context) =>
      errorWidget?.call(context) ?? const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _khiLoi(context);

    final duLieuAnh = decodeInlineImage(url);
    if (duLieuAnh != null) {
      return Image.memory(
        duLieuAnh,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, _, __) => _khiLoi(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, _) =>
          placeholder?.call(context) ?? const SizedBox.shrink(),
      errorWidget: (context, _, __) => _khiLoi(context),
    );
  }
}
