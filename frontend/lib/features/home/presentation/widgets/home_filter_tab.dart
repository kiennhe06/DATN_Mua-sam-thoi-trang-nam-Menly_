import 'package:flutter/material.dart';
import 'package:menly_app/core/widgets/category_tab.dart';

/// Tab loc nhanh o trang chu ("Mới", "Bán chạy").
///
/// Dung lai chip vien thuoc dung chung cua ung dung de moi cho loc deu cung
/// mot hinh khoi, thay cho gach chan cu.
class HomeFilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const HomeFilterTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryTab(
      label: label,
      selected: active,
      onTap: onTap,
    );
  }
}
