import 'package:flutter_test/flutter_test.dart';
import 'package:beresapp/data/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel Delivery Status Tests', () {
    test('Default delivery status is sent when parsed from Firestore map', () {
      final map = {
        'id': 'msg_100',
        'senderId': 'USR-001',
        'senderRole': 'user',
        'text': 'Halo',
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = ChatMessageModel.fromMap(map, 'msg_100');
      expect(msg.deliveryStatus, 'sent');
      expect(msg.localError, isNull);
    });

    test('Explicit delivery status preserved and copied correctly', () {
      final msg = ChatMessageModel(
        id: 'msg_temp',
        senderId: 'USR-001',
        senderRole: 'user',
        text: 'Sedang dikirim...',
        timestamp: DateTime.now(),
        deliveryStatus: 'sending',
      );
      expect(msg.deliveryStatus, 'sending');

      final failedMsg = msg.copyWith(
        deliveryStatus: 'failed',
        localError: 'Izin Firestore ditolak',
      );
      expect(failedMsg.deliveryStatus, 'failed');
      expect(failedMsg.localError, 'Izin Firestore ditolak');

      final sentMsg = failedMsg.copyWith(
        deliveryStatus: 'sent',
        clearLocalError: true,
      );
      expect(sentMsg.deliveryStatus, 'sent');
      expect(sentMsg.localError, isNull);
    });

    test('Serialization toMap includes deliveryStatus', () {
      final msg = ChatMessageModel(
        id: 'msg_200',
        senderId: 'TKG-001',
        senderRole: 'tukang',
        text: 'Saya sudah di lokasi',
        timestamp: DateTime.now(),
        deliveryStatus: 'sent',
      );
      final map = msg.toMap();
      expect(map['deliveryStatus'], 'sent');
      expect(map['senderId'], 'TKG-001');
    });
  });
}
