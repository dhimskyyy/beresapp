import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../domain/entities/ticket_status.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../models/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _syncToFirestore(TicketModel ticket) async {
    try {
      await _firestore.collection('tickets').doc(ticket.id).set(ticket.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync note for ${ticket.id}: $e');
    }
  }

  static final List<TicketModel> _mockTickets = [
    TicketModel(
      id: 'TCK-801',
      userId: 'USR-001',
      userName: 'Siti Rahmawati',
      category: 'ac',
      title: 'AC Daikin 1 PK Kamar Tidur Bocor Menetes',
      description: 'Air menetes deras dari indoor unit sejak tadi malam dan angin AC kurang dingin. Perlu dicek pipa pembuangan.',
      photoUrls: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600'],
      address: 'Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan',
      lat: -6.2382,
      lng: 106.8123,
      status: TicketStatus.onTheWay,
      selectedTukangId: 'TKG-001',
      selectedTukangName: 'Ahmad Subarjo',
      bids: [
        BidModel(
          tukangId: 'TKG-001',
          tukangName: 'Ahmad Subarjo',
          tukangPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          tukangRating: 4.9,
          estimatedPrice: 150000,
          note: 'Siap datang langsung bawa steam cuci AC dan alat cek freon.',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      finalBill: FinalBill(
        items: [
          BillItem(title: 'Jasa Cuci Servis AC 1 PK', amount: 75000),
          BillItem(title: 'Pembersihan Selang Pembuangan Tersumbat', amount: 50000),
        ],
        totalAmount: 125000,
        approvedByUser: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      beforePhotos: ['https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    TicketModel(
      id: 'TCK-802',
      userId: 'USR-002',
      userName: 'Dimas Anggara',
      category: 'plumbing',
      title: 'Pipa Saluran Cuci Piring Mampet Total',
      description: 'Air tidak bisa mengalir sama sekali di sink dapur. Sudah dicoba tuang air panas tetap buntu.',
      photoUrls: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600'],
      address: 'Apartemen Sudirman Tower A-12, Jakarta Pusat',
      lat: -6.2155,
      lng: 106.8198,
      status: TicketStatus.bidding,
      selectedTukangId: null,
      selectedTukangName: null,
      bids: [
        BidModel(
          tukangId: 'TKG-001',
          tukangName: 'Ahmad Subarjo',
          tukangPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          tukangRating: 4.9,
          estimatedPrice: 175000,
          note: 'Akan kami tembak dengan kompresor pipa mampet spiral.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    TicketModel(
      id: 'TCK-800',
      userId: 'USR-001',
      userName: 'Siti Rahmawati',
      category: 'ac',
      title: 'Servis AC & Cuci Besar Ruang Tamu',
      description: 'AC 2 PK kotor dan tidak dingin, tolong dicuci total dan cek tekanan gas freon.',
      photoUrls: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600'],
      address: 'Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan',
      lat: -6.2382,
      lng: 106.8123,
      status: TicketStatus.completed,
      selectedTukangId: 'TKG-001',
      selectedTukangName: 'Ahmad Subarjo',
      bids: [
        BidModel(
          tukangId: 'TKG-001',
          tukangName: 'Ahmad Subarjo',
          tukangPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          tukangRating: 5.0,
          estimatedPrice: 220000,
          note: 'Bawa tangga aluminium dan mesin cuci bertekanan.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      finalBill: FinalBill(
        items: [
          BillItem(title: 'Cuci Steam AC 2 PK', amount: 95000),
          BillItem(title: 'Tambah Freon R32', amount: 130000),
        ],
        totalAmount: 225000,
        approvedByUser: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      ratingStars: 5,
      ratingReview: 'Pelayanan sangat ramah, pengerjaan cepat dan bersih! AC langsung dingin semriwing.',
      beforePhotos: ['https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600'],
      afterPhotos: ['https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=600'],
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TicketModel(
      id: 'TCK-799',
      userId: 'USR-003',
      userName: 'Hendra Gunawan',
      category: 'plumbing',
      title: 'Ganti Kran Wastafel & Perbaikan Pipa Bocor',
      description: 'Kran patah dan pipa bawah wastafel bocor membasahi kabinet.',
      photoUrls: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600'],
      address: 'Cluster Menteng Indah Blok C3 No. 5, Jakarta Selatan',
      lat: -6.2215,
      lng: 106.8250,
      status: TicketStatus.completed,
      selectedTukangId: 'TKG-001',
      selectedTukangName: 'Ahmad Subarjo',
      bids: [
        BidModel(
          tukangId: 'TKG-001',
          tukangName: 'Ahmad Subarjo',
          tukangPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          tukangRating: 4.8,
          estimatedPrice: 160000,
          note: 'Siap ganti seal dan kran fleksibel baru.',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      finalBill: FinalBill(
        items: [
          BillItem(title: 'Jasa Pemasangan & Bongkar Kran', amount: 80000),
          BillItem(title: 'Kran Wastafel Fleksibel Stainless', amount: 95000),
        ],
        totalAmount: 175000,
        approvedByUser: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
      ),
      ratingStars: 5,
      ratingReview: 'Tukang datang tepat waktu, bawa alat komplit, pipa tidak bocor lagi.',
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TicketModel(
      id: 'TCK-798',
      userId: 'USR-004',
      userName: 'Rina Kartika',
      category: 'electricity',
      title: 'MCB Listrik Sering Jeglek Tiba-Tiba',
      description: 'Setiap menyalakan oven dan dispenser MCB meteran langsung turun.',
      photoUrls: ['https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600'],
      address: 'Jl. Radio Dalam Raya No. 45, Jakarta Selatan',
      lat: -6.2550,
      lng: 106.7900,
      status: TicketStatus.canceled,
      selectedTukangId: 'TKG-001',
      selectedTukangName: 'Ahmad Subarjo',
      bids: [],
      cancelReason: 'Dibatalkan konsumen sebelum mitra berangkat',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  Future<TicketModel> createTicket({
    required String userId,
    required String userName,
    required String category,
    required String title,
    required String description,
    required List<String> photoUrls,
    required String address,
    required double lat,
    required double lng,
  }) async {
    // Upload issue photos to Supabase Storage
    final uploadedUrls = await SupabaseStorageService.uploadMultipleImages(
      filePaths: photoUrls,
      folder: 'tickets',
    );

    final ticket = TicketModel(
      id: 'TCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: userId,
      userName: userName,
      category: category,
      title: title,
      description: description,
      photoUrls: uploadedUrls,
      address: address,
      lat: lat,
      lng: lng,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockTickets.insert(0, ticket);
    await _syncToFirestore(ticket);
    return ticket;
  }

  @override
  Future<List<TicketModel>> getOpenTicketsForTukang({
    required List<String> tukangServices,
    required double tukangLat,
    required double tukangLng,
    double radiusKm = 15.0,
    String? currentTukangId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('status', whereIn: ['OPEN', 'BIDDING'])
          .get();
      for (final doc in snapshot.docs) {
        final t = TicketModel.fromMap(doc.data(), doc.id);
        final idx = _mockTickets.indexWhere((m) => m.id == t.id);
        if (idx != -1) {
          _mockTickets[idx] = t;
        } else {
          _mockTickets.insert(0, t);
        }
      }
    } catch (e) {
      debugPrint('Firestore getOpenTicketsForTukang fallback note: $e');
    }

    return _mockTickets.where((t) {
      final isMatchingService = tukangServices.contains(t.category);

      // Once locked by user for a specific tukang, hide it for all OTHER tukangs!
      final isStillOpenForOthers = t.status == TicketStatus.open || t.status == TicketStatus.bidding;
      final isMyLockedJob = (t.status == TicketStatus.locked || t.status == TicketStatus.onTheWay || t.status == TicketStatus.inProgress) &&
          t.selectedTukangId == currentTukangId;

      final isEligibleStatus = isStillOpenForOthers || isMyLockedJob;

      // Real distance calculation (Haversine formula in KM)
      final distanceKm = _calculateHaversineDistance(tukangLat, tukangLng, t.lat, t.lng);
      final isWithinRadius = distanceKm <= radiusKm;

      return isMatchingService && isEligibleStatus && isWithinRadius;
    }).toList();
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0.0 && lon1 == 0.0) return 0.0;
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
            math.cos(lat1 * p) * math.cos(lat2 * p) * 
            (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R (6371 km)
  }

  @override
  Future<TicketModel> submitBid({
    required String ticketId,
    required String tukangId,
    required String tukangName,
    required String? tukangPhoto,
    required double tukangRating,
    required double estimatedPrice,
    required String note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Tiket tidak ditemukan');

    final oldTicket = _mockTickets[index];
    final updatedBids = List<BidModel>.from(oldTicket.bids);
    updatedBids.removeWhere((b) => b.tukangId == tukangId);
    updatedBids.add(BidModel(
      tukangId: tukangId,
      tukangName: tukangName,
      tukangPhoto: tukangPhoto,
      tukangRating: tukangRating,
      estimatedPrice: estimatedPrice,
      note: note,
      createdAt: DateTime.now(),
    ));

    final updatedTicket = TicketModel(
      id: oldTicket.id,
      userId: oldTicket.userId,
      userName: oldTicket.userName,
      category: oldTicket.category,
      title: oldTicket.title,
      description: oldTicket.description,
      photoUrls: oldTicket.photoUrls,
      address: oldTicket.address,
      lat: oldTicket.lat,
      lng: oldTicket.lng,
      status: TicketStatus.bidding,
      selectedTukangId: oldTicket.selectedTukangId,
      selectedTukangName: oldTicket.selectedTukangName,
      bids: updatedBids,
      finalBill: oldTicket.finalBill,
      beforePhotos: oldTicket.beforePhotos,
      afterPhotos: oldTicket.afterPhotos,
      paymentMethod: oldTicket.paymentMethod,
      paymentStatus: oldTicket.paymentStatus,
      createdAt: oldTicket.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updatedTicket;
    await _syncToFirestore(updatedTicket);
    return updatedTicket;
  }

  @override
  Future<TicketModel> lockTukang({
    required String ticketId,
    required String selectedTukangId,
    required String selectedTukangName,
  }) async {
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Tiket tidak ditemukan');

    final oldTicket = _mockTickets[index];
    final updatedTicket = TicketModel(
      id: oldTicket.id,
      userId: oldTicket.userId,
      userName: oldTicket.userName,
      category: oldTicket.category,
      title: oldTicket.title,
      description: oldTicket.description,
      photoUrls: oldTicket.photoUrls,
      address: oldTicket.address,
      lat: oldTicket.lat,
      lng: oldTicket.lng,
      status: TicketStatus.locked,
      selectedTukangId: selectedTukangId,
      selectedTukangName: selectedTukangName,
      bids: oldTicket.bids,
      finalBill: oldTicket.finalBill,
      beforePhotos: oldTicket.beforePhotos,
      afterPhotos: oldTicket.afterPhotos,
      paymentMethod: oldTicket.paymentMethod,
      paymentStatus: oldTicket.paymentStatus,
      createdAt: oldTicket.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updatedTicket;
    await _syncToFirestore(updatedTicket);
    return updatedTicket;
  }

  @override
  Future<TicketModel> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    String? cancelReason,
  }) async {
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Tiket tidak ditemukan');

    final old = _mockTickets[index];
    final updated = TicketModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      category: old.category,
      title: old.title,
      description: old.description,
      photoUrls: old.photoUrls,
      address: old.address,
      lat: old.lat,
      lng: old.lng,
      status: newStatus,
      selectedTukangId: old.selectedTukangId,
      selectedTukangName: old.selectedTukangName,
      bids: old.bids,
      finalBill: old.finalBill,
      beforePhotos: old.beforePhotos,
      afterPhotos: old.afterPhotos,
      paymentMethod: old.paymentMethod,
      paymentStatus: old.paymentStatus,
      cancelReason: cancelReason ?? old.cancelReason,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updated;
    await _syncToFirestore(updated);
    return updated;
  }

  @override
  Future<TicketModel> submitFinalBill({
    required String ticketId,
    required List<BillItem> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Tiket tidak ditemukan');

    final old = _mockTickets[index];
    final double total = items.fold(0, (sum, item) => sum + item.amount);

    final finalBill = FinalBill(
      items: items,
      totalAmount: total,
      approvedByUser: false,
      createdAt: DateTime.now(),
    );

    final updated = TicketModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      category: old.category,
      title: old.title,
      description: old.description,
      photoUrls: old.photoUrls,
      address: old.address,
      lat: old.lat,
      lng: old.lng,
      status: old.status,
      selectedTukangId: old.selectedTukangId,
      selectedTukangName: old.selectedTukangName,
      bids: old.bids,
      finalBill: finalBill,
      beforePhotos: old.beforePhotos,
      afterPhotos: old.afterPhotos,
      paymentMethod: old.paymentMethod,
      paymentStatus: old.paymentStatus,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updated;
    await _syncToFirestore(updated);
    return updated;
  }

  @override
  Future<TicketModel> approveFinalBill({required String ticketId}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Tiket tidak ditemukan');

    final old = _mockTickets[index];
    if (old.finalBill == null) throw Exception('Tagihan belum diinput oleh tukang');

    final updatedBill = FinalBill(
      items: old.finalBill!.items,
      totalAmount: old.finalBill!.totalAmount,
      approvedByUser: true,
      createdAt: old.finalBill!.createdAt,
    );

    final updated = TicketModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      category: old.category,
      title: old.title,
      description: old.description,
      photoUrls: old.photoUrls,
      address: old.address,
      lat: old.lat,
      lng: old.lng,
      status: old.status,
      selectedTukangId: old.selectedTukangId,
      selectedTukangName: old.selectedTukangName,
      bids: old.bids,
      finalBill: updatedBill,
      beforePhotos: old.beforePhotos,
      afterPhotos: old.afterPhotos,
      paymentMethod: old.paymentMethod,
      paymentStatus: old.paymentStatus,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updated;
    await _syncToFirestore(updated);
    return updated;
  }

  @override
  Future<TicketModel> uploadWorkPhotos({
    required String ticketId,
    required bool isBefore,
    required List<String> photoPaths,
  }) async {
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Tiket tidak ditemukan');

    // Upload work photos to Supabase Storage
    final uploadedUrls = await SupabaseStorageService.uploadMultipleImages(
      filePaths: photoPaths,
      folder: 'work_photos',
    );

    final old = _mockTickets[index];
    final updated = TicketModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      category: old.category,
      title: old.title,
      description: old.description,
      photoUrls: old.photoUrls,
      address: old.address,
      lat: old.lat,
      lng: old.lng,
      status: old.status,
      selectedTukangId: old.selectedTukangId,
      selectedTukangName: old.selectedTukangName,
      bids: old.bids,
      finalBill: old.finalBill,
      beforePhotos: isBefore ? uploadedUrls : old.beforePhotos,
      afterPhotos: !isBefore ? uploadedUrls : old.afterPhotos,
      paymentMethod: old.paymentMethod,
      paymentStatus: old.paymentStatus,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updated;
    await _syncToFirestore(updated);
    return updated;
  }

  @override
  Future<List<TicketModel>> getUserTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final cloudTickets = snapshot.docs
            .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
            .toList();
        for (final ct in cloudTickets) {
          final idx = _mockTickets.indexWhere((m) => m.id == ct.id);
          if (idx != -1) {
            _mockTickets[idx] = ct;
          } else {
            _mockTickets.add(ct);
          }
        }
      }
    } catch (_) {
      // Fallback silently
    }
    return _mockTickets.where((t) => t.userId == userId).toList();
  }

  @override
  Future<List<TicketModel>> getTukangTickets(String tukangId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('selectedTukangId', isEqualTo: tukangId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final cloudTickets = snapshot.docs
            .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
            .toList();
        for (final ct in cloudTickets) {
          final idx = _mockTickets.indexWhere((m) => m.id == ct.id);
          if (idx != -1) {
            _mockTickets[idx] = ct;
          } else {
            _mockTickets.add(ct);
          }
        }
      }
    } catch (_) {
      // Fallback silently
    }
    return _mockTickets.where((t) => t.selectedTukangId == tukangId || t.bids.any((b) => b.tukangId == tukangId)).toList();
  }

  @override
  Future<TicketModel?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists && doc.data() != null) {
        final cloudTicket = TicketModel.fromMap(doc.data()!, doc.id);
        final idx = _mockTickets.indexWhere((t) => t.id == ticketId);
        if (idx != -1) {
          _mockTickets[idx] = cloudTicket;
        } else {
          _mockTickets.add(cloudTicket);
        }
        return cloudTicket;
      }
    } catch (_) {
      // Fallback to cache
    }
    try {
      return _mockTickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TicketModel> submitRatingReview({
    required String ticketId,
    required int stars,
    required String review,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw Exception('Ticket $ticketId not found');

    final old = _mockTickets[index];
    final updated = TicketModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      category: old.category,
      title: old.title,
      description: old.description,
      photoUrls: old.photoUrls,
      address: old.address,
      lat: old.lat,
      lng: old.lng,
      status: old.status,
      selectedTukangId: old.selectedTukangId,
      selectedTukangName: old.selectedTukangName,
      bids: old.bids,
      finalBill: old.finalBill,
      beforePhotos: old.beforePhotos,
      afterPhotos: old.afterPhotos,
      paymentMethod: old.paymentMethod,
      paymentStatus: old.paymentStatus,
      dokuInvoiceId: old.dokuInvoiceId,
      ratingStars: stars,
      ratingReview: review,
      cancelReason: old.cancelReason,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockTickets[index] = updated;
    await _syncToFirestore(updated);
    return updated;
  }
}
