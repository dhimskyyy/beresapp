class PayoutAccount {
  final String type; // 'bank' or 'ewallet'
  final String provider; // 'BCA', 'BRI', 'BNI', 'MANDIRI', 'DANA', 'GOPAY', 'OVO', 'SHOPEEPAY'
  final String accountNumber;
  final String accountName;

  PayoutAccount({
    required this.type,
    required this.provider,
    required this.accountNumber,
    required this.accountName,
  });

  factory PayoutAccount.fromMap(Map<String, dynamic> map) {
    return PayoutAccount(
      type: map['type'] ?? 'bank',
      provider: map['provider'] ?? 'BCA',
      accountNumber: map['accountNumber'] ?? '',
      accountName: map['accountName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'provider': provider,
      'accountNumber': accountNumber,
      'accountName': accountName,
    };
  }
}

class TukangLocation {
  final double lat;
  final double lng;
  final DateTime updatedAt;

  TukangLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory TukangLocation.fromMap(Map<String, dynamic> map) {
    return TukangLocation(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TukangModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String birthDate;
  final int age;
  final List<String> services;
  final List<PayoutAccount> payoutAccounts;
  final String ktpUrl;
  final String verificationStatus; // 'pending_verification' | 'verified' | 'rejected'
  final String? rejectionReason;
  final bool isSuspended;
  final DateTime? suspendedUntil;
  final String? suspendReason;
  final double walletBalance;
  final double rating;
  final int reviewCount;
  final bool isOnline;
  final double workRadiusKm; // Real work radius filter in km
  final TukangLocation? currentLocation;
  final DateTime createdAt;

  TukangModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.birthDate,
    required this.age,
    required this.services,
    required this.payoutAccounts,
    required this.ktpUrl,
    this.verificationStatus = 'pending_verification',
    this.rejectionReason,
    this.isSuspended = false,
    this.suspendedUntil,
    this.suspendReason,
    this.walletBalance = 0.0,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.isOnline = false,
    this.workRadiusKm = 15.0,
    this.currentLocation,
    required this.createdAt,
  });

  /// Check if currently under 3-Day suspension
  bool get isCurrentlySuspended {
    if (!isSuspended) return false;
    if (suspendedUntil == null) return isSuspended;
    return suspendedUntil!.isAfter(DateTime.now());
  }

  /// Check if eligible to receive job radar and bid
  bool get canAcceptJobs {
    return verificationStatus == 'verified' && !isCurrentlySuspended && isOnline;
  }

  TukangModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? birthDate,
    int? age,
    List<String>? services,
    List<PayoutAccount>? payoutAccounts,
    String? ktpUrl,
    String? verificationStatus,
    String? rejectionReason,
    bool? isSuspended,
    DateTime? suspendedUntil,
    String? suspendReason,
    double? walletBalance,
    double? rating,
    int? reviewCount,
    bool? isOnline,
    double? workRadiusKm,
    TukangLocation? currentLocation,
  }) {
    return TukangModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      services: services ?? this.services,
      payoutAccounts: payoutAccounts ?? this.payoutAccounts,
      ktpUrl: ktpUrl ?? this.ktpUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      suspendReason: suspendReason ?? this.suspendReason,
      walletBalance: walletBalance ?? this.walletBalance,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOnline: isOnline ?? this.isOnline,
      workRadiusKm: workRadiusKm ?? this.workRadiusKm,
      currentLocation: currentLocation ?? this.currentLocation,
      createdAt: createdAt,
    );
  }

  factory TukangModel.fromMap(Map<String, dynamic> map, String id) {
    return TukangModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      birthDate: map['birthDate'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      services: List<String>.from(map['services'] ?? []),
      payoutAccounts: (map['payoutAccounts'] as List<dynamic>? ?? [])
          .map((item) => PayoutAccount.fromMap(item as Map<String, dynamic>))
          .toList(),
      ktpUrl: map['ktpUrl'] ?? '',
      verificationStatus: map['verificationStatus'] ?? 'pending_verification',
      rejectionReason: map['rejectionReason'],
      isSuspended: map['isSuspended'] ?? false,
      suspendedUntil: map['suspendedUntil'] != null
          ? DateTime.tryParse(map['suspendedUntil'].toString())
          : null,
      suspendReason: map['suspendReason'],
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isOnline: map['isOnline'] ?? false,
      workRadiusKm: (map['workRadiusKm'] as num?)?.toDouble() ?? 15.0,
      currentLocation: map['currentLocation'] != null
          ? TukangLocation.fromMap(map['currentLocation'] as Map<String, dynamic>)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'birthDate': birthDate,
      'age': age,
      'services': services,
      'payoutAccounts': payoutAccounts.map((a) => a.toMap()).toList(),
      'ktpUrl': ktpUrl,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
      'isSuspended': isSuspended,
      'suspendedUntil': suspendedUntil?.toIso8601String(),
      'suspendReason': suspendReason,
      'walletBalance': walletBalance,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOnline': isOnline,
      'workRadiusKm': workRadiusKm,
      'currentLocation': currentLocation?.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
