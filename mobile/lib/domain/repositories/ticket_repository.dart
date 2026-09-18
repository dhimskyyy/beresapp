import '../../data/models/ticket_model.dart';

abstract class TicketRepository {
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
  });

  Future<List<TicketModel>> getOpenTicketsForTukang({
    required List<String> tukangServices,
    required double tukangLat,
    required double tukangLng,
  });

  Future<TicketModel> submitBid({
    required String ticketId,
    required String tukangId,
    required String tukangName,
    required String? tukangPhoto,
    required double tukangRating,
    required double estimatedPrice,
    required String note,
  });

  Future<TicketModel> lockTukang({
    required String ticketId,
    required String selectedTukangId,
    required String selectedTukangName,
  });

  Future<List<TicketModel>> getUserTickets(String userId);
  Future<List<TicketModel>> getTukangTickets(String tukangId);
  Future<TicketModel?> getTicketById(String ticketId);
}
