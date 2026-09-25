import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription? _chatSubscription;
  List<ChatMessageModel> _currentMessages = [];

  ChatBloc({required this.chatRepository}) : super(ChatInitialState()) {
    on<StartChatStreamEvent>(_onStartChatStream);
    on<ChatMessagesReceivedEvent>(_onMessagesReceived);
    on<ChatStreamErrorEvent>(_onStreamError);
    on<SendChatMessageRequestedEvent>(_onSendMessage);
    on<RetrySendMessageEvent>(_onRetrySendMessage);
  }

  Future<void> _onStartChatStream(StartChatStreamEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoadingState());
    _currentMessages = [];
    await _chatSubscription?.cancel();
    _chatSubscription = chatRepository.getChatMessagesStream(event.ticketId).listen(
      (messages) {
        add(ChatMessagesReceivedEvent(messages));
      },
      onError: (e) {
        add(ChatStreamErrorEvent(e.toString()));
      },
    );
  }

  void _onStreamError(ChatStreamErrorEvent event, Emitter<ChatState> emit) {
    emit(ChatFailureState('Gagal menyinkronkan pesan chat: ${event.errorMessage}'));
  }

  void _onMessagesReceived(ChatMessagesReceivedEvent event, Emitter<ChatState> emit) {
    // Preserve any local unsent / failed messages that are not yet in Firestore
    final serverIds = event.messages.map((m) => m.id).toSet();
    final pendingLocal = _currentMessages.where((m) => !serverIds.contains(m.id) && m.deliveryStatus != 'sent').toList();

    _currentMessages = [...event.messages, ...pendingLocal];
    _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    emit(ChatLoadedState(List.from(_currentMessages)));
  }

  Future<void> _onSendMessage(SendChatMessageRequestedEvent event, Emitter<ChatState> emit) async {
    final tempId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final pendingMessage = ChatMessageModel(
      id: tempId,
      senderId: event.senderId,
      senderRole: event.senderRole,
      text: event.text,
      imageUrl: event.imagePath,
      timestamp: DateTime.now(),
      deliveryStatus: 'sending',
    );

    _currentMessages.add(pendingMessage);
    emit(ChatLoadedState(List.from(_currentMessages)));

    try {
      final sentMessage = await chatRepository.sendChatMessage(
        ticketId: event.ticketId,
        senderId: event.senderId,
        senderRole: event.senderRole,
        text: event.text,
        imagePath: event.imagePath,
      );

      // Update local message to sent
      final idx = _currentMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _currentMessages[idx] = sentMessage.copyWith(deliveryStatus: 'sent');
        emit(ChatLoadedState(List.from(_currentMessages)));
      }
    } catch (e) {
      // Mark as failed, keep in list so user can see it failed and retry!
      final idx = _currentMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _currentMessages[idx] = _currentMessages[idx].copyWith(
          deliveryStatus: 'failed',
          localError: e.toString(),
        );
        emit(ChatLoadedState(List.from(_currentMessages)));
      }
    }
  }

  Future<void> _onRetrySendMessage(RetrySendMessageEvent event, Emitter<ChatState> emit) async {
    final failedMsg = event.failedMessage;
    final idx = _currentMessages.indexWhere((m) => m.id == failedMsg.id);
    if (idx != -1) {
      _currentMessages[idx] = failedMsg.copyWith(deliveryStatus: 'sending', clearLocalError: true);
      emit(ChatLoadedState(List.from(_currentMessages)));
    }

    try {
      final sentMessage = await chatRepository.sendChatMessage(
        ticketId: event.ticketId,
        senderId: failedMsg.senderId,
        senderRole: failedMsg.senderRole,
        text: failedMsg.text,
        imagePath: failedMsg.imageUrl,
      );

      final updatedIdx = _currentMessages.indexWhere((m) => m.id == failedMsg.id);
      if (updatedIdx != -1) {
        _currentMessages[updatedIdx] = sentMessage.copyWith(deliveryStatus: 'sent');
        emit(ChatLoadedState(List.from(_currentMessages)));
      }
    } catch (e) {
      final updatedIdx = _currentMessages.indexWhere((m) => m.id == failedMsg.id);
      if (updatedIdx != -1) {
        _currentMessages[updatedIdx] = _currentMessages[updatedIdx].copyWith(
          deliveryStatus: 'failed',
          localError: e.toString(),
        );
        emit(ChatLoadedState(List.from(_currentMessages)));
      }
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
