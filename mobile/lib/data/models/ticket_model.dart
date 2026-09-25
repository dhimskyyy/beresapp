import '../../domain/entities/ticket_status.dart';

class BidModel {
  final String tukangId;
  final String tukangName;
  final String? tukangPhoto;
  final double tukangRating;
  final double estimatedPrice;
  final String note;
  final DateTime createdAt;

  BidModel({
    required this.tukangId,
    required this.tukangName,
    this.tukangPhoto,
    this.tukangRating = 5.0,
    required this.estimatedPrice,
    required this.note,
    required this.createdAt,
  });

  factory BidModel.fromMap(Map<String, dynamic> map) {
    return BidModel(
      tukangId: map['tukangId'] ?? '',
      tukangName: map['tukangName'] ?? '',
      tukangPhoto: map['tukangPhoto'],
      tukangRating: (map['tukangRating'] as num?)?.toDouble() ?? 5.0,
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tukangId': tukangId,
      'tukangName': tukangName,
      'tukangPhoto': tukangPhoto,
      'tukangRating': tukangRating,
      'estimatedPrice': estimatedPrice,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class BillItem {
  final String title;
  final double amount;

  BillItem({required this.title, required this.amount});

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'amount': amount};
  }
}

class FinalBill {
  final List<BillItem> items;
  final double totalAmount;
  final bool approvedByUser;
  final DateTime createdAt;

  FinalBill({
    required this.items,
    required this.totalAmount,
    this.approvedByUser = false,
    required this.createdAt,
  });

  factory FinalBill.fromMap(Map<String, dynamic> map) {
    return FinalBill(
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => BillItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      approvedByUser: map['approvedByUser'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'approvedByUser': approvedByUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TicketModel {
  final String id;
  final String userId;
  final String userName;
  final String category;
  final String title;
  final String description;
  final List<String> photoUrls;
  final String address;
  final double lat;
  final double lng;
  final TicketStatus status;
  final String? selectedTukangId;
  final String? selectedTukangName;
  final List<BidModel> bids;
  final FinalBill? finalBill;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String? paymentMethod; // 'CASH'
  final String? paymentStatus; // 'unpaid' | 'paid'
  final String? dokuInvoiceId;
  final int? ratingStars;
  final String? ratingReview;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.title,
    required this.description,
    required this.photoUrls,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    this.selectedTukangId,
    this.selectedTukangName,
    this.bids = const [],
    this.finalBill,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.dokuInvoiceId,
    this.ratingStars,
    this.ratingReview,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    final locationMap = map['location'] as Map<String, dynamic>? ?? {};
    return TicketModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      address: map['address'] ?? '',
      lat: (locationMap['lat'] as num?)?.toDouble() ??
          (map['lat'] as num?)?.toDouble() ??
          0.0,
      lng: (locationMap['lng'] as num?)?.toDouble() ??
          (map['lng'] as num?)?.toDouble() ??
          0.0,
      status: TicketStatus.fromCode(map['status'] ?? 'OPEN'),
      selectedTukangId: map['selectedTukangId'],
      selectedTukangName: map['selectedTukangName'],
      bids: (map['bids'] as List<dynamic>? ?? [])
          .map((b) => BidModel.fromMap(b as Map<String, dynamic>))
          .toList(),
      finalBill: map['finalBill'] != null
          ? FinalBill.fromMap(map['finalBill'] as Map<String, dynamic>)
          : null,
      beforePhotos: List<String>.from(map['beforePhotos'] ?? []),
      afterPhotos: List<String>.from(map['afterPhotos'] ?? []),
      paymentMethod: map['paymentMethod'],
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      dokuInvoiceId: map['dokuInvoiceId'],
      ratingStars: (map['rating'] as Map<String, dynamic>?)?['stars'] as int?,
      ratingReview: (map['rating'] as Map<String, dynamic>?)?['review'] as String?,
      cancelReason: map['cancelReason'],
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    try {
      final dynamic dyn = val;
      if (dyn.toDate != null) return dyn.toDate() as DateTime;
    } catch (_) {}
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'category': category,
      'title': title,
      'description': description,
      'photoUrls': photoUrls,
      'address': address,
      'lat': lat,
      'lng': lng,
      'location': {'lat': lat, 'lng': lng},
      'status': status.code,
      'selectedTukangId': selectedTukangId,
      'selectedTukangName': selectedTukangName,
      'bids': bids.map((b) => b.toMap()).toList(),
      'finalBill': finalBill?.toMap(),
      'beforePhotos': beforePhotos,
      'afterPhotos': afterPhotos,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'dokuInvoiceId': dokuInvoiceId,
      'rating': ratingStars != null
          ? {'stars': ratingStars, 'review': ratingReview}
          : null,
      'cancelReason': cancelReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
