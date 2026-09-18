import '../../domain/entities/ticket_status.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../models/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
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
    await Future.delayed(const Duration(milliseconds: 1000));
    final ticket = TicketModel(
      id: 'TCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
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
    _mockTickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<List<TicketModel>> getOpenTicketsForTukang({
    required List<String> tukangServices,
    required double tukangLat,
    required double tukangLng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockTickets.where((t) {
      final isMatchingService = tukangServices.contains(t.category);
      final isOpenForBidding = t.status == TicketStatus.open || t.status == TicketStatus.bidding;
      return isMatchingService && isOpenForBidding;
    }).toList();
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
    
    // Remove previous bid by same tukang if any
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
    return updatedTicket;
  }

  @override
  Future<TicketModel> lockTukang({
    required String ticketId,
    required String selectedTukangId,
    required String selectedTukangName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
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
    return updatedTicket;
  }

  @override
  Future<List<TicketModel>> getUserTickets(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTickets.where((t) => t.userId == userId).toList();
  }

  @override
  Future<List<TicketModel>> getTukangTickets(String tukangId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTickets.where((t) => t.selectedTukangId == tukangId || t.bids.any((b) => b.tukangId == tukangId)).toList();
  }

  @override
  Future<TicketModel?> getTicketById(String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockTickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }
}
