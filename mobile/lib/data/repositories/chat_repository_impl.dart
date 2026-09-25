import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const bool _demoMode = bool.fromEnvironment('BERES_DEMO_MODE', defaultValue: false);

  static final Map<String, List<ChatMessageModel>> _mockChatsByTicket = {
    'TCK-801': [
      ChatMessageModel(
        id: 'msg_1',
        senderId: 'USR-001',
        senderRole: 'user',
        text: 'Halo Pak Ahmad, untuk lokasi rumah di dalam komplek Wijaya blok B4 ya.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        deliveryStatus: 'sent',
      ),
      ChatMessageModel(
        id: 'msg_2',
        senderId: 'TKG-001',
        senderRole: 'tukang',
        text: 'Siap Bu Siti, ini saya sudah di jalan dekat patokan Indomaret.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        deliveryStatus: 'sent',
      ),
      ChatMessageModel(
        id: 'msg_3',
        senderId: 'TKG-001',
        senderRole: 'tukang',
        imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600',
        text: 'Foto selang AC yang menetes sudah saya dokumentasikan.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        deliveryStatus: 'sent',
      ),
    ],
  };

  static final Map<String, StreamController<List<ChatMessageModel>>> _controllers = {};
  static final Map<String, StreamSubscription<QuerySnapshot>?> _subscriptions = {};

  StreamController<List<ChatMessageModel>> _getController(String ticketId) {
    if (!_controllers.containsKey(ticketId) || _controllers[ticketId]!.isClosed) {
      _controllers[ticketId] = StreamController<List<ChatMessageModel>>.broadcast();
    }
    return _controllers[ticketId]!;
  }

  @override
  Stream<List<ChatMessageModel>> getChatMessagesStream(String ticketId) {
    final controller = _getController(ticketId);

    if (_demoMode) {
      final initialList = _mockChatsByTicket[ticketId] ?? [];
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!controller.isClosed) {
          controller.add(List.from(initialList));
        }
      });
      return controller.stream;
    }

    // Production: Listen to Cloud Firestore real-time sub-collection: tickets/{ticketId}/chats
    _subscriptions[ticketId]?.cancel();
    try {
      _subscriptions[ticketId] = _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('chats')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
        (snapshot) {
          if (!controller.isClosed) {
            final messages = snapshot.docs
                .map((doc) => ChatMessageModel.fromMap(
                      doc.data(),
                      doc.id,
                    ))
                .toList();
            controller.add(messages);
          }
        },
        onError: (err) {
          if (!controller.isClosed) {
            controller.addError(err);
          }
        },
      );
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }

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
      deliveryStatus: 'sent',
    );

    if (_demoMode) {
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

    // Production: Persist to Cloud Firestore and re-throw if it fails!
    // Never treat failure as local success.
    await _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('chats')
        .doc(message.id)
        .set(message.toMap());

    return message;
  }
}
