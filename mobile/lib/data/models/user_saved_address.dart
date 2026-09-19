class UserSavedAddress {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final String note;
  final bool isPrimary;
  final double latitude;
  final double longitude;

  UserSavedAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    required this.note,
    this.isPrimary = false,
    this.latitude = -6.2088,
    this.longitude = 106.8456,
  });

  UserSavedAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phone,
    String? fullAddress,
    String? note,
    bool? isPrimary,
    double? latitude,
    double? longitude,
  }) {
    return UserSavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      note: note ?? this.note,
      isPrimary: isPrimary ?? this.isPrimary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
