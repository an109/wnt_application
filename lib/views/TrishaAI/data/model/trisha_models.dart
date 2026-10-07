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
