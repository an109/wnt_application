/// Response shapes of the Trisha AI chat service (`/v1/chat/start`, `/v1/chat`).
/// See trisha-ai/README.md for every card type and its fields.
class TrishaCard {
  final String type;
  final Map<String, dynamic> data;

  const TrishaCard({required this.type, required this.data});

  factory TrishaCard.fromJson(Map<String, dynamic> json) => TrishaCard(
        type: json['type']?.toString() ?? '',
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class TrishaReply {
  final String sessionId;
  final String text;
  final List<TrishaCard> cards;
  final List<String> quickReplies;

  const TrishaReply({
    required this.sessionId,
    required this.text,
    this.cards = const [],
    this.quickReplies = const [],
  });

  factory TrishaReply.fromJson(Map<String, dynamic> json) => TrishaReply(
        sessionId: json['session_id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        cards: (json['cards'] as List? ?? const [])
            .whereType<Map>()
            .map((c) => TrishaCard.fromJson(c.cast<String, dynamic>()))
            .toList(),
        quickReplies: (json['quick_replies'] as List? ?? const []).map((q) => q.toString()).toList(),
      );
}

/// One bubble in the chat: either the user's text or a Trisha reply.
class TrishaMessage {
  final String id;
  final bool fromUser;
  final String text;
  final List<TrishaCard> cards;
  final List<String> quickReplies;

  /// Local thumbs feedback: true = liked, false = disliked, null = none.
  final bool? liked;
  final bool saved;

  const TrishaMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.cards = const [],
    this.quickReplies = const [],
    this.liked,
    this.saved = false,
  });

  TrishaMessage copyWith({bool? Function()? liked, bool? saved}) => TrishaMessage(
        id: id,
        fromUser: fromUser,
        text: text,
        cards: cards,
        quickReplies: quickReplies,
        liked: liked != null ? liked() : this.liked,
        saved: saved ?? this.saved,
      );
}


/// The active expert chat returned by `GET /v1/chat/active`.
class TrishaExpertChat {
  final bool active;
  final String? ticketNumber;
  final String? chatUrl;
  final List<TrishaExpertMessage> messages;

  const TrishaExpertChat({
    required this.active,
    this.ticketNumber,
    this.chatUrl,
    this.messages = const [],
  });

  factory TrishaExpertChat.fromJson(Map<String, dynamic> json) => TrishaExpertChat(
        active: json['active'] == true,
        ticketNumber: json['ticket_number']?.toString(),
        chatUrl: json['chat_url']?.toString(),
        messages: (json['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => TrishaExpertMessage.fromJson(m.cast<String, dynamic>()))
            .toList(),
      );
}

class TrishaExpertMessage {
  final String role; // 'user', 'assistant', 'system'
  final String? author;
  final String text;
  final List<TrishaCard> cards;

  const TrishaExpertMessage({
    required this.role,
    this.author,
    required this.text,
    this.cards = const [],
  });

  factory TrishaExpertMessage.fromJson(Map<String, dynamic> json) => TrishaExpertMessage(
        role: json['role']?.toString() ?? 'assistant',
        author: json['author']?.toString(),
        text: json['text']?.toString() ?? '',
        cards: (json['cards'] as List? ?? const [])
            .whereType<Map>()
            .map((c) => TrishaCard.fromJson(c.cast<String, dynamic>()))
            .toList(),
      );
}

/// Ticket returned by `POST /v1/chat/handoff`.
class TrishaExpertTicket {
  final String ticketNumber;
  final String chatUrl;

  const TrishaExpertTicket({required this.ticketNumber, required this.chatUrl});

  factory TrishaExpertTicket.fromJson(Map<String, dynamic> json) => TrishaExpertTicket(
        ticketNumber: json['ticket_number']?.toString() ?? '',
        chatUrl: json['chat_url']?.toString() ?? '',
      );
}

/// One row of the chat history list (`GET /v1/chats`).
class TrishaChatSummary {
  final String sessionId;
  final String title;

  /// flight / hotel / holiday / transfer / insurance, or null for general chat.
  final String? flow;
  final String lastMessage;
  final DateTime updatedAt;

  const TrishaChatSummary({
    required this.sessionId,
    required this.title,
    required this.flow,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory TrishaChatSummary.fromJson(Map<String, dynamic> json) => TrishaChatSummary(
        sessionId: json['session_id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Chat',
        flow: json['flow']?.toString(),
        lastMessage: json['last_message']?.toString() ?? '',
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );
}

/// A past chat reopened from the history (`GET /v1/chats/{id}`).
class TrishaChatHistory {
  final String sessionId;
  final List<({bool fromUser, String text, List<TrishaCard> cards, List<String> quickReplies})> messages;

  const TrishaChatHistory({required this.sessionId, required this.messages});

  factory TrishaChatHistory.fromJson(Map<String, dynamic> json) => TrishaChatHistory(
        sessionId: json['session_id']?.toString() ?? '',
        messages: [
          for (final m in (json['messages'] as List? ?? const []).whereType<Map>())
            (
              fromUser: m['role'] == 'user',
              text: m['text']?.toString() ?? '',
              cards: (m['cards'] as List? ?? const [])
                  .whereType<Map>()
                  .map((c) => TrishaCard.fromJson(c.cast<String, dynamic>()))
                  .toList(),
              quickReplies: (m['quick_replies'] as List? ?? const []).map((q) => q.toString()).toList(),
            ),
        ],
      );
}
