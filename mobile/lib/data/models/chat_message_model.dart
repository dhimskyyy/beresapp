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
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? 'user',
      text: map['text'],
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
