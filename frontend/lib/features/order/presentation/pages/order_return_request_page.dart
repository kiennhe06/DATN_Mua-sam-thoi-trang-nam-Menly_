import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrderReturnRequestPage extends StatefulWidget {
  final OrderModel order;

  const OrderReturnRequestPage({super.key, required this.order});

  @override
  State<OrderReturnRequestPage> createState() => _OrderReturnRequestPageState();
}

class _OrderReturnRequestPageState extends State<OrderReturnRequestPage> {
  static const int _maxImages = 5;

  final TextEditingController _detailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  String _selectedReason = 'Sản phẩm không đúng mô tả';
  bool _submitting = false;
  bool _loadingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _loadingOrder = true);
      await context.read<OrderProvider>().fetchOrderById(widget.order.id);
      if (mounted) setState(() => _loadingOrder = false);
    });
  }

  final _reasons = const [
    'Sản phẩm không đúng mô tả',
    'Sản phẩm bị lỗi do nhà sản xuất',
    'Giao sai size hoặc màu',
    'Không còn nhu cầu sử dụng',
    'Khác',
  ];

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages({bool fromCamera = false}) async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      AppSnackBar.show(context, message: 'Chỉ được đính kèm tối đa $_maxImages ảnh');
      return;
    }

    try {
      final List<XFile> picked;
      if (fromCamera) {
        final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
        picked = shot == null ? const [] : [shot];
      } else {
        picked = await _picker.pickMultiImage(imageQuality: 75, limit: remaining);
      }
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

  Future<void> _submit() async {
    if (_submitting) return;

    final detail = _detailController.text.trim();
    final reason = detail.isEmpty ? _selectedReason : '$_selectedReason: $detail';

    if (_images.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Vui lòng đính kèm ít nhất 1 ảnh minh chứng',
        backgroundColor: AppColors.of(context).danger,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<OrderProvider>().submitReturnRequest(
            orderId: widget.order.id,
            reason: reason,
            images: _images,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
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
    final order =
        context.watch<OrderProvider>().findById(widget.order.id) ?? widget.order;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'Gửi yêu cầu trả hàng',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_loadingOrder)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          _buildOrderCard(c, order),
          const SizedBox(height: 16),
          Text(
            'Lý do trả hàng',
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(
                  reason,
                  style: TextStyle(
                    color: isSelected ? c.onPrimary : c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedReason = reason),
                selectedColor: c.primary,
                backgroundColor: c.surface,
                side: BorderSide(color: isSelected ? c.primary : c.border),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Mô tả chi tiết',
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailController,
            maxLines: 5,
            minLines: 4,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Sản phẩm giao sai size, chất liệu khác với hình ảnh...',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ảnh minh chứng (${_images.length}/$_maxImages)',
                style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text('Bắt buộc, tối đa 5MB/ảnh', style: TextStyle(color: c.textMuted, fontSize: 12)),
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
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Gửi yêu cầu trả hàng',
            icon: Icons.assignment_return_rounded,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(AppColors c, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.code,
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Hoàn tối đa ${formatVnd(order.total)} • ${order.status.label}',
            style: TextStyle(color: c.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (order.items.isEmpty)
            Text(
              'Đơn chưa có dòng sản phẩm từ máy chủ.',
              style: TextStyle(color: c.textMuted, fontSize: 12.5),
            ),
          for (final item in order.items.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: item.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: c.surfaceVariant),
                            )
                          : Container(color: c.surfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _itemLabel(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
            child: kIsWeb
                ? FutureBuilder(
                    future: _images[index].readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(color: c.surfaceVariant);
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  )
                : Image.file(
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
            onTap: () => setState(() => _images.removeAt(index)),
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

  String _itemLabel(OrderItemModel item) {
    final variant = [
      if (item.size.trim().isNotEmpty) item.size.trim(),
      if (item.color.trim().isNotEmpty) item.color.trim(),
    ].join(', ');
    final name = item.productName.trim().isEmpty ? 'Sản phẩm' : item.productName.trim();
    return variant.isEmpty ? '$name x${item.quantity}' : '$name ($variant) x${item.quantity}';
  }

  Widget _buildAddImageButton(AppColors c) {
    return InkWell(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Chọn từ thư viện'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImages();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Chụp ảnh minh chứng'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImages(fromCamera: true);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
