import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:menly_app/features/address/presentation/providers/address_provider.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';

/// Xoa du lieu cua nguoi dung hien tai khoi bo nho cua cac provider.
///
/// Cac provider song suot vong doi ung dung, khong tu mat khi doi tai khoan.
/// Neu khong xoa, nguoi dang nhap sau tren cung mot may se thay gio hang, dia
/// chi, danh sach yeu thich va don hang cua nguoi truoc.
///
/// Goi ca luc dang xuat lan ngay sau khi dang nhap tai khoan khac.
void clearUserDataInMemory(BuildContext context) {
  context.read<CartProvider>().clearUserData();
  context.read<WishlistProvider>().clearUserData();
  context.read<AddressProvider>().clearUserData();
  context.read<OrderProvider>().clearUserData();
  context.read<NotificationProvider>().clearUserData();
  context.read<ProductProvider>().clearUserData();
}
