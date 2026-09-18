import '../../data/models/chat_message_model.dart';

abstract class ChatRepository {
  Stream<List<ChatMessageModel>> getChatMessagesStream(String ticketId);
  
  Future<ChatMessageModel> sendChatMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    String? text,
    String? imagePath,
  });
}
