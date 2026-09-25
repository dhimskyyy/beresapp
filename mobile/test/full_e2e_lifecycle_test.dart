import 'package:flutter_test/flutter_test.dart';
import 'package:beresapp/data/models/ticket_model.dart';
import 'package:beresapp/domain/entities/ticket_status.dart';
import 'package:beresapp/domain/repositories/ticket_repository.dart';
import 'package:beresapp/domain/repositories/payment_repository.dart';
import 'package:beresapp/features/ticket/bloc/ticket_bloc.dart';
import 'package:beresapp/features/ticket/bloc/ticket_event.dart';
import 'package:beresapp/features/ticket/bloc/ticket_state.dart';
import 'package:beresapp/features/payment/bloc/payment_bloc.dart';
import 'package:beresapp/features/payment/bloc/payment_event.dart';
import 'package:beresapp/features/payment/bloc/payment_state.dart';

class MockFullLifecycleTicketRepository implements TicketRepository {
  TicketModel? currentTicket;

  bool _isValidStatusTransition(TicketStatus current, TicketStatus next) {
    if (current == next) return true;
    const transitions = {
      TicketStatus.open: {TicketStatus.bidding, TicketStatus.canceled},
      TicketStatus.bidding: {TicketStatus.locked, TicketStatus.canceled},
      TicketStatus.locked: {TicketStatus.onTheWay, TicketStatus.canceled},
      TicketStatus.onTheWay: {TicketStatus.arrived},
      TicketStatus.arrived: {TicketStatus.inProgress},
      TicketStatus.inProgress: {TicketStatus.workCompleted},
      TicketStatus.workCompleted: {TicketStatus.paymentPending},
      TicketStatus.paymentPending: {TicketStatus.completed},
      TicketStatus.completed: <TicketStatus>{},
      TicketStatus.canceled: <TicketStatus>{},
    };
    return transitions[current]?.contains(next) ?? false;
  }

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
    currentTicket = TicketModel(
      id: 'TCK-TEST-001',
      userId: userId,
      userName: userName,
      category: category,
      title: title,
      description: description,
      photoUrls: photoUrls,
      address: address,
      lat: lat,
      lng: lng,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<List<TicketModel>> getOpenTicketsForTukang({
    required List<String> tukangServices,
    required double tukangLat,
    required double tukangLng,
    double radiusKm = 15.0,
    String? currentTukangId,
  }) async {
    if (currentTicket == null) return [];
    if (tukangServices.contains(currentTicket!.category) &&
        (currentTicket!.status == TicketStatus.open || currentTicket!.status == TicketStatus.bidding)) {
      return [currentTicket!];
    }
    return [];
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
    if (currentTicket == null) throw Exception('Tiket tidak ditemukan');
    final bids = List<BidModel>.from(currentTicket!.bids);
    bids.add(BidModel(
      tukangId: tukangId,
      tukangName: tukangName,
      tukangPhoto: tukangPhoto,
      tukangRating: tukangRating,
      estimatedPrice: estimatedPrice,
      note: note,
      createdAt: DateTime.now(),
    ));

    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: TicketStatus.bidding,
      selectedTukangId: currentTicket!.selectedTukangId,
      selectedTukangName: currentTicket!.selectedTukangName,
      bids: bids,
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<TicketModel> lockTukang({
    required String ticketId,
    required String selectedTukangId,
    required String selectedTukangName,
  }) async {
    if (currentTicket == null) throw Exception('Tiket tidak ditemukan');
    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: TicketStatus.locked,
      selectedTukangId: selectedTukangId,
      selectedTukangName: selectedTukangName,
      bids: currentTicket!.bids,
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<TicketModel> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    String? cancelReason,
  }) async {
    if (currentTicket == null) throw Exception('Tiket tidak ditemukan');
    if (!_isValidStatusTransition(currentTicket!.status, newStatus)) {
      throw Exception('Transisi ilegal dari ${currentTicket!.status.code} ke ${newStatus.code}');
    }
    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: newStatus,
      selectedTukangId: currentTicket!.selectedTukangId,
      selectedTukangName: currentTicket!.selectedTukangName,
      bids: currentTicket!.bids,
      finalBill: currentTicket!.finalBill,
      beforePhotos: currentTicket!.beforePhotos,
      afterPhotos: currentTicket!.afterPhotos,
      paymentMethod: newStatus == TicketStatus.completed ? 'CASH' : currentTicket!.paymentMethod,
      paymentStatus: newStatus == TicketStatus.completed ? 'paid' : currentTicket!.paymentStatus,
      cancelReason: cancelReason ?? currentTicket!.cancelReason,
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<TicketModel> submitFinalBill({
    required String ticketId,
    required List<BillItem> items,
  }) async {
    final double total = items.fold(0, (acc, it) => acc + it.amount);
    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: currentTicket!.status,
      selectedTukangId: currentTicket!.selectedTukangId,
      selectedTukangName: currentTicket!.selectedTukangName,
      bids: currentTicket!.bids,
      finalBill: FinalBill(
        items: items,
        totalAmount: total,
        approvedByUser: false,
        createdAt: DateTime.now(),
      ),
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<TicketModel> approveFinalBill({required String ticketId}) async {
    final oldBill = currentTicket!.finalBill!;
    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: currentTicket!.status,
      selectedTukangId: currentTicket!.selectedTukangId,
      selectedTukangName: currentTicket!.selectedTukangName,
      bids: currentTicket!.bids,
      finalBill: FinalBill(
        items: oldBill.items,
        totalAmount: oldBill.totalAmount,
        approvedByUser: true,
        createdAt: oldBill.createdAt,
      ),
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<TicketModel> uploadWorkPhotos({
    required String ticketId,
    required bool isBefore,
    required List<String> photoPaths,
  }) async {
    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: currentTicket!.status,
      selectedTukangId: currentTicket!.selectedTukangId,
      selectedTukangName: currentTicket!.selectedTukangName,
      bids: currentTicket!.bids,
      finalBill: currentTicket!.finalBill,
      beforePhotos: isBefore ? photoPaths : currentTicket!.beforePhotos,
      afterPhotos: !isBefore ? photoPaths : currentTicket!.afterPhotos,
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<TicketModel> submitRatingReview({
    required String ticketId,
    required int stars,
    required String review,
  }) async {
    currentTicket = TicketModel(
      id: currentTicket!.id,
      userId: currentTicket!.userId,
      userName: currentTicket!.userName,
      category: currentTicket!.category,
      title: currentTicket!.title,
      description: currentTicket!.description,
      photoUrls: currentTicket!.photoUrls,
      address: currentTicket!.address,
      lat: currentTicket!.lat,
      lng: currentTicket!.lng,
      status: currentTicket!.status,
      selectedTukangId: currentTicket!.selectedTukangId,
      selectedTukangName: currentTicket!.selectedTukangName,
      bids: currentTicket!.bids,
      finalBill: currentTicket!.finalBill,
      beforePhotos: currentTicket!.beforePhotos,
      afterPhotos: currentTicket!.afterPhotos,
      paymentMethod: currentTicket!.paymentMethod,
      paymentStatus: currentTicket!.paymentStatus,
      ratingStars: stars,
      ratingReview: review,
      createdAt: currentTicket!.createdAt,
      updatedAt: DateTime.now(),
    );
    return currentTicket!;
  }

  @override
  Future<List<TicketModel>> getUserTickets(String userId) async => currentTicket != null ? [currentTicket!] : [];

  @override
  Future<List<TicketModel>> getTukangTickets(String tukangId) async => currentTicket != null ? [currentTicket!] : [];

  @override
  Future<TicketModel?> getTicketById(String ticketId) async => currentTicket;
}

class MockFullLifecyclePaymentRepository implements PaymentRepository {
  final MockFullLifecycleTicketRepository ticketRepo;
  MockFullLifecyclePaymentRepository(this.ticketRepo);

  @override
  Future<TicketModel> processPaymentSuccess({
    required String ticketId,
    required String paymentMethod,
  }) async {
    return ticketRepo.updateTicketStatus(
      ticketId: ticketId,
      newStatus: TicketStatus.completed,
    );
  }
}

void main() {
  group('End-to-End Pure Cash Lifecycle & State Machine Tests', () {
    late MockFullLifecycleTicketRepository mockTicketRepo;
    late MockFullLifecyclePaymentRepository mockPaymentRepo;
    late TicketBloc ticketBloc;
    late PaymentBloc paymentBloc;

    setUp(() {
      mockTicketRepo = MockFullLifecycleTicketRepository();
      mockPaymentRepo = MockFullLifecyclePaymentRepository(mockTicketRepo);
      ticketBloc = TicketBloc(ticketRepository: mockTicketRepo);
      paymentBloc = PaymentBloc(paymentRepository: mockPaymentRepo);
    });

    tearDown(() {
      ticketBloc.close();
      paymentBloc.close();
    });

    test('Lengkap: Siklus Hidup Pekerjaan dari OPEN sampai COMPLETED & RATING', () async {
      // Step 1: User membuat tiket baru
      ticketBloc.add(CreateTicketRequestedEvent(
        userId: 'USR-UID-123',
        userName: 'Siti Rahmawati',
        category: 'ac',
        title: 'AC Bocor & Kurang Dingin',
        description: 'Unit indoor meneteskan air deras sejak kemarin sore.',
        photoUrls: ['https://storage.beresapp.com/tickets/photo1.jpg'],
        address: 'Jl. Wijaya No. 10, Jakarta Selatan',
        lat: -6.2443,
        lng: 106.8021,
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TicketCreatedSuccessState>().having(
            (s) => s.ticket.status,
            'status',
            TicketStatus.open,
          ),
        ]),
      );

      expect(mockTicketRepo.currentTicket!.status, TicketStatus.open);
      expect(mockTicketRepo.currentTicket!.userId, 'USR-UID-123');

      // Step 2: Mitra Tukang melihat radar & mengajukan penawaran
      ticketBloc.add(SubmitBidRequestedEvent(
        ticketId: 'TCK-TEST-001',
        tukangId: 'TKG-UID-456',
        tukangName: 'Ahmad Subarjo',
        tukangPhoto: 'https://images.unsplash.com/avatar.jpg',
        tukangRating: 4.9,
        estimatedPrice: 150000,
        note: 'Bisa langsung meluncur bawa tangga dan freon R32.',
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<BidSubmittedSuccessState>().having(
            (s) => s.updatedTicket.status,
            'status',
            TicketStatus.bidding,
          ),
        ]),
      );

      expect(mockTicketRepo.currentTicket!.status, TicketStatus.bidding);
      expect(mockTicketRepo.currentTicket!.bids.length, 1);
      expect(mockTicketRepo.currentTicket!.bids.first.estimatedPrice, 150000);

      // Step 3: User mengunci dan memilih Mitra Tukang
      ticketBloc.add(LockTukangRequestedEvent(
        ticketId: 'TCK-TEST-001',
        selectedTukangId: 'TKG-UID-456',
        selectedTukangName: 'Ahmad Subarjo',
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.status,
            'status',
            TicketStatus.locked,
          ),
        ]),
      );

      expect(mockTicketRepo.currentTicket!.status, TicketStatus.locked);
      expect(mockTicketRepo.currentTicket!.selectedTukangId, 'TKG-UID-456');

      // Step 4: Tukang berangkat OTW
      ticketBloc.add(UpdateTicketStatusRequestedEvent(
        ticketId: 'TCK-TEST-001',
        newStatus: TicketStatus.onTheWay,
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.status,
            'status',
            TicketStatus.onTheWay,
          ),
        ]),
      );

      // Step 5: Tukang tiba di lokasi
      ticketBloc.add(UpdateTicketStatusRequestedEvent(
        ticketId: 'TCK-TEST-001',
        newStatus: TicketStatus.arrived,
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.status,
            'status',
            TicketStatus.arrived,
          ),
        ]),
      );

      // Step 6: Tukang input Nota Kesepakatan di Chat
      ticketBloc.add(SubmitFinalBillRequestedEvent(
        ticketId: 'TCK-TEST-001',
        items: [
          BillItem(title: 'Cuci Unit AC Standar', amount: 75000),
          BillItem(title: 'Tambah Freon R32', amount: 75000),
        ],
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>(),
        ]),
      );

      expect(mockTicketRepo.currentTicket!.finalBill!.totalAmount, 150000);
      expect(mockTicketRepo.currentTicket!.finalBill!.approvedByUser, isFalse);

      // User menyetujui Nota di Chat
      ticketBloc.add(ApproveFinalBillRequestedEvent('TCK-TEST-001'));
      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>(),
        ]),
      );
      expect(mockTicketRepo.currentTicket!.finalBill!.approvedByUser, isTrue);

      // Step 7: Tukang upload foto Before & mulai pengerjaan
      ticketBloc.add(UploadWorkPhotosRequestedEvent(
        ticketId: 'TCK-TEST-001',
        isBefore: true,
        photoPaths: ['https://storage.beresapp.com/before1.jpg'],
      ));
      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>(),
        ]),
      );

      ticketBloc.add(UpdateTicketStatusRequestedEvent(
        ticketId: 'TCK-TEST-001',
        newStatus: TicketStatus.inProgress,
      ));
      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.status,
            'status',
            TicketStatus.inProgress,
          ),
        ]),
      );

      // Step 8: Tukang upload foto After & selesaikan pengerjaan
      ticketBloc.add(UploadWorkPhotosRequestedEvent(
        ticketId: 'TCK-TEST-001',
        isBefore: false,
        photoPaths: ['https://storage.beresapp.com/after1.jpg'],
      ));
      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>(),
        ]),
      );

      ticketBloc.add(UpdateTicketStatusRequestedEvent(
        ticketId: 'TCK-TEST-001',
        newStatus: TicketStatus.workCompleted,
      ));
      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.status,
            'status',
            TicketStatus.workCompleted,
          ),
        ]),
      );

      ticketBloc.add(UpdateTicketStatusRequestedEvent(
        ticketId: 'TCK-TEST-001',
        newStatus: TicketStatus.paymentPending,
      ));
      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.status,
            'status',
            TicketStatus.paymentPending,
          ),
        ]),
      );

      // Step 9: User/Tukang konfirmasi pembayaran TUNAI (Pure Cash)
      paymentBloc.add(ConfirmPaymentSuccessRequestedEvent(
        ticketId: 'TCK-TEST-001',
        paymentMethod: 'CASH',
      ));

      await expectLater(
        paymentBloc.stream,
        emitsInOrder([
          isA<PaymentLoadingState>(),
          isA<PaymentCompletedSuccessState>().having(
            (s) => s.paidTicket.status,
            'status',
            TicketStatus.completed,
          ),
        ]),
      );

      expect(mockTicketRepo.currentTicket!.status, TicketStatus.completed);
      expect(mockTicketRepo.currentTicket!.paymentMethod, 'CASH');
      expect(mockTicketRepo.currentTicket!.paymentStatus, 'paid');

      // Step 10: User berikan rating bintang 5 & ulasan
      ticketBloc.add(SubmitRatingReviewRequestedEvent(
        ticketId: 'TCK-TEST-001',
        stars: 5,
        review: 'Kerja rapi, cepat, dan sangat sopan. Sangat direkomendasikan!',
      ));

      await expectLater(
        ticketBloc.stream,
        emitsInOrder([
          isA<TicketLoadingState>(),
          isA<TukangLockedSuccessState>().having(
            (s) => s.lockedTicket.ratingStars,
            'ratingStars',
            5,
          ),
        ]),
      );

      expect(mockTicketRepo.currentTicket!.ratingStars, 5);
      expect(mockTicketRepo.currentTicket!.ratingReview, contains('sangat sopan'));
    });

    test('Validasi Transisi Ilegal Ditolak: Tidak bisa lompat dari OPEN ke COMPLETED', () async {
      await mockTicketRepo.createTicket(
        userId: 'USR-001',
        userName: 'Siti',
        category: 'ac',
        title: 'AC Rusak',
        description: 'Bocor',
        photoUrls: [],
        address: 'Jakarta',
        lat: -6.2,
        lng: 106.8,
      );

      expect(
        () => mockTicketRepo.updateTicketStatus(
          ticketId: 'TCK-TEST-001',
          newStatus: TicketStatus.completed,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Validasi Pembatalan: User hanya bisa batal pada OPEN, BIDDING, LOCKED', () {
      expect(TicketStatus.open.canUserCancelDirectly, isTrue);
      expect(TicketStatus.bidding.canUserCancelDirectly, isTrue);
      expect(TicketStatus.locked.canUserCancelDirectly, isTrue);
      expect(TicketStatus.onTheWay.canUserCancelDirectly, isFalse);
      expect(TicketStatus.arrived.canUserCancelDirectly, isFalse);
      expect(TicketStatus.inProgress.canUserCancelDirectly, isFalse);
      expect(TicketStatus.paymentPending.canUserCancelDirectly, isFalse);
      expect(TicketStatus.completed.canUserCancelDirectly, isFalse);
    });

    test('Data Model Integrity: toMap dan fromMap konsisten', () {
      final now = DateTime.now();
      final model = TicketModel(
        id: 'TCK-999',
        userId: 'USR-888',
        userName: 'Budi Santoso',
        category: 'elektronik',
        title: 'TV Mati Total',
        description: 'Lampu indikator tidak menyala',
        photoUrls: ['https://example.com/tv.jpg'],
        address: 'Jl. Sudirman No. 45',
        lat: -6.2088,
        lng: 106.8456,
        status: TicketStatus.paymentPending,
        selectedTukangId: 'TKG-777',
        selectedTukangName: 'Pak Joko',
        bids: [
          BidModel(
            tukangId: 'TKG-777',
            tukangName: 'Pak Joko',
            estimatedPrice: 200000,
            note: 'Siap servis',
            createdAt: now,
          ),
        ],
        finalBill: FinalBill(
          items: [BillItem(title: 'Ganti IC Power', amount: 200000)],
          totalAmount: 200000,
          approvedByUser: true,
          createdAt: now,
        ),
        paymentMethod: 'CASH',
        paymentStatus: 'paid',
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      final reconstructed = TicketModel.fromMap(map, 'TCK-999');

      expect(reconstructed.id, model.id);
      expect(reconstructed.userId, model.userId);
      expect(reconstructed.status, TicketStatus.paymentPending);
      expect(reconstructed.lat, model.lat);
      expect(reconstructed.lng, model.lng);
      expect(reconstructed.finalBill!.totalAmount, 200000);
      expect(reconstructed.finalBill!.approvedByUser, isTrue);
      expect(reconstructed.paymentMethod, 'CASH');
      expect(reconstructed.paymentStatus, 'paid');
    });
  });
}
