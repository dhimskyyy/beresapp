import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/ticket_status.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/ticket_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<TicketModel> processPaymentSuccess({
    required String ticketId,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // 1. Fetch current ticket from Firestore if available
    TicketModel? existingTicket;
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists && doc.data() != null) {
        existingTicket = TicketModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {}

    final String tukangId = existingTicket?.selectedTukangId ?? 'TKG-001';

    // 2. Construct updated ticket model for pure cash payment
    final updatedTicket = TicketModel(
      id: existingTicket?.id ?? ticketId,
      userId: existingTicket?.userId ?? 'USR-001',
      userName: existingTicket?.userName ?? 'Siti Rahmawati',
      category: existingTicket?.category ?? 'ac',
      title: existingTicket?.title ?? 'Pekerjaan Selesai',
      description: existingTicket?.description ?? 'Pekerjaan telah selesai dan lunas tunai.',
      photoUrls: existingTicket?.photoUrls ?? [],
      address: existingTicket?.address ?? 'Lokasi Konsumen',
      lat: existingTicket?.lat ?? -6.2088,
      lng: existingTicket?.lng ?? 106.8456,
      status: TicketStatus.completed,
      selectedTukangId: tukangId,
      selectedTukangName: existingTicket?.selectedTukangName ?? 'Mitra Tukang',
      bids: existingTicket?.bids ?? [],
      finalBill: existingTicket?.finalBill,
      beforePhotos: existingTicket?.beforePhotos ?? [],
      afterPhotos: existingTicket?.afterPhotos ?? [],
      paymentMethod: 'CASH',
      paymentStatus: 'paid',
      dokuInvoiceId: null,
      ratingStars: existingTicket?.ratingStars,
      ratingReview: existingTicket?.ratingReview,
      cancelReason: existingTicket?.cancelReason,
      createdAt: existingTicket?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 3. Sync ticket status directly to Cloud Firestore
    try {
      debugPrint('[PaymentRepo] Mengonfirmasi pembayaran tunai tiket $ticketId ke Cloud Firestore...');
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'COMPLETED',
        'paymentMethod': 'CASH',
        'paymentStatus': 'paid',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('[PaymentRepo] SUKSES: Pembayaran tunai tiket $ticketId tersimpan di Cloud Firestore!');
    } catch (e) {
      debugPrint('[PaymentRepo] Warning update Firestore: $e, mencoba set merge...');
      try {
        await _firestore.collection('tickets').doc(ticketId).set(
          updatedTicket.toMap(),
          SetOptions(merge: true),
        );
      } catch (err) {
        debugPrint('[PaymentRepo] GAGAL menyimpan status tiket ke Firestore: $err');
        rethrow;
      }
    }

    return updatedTicket;
  }
}
