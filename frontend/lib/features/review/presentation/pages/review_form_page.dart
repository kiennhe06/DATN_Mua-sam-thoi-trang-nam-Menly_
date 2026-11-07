import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/review_provider.dart';

class ReviewFormPage extends StatefulWidget {
  final String? orderItemId;
  final String? productId;
  final String productName;
  final String thumbnailUrl;

  const ReviewFormPage({
    super.key,
    this.orderItemId,
    this.productId,
    required this.productName,
    this.thumbnailUrl = '',
  });

  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  static const int _maxImages = 5;

  final TextEditingController _commentController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      AppSnackBar.show(context, message: 'Chỉ được đính kèm tối đa $_maxImages ảnh');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(imageQuality: 75, limit: remaining);
      if (!mounted || picked.isEmpty) return;

      final existingPaths = _images.map((image) => image.path).toSet();
      setState(() {
        for (final file in picked) {
          if (_images.length >= _maxImages) break;
          if (existingPaths.add(file.path)) {
            _images.add(file);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Không thể chọn ảnh. Vui lòng thử lại.');
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await context.read<ReviewProvider>().submitReview(
            orderItemId: widget.orderItemId,
            productId: widget.productId,
            rating: _rating,
            comment: _commentController.text,
            images: _images,
          );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(
        context,
        message: message,
        backgroundColor: AppColors.of(context).danger,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'Đánh giá sản phẩm',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildProductRow(c),
          const SizedBox(height: 20),
          Text(
            'Bạn cảm thấy sản phẩm thế nào?',
            style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final selected = index < _rating;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Chia sẻ cảm nhận của bạn về chất liệu, form dáng, màu sắc...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ảnh thực tế (${_images.length}/$_maxImages)',
                style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                'Tối đa 5MB/ảnh',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < _images.length; i++) _buildImagePreview(i, c),
              if (_images.length < _maxImages) _buildAddImageButton(c),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Gửi đánh giá'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: widget.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      widget.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: c.surfaceVariant),
                    )
                  : Container(color: c.surfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(int index, AppColors c) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(
            width: 84,
            height: 84,
            child: Image.file(
              File(_images[index].path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: c.surfaceVariant),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(AppColors c) {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: c.textSecondary, size: 28),
            const SizedBox(height: 4),
            Text('Thêm ảnh', style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
