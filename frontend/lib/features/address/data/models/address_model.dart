/// Model dia chi giao hang (AP-DC1)
class AddressModel {
  final String id;
  final String recipientName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String detailAddress;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detailAddress,
    this.isDefault = false,
  });

  String get fullAddress => '$detailAddress, $ward, $district, $province';

  AddressModel copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? province,
    String? district,
    String? ward,
    String? detailAddress,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      detailAddress: detailAddress ?? this.detailAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      detailAddress: json['detail_address']?.toString() ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_name': recipientName,
    'phone': phone,
    'province': province,
    'district': district,
    'ward': ward,
    'detail_address': detailAddress,
    'is_default': isDefault,
  };
}

