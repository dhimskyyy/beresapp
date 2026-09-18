import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitialState extends ChatState {}

class ChatLoadingState extends ChatState {}

class ChatLoadedState extends ChatState {
  final List<ChatMessageModel> messages;
  const ChatLoadedState(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ChatFailureState extends ChatState {
  final String message;
  const ChatFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
