import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/ticket_repository.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository ticketRepository;

  TicketBloc({required this.ticketRepository}) : super(TicketInitialState()) {
    on<CreateTicketRequestedEvent>(_onCreateTicket);
    on<FetchTukangRadarTicketsEvent>(_onFetchTukangRadarTickets);
    on<SubmitBidRequestedEvent>(_onSubmitBid);
    on<LockTukangRequestedEvent>(_onLockTukang);
    on<UpdateTicketStatusRequestedEvent>(_onUpdateStatus);
    on<SubmitFinalBillRequestedEvent>(_onSubmitFinalBill);
    on<ApproveFinalBillRequestedEvent>(_onApproveFinalBill);
    on<UploadWorkPhotosRequestedEvent>(_onUploadWorkPhotos);
    on<FetchUserTicketsEvent>(_onFetchUserTickets);
    on<FetchTukangActiveTicketsEvent>(_onFetchTukangActiveTickets);
  }

  Future<void> _onCreateTicket(CreateTicketRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final ticket = await ticketRepository.createTicket(
        userId: event.userId,
        userName: event.userName,
        category: event.category,
        title: event.title,
        description: event.description,
        photoUrls: event.photoUrls,
        address: event.address,
        lat: event.lat,
        lng: event.lng,
      );
      emit(TicketCreatedSuccessState(ticket));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal membuat tiket: ${e.toString()}'));
    }
  }

  Future<void> _onFetchTukangRadarTickets(FetchTukangRadarTicketsEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final list = await ticketRepository.getOpenTicketsForTukang(
        tukangServices: event.services,
        tukangLat: event.lat,
        tukangLng: event.lng,
      );
      emit(TicketListLoadedState(list));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal memuat radar tiket: ${e.toString()}'));
    }
  }

  Future<void> _onSubmitBid(SubmitBidRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final updated = await ticketRepository.submitBid(
        ticketId: event.ticketId,
        tukangId: event.tukangId,
        tukangName: event.tukangName,
        tukangPhoto: event.tukangPhoto,
        tukangRating: event.tukangRating,
        estimatedPrice: event.estimatedPrice,
        note: event.note,
      );
      emit(BidSubmittedSuccessState(updated));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal mengajukan penawaran: ${e.toString()}'));
    }
  }

  Future<void> _onLockTukang(LockTukangRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final locked = await ticketRepository.lockTukang(
        ticketId: event.ticketId,
        selectedTukangId: event.selectedTukangId,
        selectedTukangName: event.selectedTukangName,
      );
      emit(TukangLockedSuccessState(locked));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal mengunci tukang: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStatus(UpdateTicketStatusRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final updated = await ticketRepository.updateTicketStatus(
        ticketId: event.ticketId,
        newStatus: event.newStatus,
        cancelReason: event.cancelReason,
      );
      emit(TukangLockedSuccessState(updated));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal memperbarui status: ${e.toString()}'));
    }
  }

  Future<void> _onSubmitFinalBill(SubmitFinalBillRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final updated = await ticketRepository.submitFinalBill(
        ticketId: event.ticketId,
        items: event.items,
      );
      emit(TukangLockedSuccessState(updated));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal menginput rincian tagihan: ${e.toString()}'));
    }
  }

  Future<void> _onApproveFinalBill(ApproveFinalBillRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final updated = await ticketRepository.approveFinalBill(ticketId: event.ticketId);
      emit(TukangLockedSuccessState(updated));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal menyetujui rincian tagihan: ${e.toString()}'));
    }
  }

  Future<void> _onUploadWorkPhotos(UploadWorkPhotosRequestedEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final updated = await ticketRepository.uploadWorkPhotos(
        ticketId: event.ticketId,
        isBefore: event.isBefore,
        photoPaths: event.photoPaths,
      );
      emit(TukangLockedSuccessState(updated));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal mengunggah foto pengerjaan: ${e.toString()}'));
    }
  }

  Future<void> _onFetchUserTickets(FetchUserTicketsEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final list = await ticketRepository.getUserTickets(event.userId);
      emit(TicketListLoadedState(list));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal memuat tiket user: ${e.toString()}'));
    }
  }

  Future<void> _onFetchTukangActiveTickets(FetchTukangActiveTicketsEvent event, Emitter<TicketState> emit) async {
    emit(TicketLoadingState());
    try {
      final list = await ticketRepository.getTukangTickets(event.tukangId);
      emit(TicketListLoadedState(list));
    } catch (e) {
      emit(TicketOperationFailureState('Gagal memuat tiket aktif tukang: ${e.toString()}'));
    }
  }
}
