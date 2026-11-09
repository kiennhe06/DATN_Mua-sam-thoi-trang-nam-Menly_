import 'package:flutter/material.dart';
import 'package:menly_app/core/widgets/app_image.dart';

class AvatarPreset {
  final String id;
  final String label;
  final Color background;
  final Color skin;
  final Color hair;
  final Color shirt;

  const AvatarPreset({
    required this.id,
    required this.label,
    required this.background,
    required this.skin,
    required this.hair,
    required this.shirt,
  });

  static const presets = [
    AvatarPreset(
      id: 'menly-avatar:classic',
      label: 'Cổ điển',
      background: Color(0xFFE7EEF7),
      skin: Color(0xFFE8B995),
      hair: Color(0xFF34251F),
      shirt: Color(0xFF304766),
    ),
    AvatarPreset(
      id: 'menly-avatar:bright',
      label: 'Năng động',
      background: Color(0xFFFFE9D7),
      skin: Color(0xFFD99A72),
      hair: Color(0xFF241D1A),
      shirt: Color(0xFFDA704F),
    ),
    AvatarPreset(
      id: 'menly-avatar:calm',
      label: 'Điềm đạm',
      background: Color(0xFFE4F1E8),
      skin: Color(0xFFF0C9A6),
      hair: Color(0xFF594236),
      shirt: Color(0xFF47775E),
    ),
    AvatarPreset(
      id: 'menly-avatar:urban',
      label: 'Hiện đại',
      background: Color(0xFFECE7F5),
      skin: Color(0xFFB97855),
      hair: Color(0xFF211B20),
      shirt: Color(0xFF725A91),
    ),
    AvatarPreset(
      id: 'menly-avatar:classic-light',
      label: 'Thanh lịch',
      background: Color(0xFFFFF1D9),
      skin: Color(0xFFF2CBAA),
      hair: Color(0xFF8A583A),
      shirt: Color(0xFF476B83),
    ),
    AvatarPreset(
      id: 'menly-avatar:night',
      label: 'Cá tính',
      background: Color(0xFFDDE9EA),
      skin: Color(0xFF8F5D46),
      hair: Color(0xFF241D1A),
      shirt: Color(0xFF394C4D),
    ),
  ];

  static AvatarPreset? find(String? id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String fallbackText;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.radius,
    this.fallbackText = 'M',
  });

  @override
  Widget build(BuildContext context) {
    final preset = AvatarPreset.find(avatarUrl);
    if (preset != null) {
      return ClipOval(
        child: CustomPaint(
          size: Size.square(radius * 2),
          painter: _PresetAvatarPainter(preset),
        ),
      );
    }

    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) return _fallback();
    return ClipOval(
      child: AppImage(
        url: url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_) => _fallback(),
        errorWidget: (_) => _fallback(),
      ),
    );
  }

  Widget _fallback() => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          fallbackText.isEmpty
              ? 'M'
              : fallbackText.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.72,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1B17),
          ),
        ),
      );
}

class _PresetAvatarPainter extends CustomPainter {
  final AvatarPreset preset;

  const _PresetAvatarPainter(this.preset);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width;
    final paint = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);

    paint.color = preset.background;
    canvas.drawCircle(center, scale / 2, paint);

    paint.color = preset.shirt;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, scale * 0.96),
        width: scale * 0.84,
        height: scale * 0.62,
      ),
      paint,
    );

    paint.color = preset.skin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, scale * 0.68),
          width: scale * 0.2,
          height: scale * 0.25,
        ),
        Radius.circular(scale * 0.04),
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, scale * 0.43),
        width: scale * 0.47,
        height: scale * 0.58,
      ),
      paint,
    );
    canvas.drawCircle(
        Offset(scale * 0.255, scale * 0.45), scale * 0.055, paint);
    canvas.drawCircle(
        Offset(scale * 0.745, scale * 0.45), scale * 0.055, paint);

    paint.color = preset.hair;
    final hair = Path()
      ..moveTo(scale * 0.265, scale * 0.4)
      ..cubicTo(scale * 0.22, scale * 0.14, scale * 0.78, scale * 0.12,
          scale * 0.74, scale * 0.43)
      ..cubicTo(scale * 0.66, scale * 0.34, scale * 0.43, scale * 0.31,
          scale * 0.265, scale * 0.4)
      ..close();
    canvas.drawPath(hair, paint);

    paint.color = const Color(0xFF382923);
    canvas.drawCircle(Offset(scale * 0.41, scale * 0.47), scale * 0.018, paint);
    canvas.drawCircle(Offset(scale * 0.59, scale * 0.47), scale * 0.018, paint);

    paint
      ..color = const Color(0xFF9B5549)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.018
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(scale * 0.44, scale * 0.57)
      ..quadraticBezierTo(
          scale * 0.5, scale * 0.61, scale * 0.56, scale * 0.57);
    canvas.drawPath(smile, paint);
  }

  @override
  bool shouldRepaint(covariant _PresetAvatarPainter oldDelegate) =>
      oldDelegate.preset.id != preset.id;
}
