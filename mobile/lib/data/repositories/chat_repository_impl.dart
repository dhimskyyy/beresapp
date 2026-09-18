import 'dart:async';
import '../../core/services/supabase_storage_service.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  static final Map<String, List<ChatMessageModel>> _mockChatsByTicket = {
    'TCK-801': [
      ChatMessageModel(
        id: 'msg_1',
        senderId: 'USR-001',
        senderRole: 'user',
        text: 'Halo Pak Ahmad, untuk lokasi rumah di dalam komplek Wijaya blok B4 ya.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      ChatMessageModel(
        id: 'msg_2',
        senderId: 'TKG-001',
        senderRole: 'tukang',
        text: 'Siap Bu Siti, ini saya sudah di jalan dekat patokan Indomaret.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessageModel(
        id: 'msg_3',
        senderId: 'TKG-001',
        senderRole: 'tukang',
        imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600',
        text: 'Foto selang AC yang menetes sudah saya dokumentasikan.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ],
  };

  static final Map<String, StreamController<List<ChatMessageModel>>> _controllers = {};

  StreamController<List<ChatMessageModel>> _getController(String ticketId) {
    if (!_controllers.containsKey(ticketId)) {
      _controllers[ticketId] = StreamController<List<ChatMessageModel>>.broadcast();
    }
    return _controllers[ticketId]!;
  }

  @override
  Stream<List<ChatMessageModel>> getChatMessagesStream(String ticketId) {
    final controller = _getController(ticketId);
    final initialList = _mockChatsByTicket[ticketId] ?? [];
    
    // Emit initial list after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!controller.isClosed) {
        controller.add(List.from(initialList));
      }
    });

    return controller.stream;
  }

  @override
  Future<ChatMessageModel> sendChatMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    String? text,
    String? imagePath,
  }) async {
    String? uploadedUrl;
    if (imagePath != null && imagePath.isNotEmpty) {
      uploadedUrl = await SupabaseStorageService.uploadImage(
        filePath: imagePath,
        folder: 'chat',
      );
    }

    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderRole: senderRole,
      text: text,
      imageUrl: uploadedUrl,
      timestamp: DateTime.now(),
    );

    if (!_mockChatsByTicket.containsKey(ticketId)) {
      _mockChatsByTicket[ticketId] = [];
    }
    _mockChatsByTicket[ticketId]!.add(message);

    final controller = _getController(ticketId);
    if (!controller.isClosed) {
      controller.add(List.from(_mockChatsByTicket[ticketId]!));
    }

    return message;
  }
}
