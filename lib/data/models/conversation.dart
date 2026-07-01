/// A chat conversation, mirroring `public.conversations`.
class Conversation {
  const Conversation({
    required this.id,
    required this.peerName,
    required this.peerPhoto,
    this.lastPreview,
    this.timeLabel,
    this.unread = 0,
  });

  final String id;
  final String peerName;
  final String peerPhoto;
  final String? lastPreview;
  final String? timeLabel;
  final int unread;

  factory Conversation.fromMap(Map<String, dynamic> m) {
    return Conversation(
      id: m['id'] as String,
      peerName: (m['peer_name'] as String?) ?? 'Chat',
      peerPhoto:
          (m['peer_photo'] as String?) ?? 'assets/images/profile_pic.png',
      lastPreview: m['last_preview'] as String?,
      timeLabel: m['time_label'] as String?,
      unread: (m['unread'] as int?) ?? 0,
    );
  }
}

/// One message inside a conversation, mirroring `public.messages`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromMe,
    required this.body,
    this.timeLabel,
  });

  final String id;
  final bool fromMe;
  final String body;
  final String? timeLabel;

  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    return ChatMessage(
      id: m['id'] as String,
      fromMe: m['from_me'] == true,
      body: (m['body'] as String?) ?? '',
      timeLabel: m['time_label'] as String?,
    );
  }
}
