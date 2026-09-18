import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription? _chatSubscription;

  ChatBloc({required this.chatRepository}) : super(ChatInitialState()) {
    on<StartChatStreamEvent>(_onStartChatStream);
    on<ChatMessagesReceivedEvent>(_onMessagesReceived);
    on<SendChatMessageRequestedEvent>(_onSendMessage);
  }

  Future<void> _onStartChatStream(StartChatStreamEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoadingState());
    await _chatSubscription?.cancel();
    _chatSubscription = chatRepository.getChatMessagesStream(event.ticketId).listen(
      (messages) {
        add(ChatMessagesReceivedEvent(messages));
      },
      onError: (e) {
        add(ChatMessagesReceivedEvent(const []));
      },
    );
  }

  void _onMessagesReceived(ChatMessagesReceivedEvent event, Emitter<ChatState> emit) {
    emit(ChatLoadedState(event.messages));
  }

  Future<void> _onSendMessage(SendChatMessageRequestedEvent event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.sendChatMessage(
        ticketId: event.ticketId,
        senderId: event.senderId,
        senderRole: event.senderRole,
        text: event.text,
        imagePath: event.imagePath,
      );
    } catch (e) {
      emit(ChatFailureState('Gagal mengirim pesan: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
