class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'user' or 'tukang'
  final String? text;
  final String? imageUrl;
  final bool isRead;
  final DateTime timestamp;
  final String deliveryStatus; // 'sending', 'sent', 'failed'
  final String? localError;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    this.text,
    this.imageUrl,
    this.isRead = false,
    required this.timestamp,
    this.deliveryStatus = 'sent',
    this.localError,
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
      deliveryStatus: map['deliveryStatus'] ?? 'sent',
      localError: map['localError'],
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
      'deliveryStatus': deliveryStatus,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderRole,
    String? text,
    String? imageUrl,
    bool? isRead,
    DateTime? timestamp,
    String? deliveryStatus,
    String? localError,
    bool clearLocalError = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      localError: clearLocalError ? null : (localError ?? this.localError),
    );
  }
}
