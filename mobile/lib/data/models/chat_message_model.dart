class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'user' or 'tukang'
  final String? text;
  final String? imageUrl;
  final bool isRead;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    this.text,
    this.imageUrl,
    this.isRead = false,
    required this.timestamp,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedTime = DateTime.now();
    final rawTime = map['timestamp'];
    if (rawTime != null) {
      if (rawTime is DateTime) {
        parsedTime = rawTime;
      } else {
        try {
          parsedTime = (rawTime as dynamic).toDate();
        } catch (_) {
          parsedTime = DateTime.tryParse(rawTime.toString()) ?? DateTime.now();
        }
      }
    }
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? 'user',
      text: map['text'],
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
