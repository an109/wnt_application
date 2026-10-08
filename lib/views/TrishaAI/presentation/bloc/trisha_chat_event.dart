import 'package:equatable/equatable.dart';

abstract class TrishaChatEvent extends Equatable {
  const TrishaChatEvent();

  @override
  List<Object?> get props => [];
}

/// Opens a new chat session (Trisha greets first).
class TrishaChatStarted extends TrishaChatEvent {
  const TrishaChatStarted();
}

/// Typed text or a tapped quick reply.
class TrishaMessageSent extends TrishaChatEvent {
  final String text;

  const TrishaMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// A card or button tap. [label], when given, is shown as the user's bubble
/// (e.g. "Option 2"); payment results and refreshes have none.
class TrishaActionSent extends TrishaChatEvent {
  final String type;
  final Map<String, dynamic> data;
  final String? label;

  const TrishaActionSent(this.type, {this.data = const {}, this.label});

  @override
  List<Object?> get props => [type, data, label];
}

/// Repeats the last call that failed (network / server error).
class TrishaRetried extends TrishaChatEvent {
  const TrishaRetried();
}

class TrishaFeedbackGiven extends TrishaChatEvent {
  final String messageId;
  final bool liked;

  const TrishaFeedbackGiven(this.messageId, {required this.liked});

  @override
  List<Object?> get props => [messageId, liked];
}

class TrishaMessageSaved extends TrishaChatEvent {
  final String messageId;

  const TrishaMessageSaved(this.messageId);

  @override
  List<Object?> get props => [messageId];
}


/// Reopens a past chat from the history: its messages are shown and new
/// messages continue the same chat.
class TrishaChatOpened extends TrishaChatEvent {
  final String sessionId;

  const TrishaChatOpened(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
