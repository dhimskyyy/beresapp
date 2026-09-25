import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class StartChatStreamEvent extends ChatEvent {
  final String ticketId;
  const StartChatStreamEvent(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class ChatMessagesReceivedEvent extends ChatEvent {
  final List<ChatMessageModel> messages;
  const ChatMessagesReceivedEvent(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ChatStreamErrorEvent extends ChatEvent {
  final String errorMessage;
  const ChatStreamErrorEvent(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class SendChatMessageRequestedEvent extends ChatEvent {
  final String ticketId;
  final String senderId;
  final String senderRole;
  final String? text;
  final String? imagePath;

  const SendChatMessageRequestedEvent({
    required this.ticketId,
    required this.senderId,
    required this.senderRole,
    this.text,
    this.imagePath,
  });

  @override
  List<Object?> get props => [ticketId, senderId, senderRole, text, imagePath];
}

class RetrySendMessageEvent extends ChatEvent {
  final String ticketId;
  final ChatMessageModel failedMessage;

  const RetrySendMessageEvent({
    required this.ticketId,
    required this.failedMessage,
  });

  @override
  List<Object?> get props => [ticketId, failedMessage];
}
