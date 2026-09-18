import 'package:equatable/equatable.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/ticket_status.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();
  @override
  List<Object?> get props => [];
}

class CreateTicketRequestedEvent extends TicketEvent {
  final String userId;
  final String userName;
  final String category;
  final String title;
  final String description;
  final List<String> photoUrls;
  final String address;
  final double lat;
  final double lng;

  const CreateTicketRequestedEvent({
    required this.userId,
    required this.userName,
    required this.category,
    required this.title,
    required this.description,
    required this.photoUrls,
    required this.address,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [userId, userName, category, title, description, photoUrls, address, lat, lng];
}

class FetchTukangRadarTicketsEvent extends TicketEvent {
  final List<String> services;
  final double lat;
  final double lng;
  final double radiusKm;
  final String? tukangId;

  const FetchTukangRadarTicketsEvent({
    required this.services,
    required this.lat,
    required this.lng,
    this.radiusKm = 15.0,
    this.tukangId,
  });

  @override
  List<Object?> get props => [services, lat, lng, radiusKm, tukangId];
}

class SubmitBidRequestedEvent extends TicketEvent {
  final String ticketId;
  final String tukangId;
  final String tukangName;
  final String? tukangPhoto;
  final double tukangRating;
  final double estimatedPrice;
  final String note;

  const SubmitBidRequestedEvent({
    required this.ticketId,
    required this.tukangId,
    required this.tukangName,
    this.tukangPhoto,
    required this.tukangRating,
    required this.estimatedPrice,
    required this.note,
  });

  @override
  List<Object?> get props => [ticketId, tukangId, tukangName, tukangPhoto, tukangRating, estimatedPrice, note];
}

class LockTukangRequestedEvent extends TicketEvent {
  final String ticketId;
  final String selectedTukangId;
  final String selectedTukangName;

  const LockTukangRequestedEvent({
    required this.ticketId,
    required this.selectedTukangId,
    required this.selectedTukangName,
  });

  @override
  List<Object?> get props => [ticketId, selectedTukangId, selectedTukangName];
}

class UpdateTicketStatusRequestedEvent extends TicketEvent {
  final String ticketId;
  final TicketStatus newStatus;
  final String? cancelReason;

  const UpdateTicketStatusRequestedEvent({
    required this.ticketId,
    required this.newStatus,
    this.cancelReason,
  });

  @override
  List<Object?> get props => [ticketId, newStatus, cancelReason];
}

class SubmitFinalBillRequestedEvent extends TicketEvent {
  final String ticketId;
  final List<BillItem> items;

  const SubmitFinalBillRequestedEvent({
    required this.ticketId,
    required this.items,
  });

  @override
  List<Object?> get props => [ticketId, items];
}

class ApproveFinalBillRequestedEvent extends TicketEvent {
  final String ticketId;
  const ApproveFinalBillRequestedEvent(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class UploadWorkPhotosRequestedEvent extends TicketEvent {
  final String ticketId;
  final bool isBefore;
  final List<String> photoPaths;

  const UploadWorkPhotosRequestedEvent({
    required this.ticketId,
    required this.isBefore,
    required this.photoPaths,
  });

  @override
  List<Object?> get props => [ticketId, isBefore, photoPaths];
}

class FetchUserTicketsEvent extends TicketEvent {
  final String userId;
  const FetchUserTicketsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class FetchTukangActiveTicketsEvent extends TicketEvent {
  final String tukangId;
  const FetchTukangActiveTicketsEvent(this.tukangId);
  @override
  List<Object?> get props => [tukangId];
}
