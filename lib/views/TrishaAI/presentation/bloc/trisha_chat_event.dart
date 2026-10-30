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


/// User chose "Chat with Tisha" from the chooser.
class TrishaAiModeChosen extends TrishaChatEvent {
  const TrishaAiModeChosen();
}

/// User chose "Chat with an Expert" from the chooser.
/// If [fromLoginReturn] is true, this is a retry after the user just logged in.
class TrishaExpertRequested extends TrishaChatEvent {
  final bool fromLoginReturn;
  const TrishaExpertRequested({this.fromLoginReturn = false});

  @override
  List<Object?> get props => [fromLoginReturn];
}

/// User chose to continue a previous expert conversation.
class TrishaExpertContinued extends TrishaChatEvent {
  const TrishaExpertContinued();
}

/// User typed a message in expert mode (sent over WebSocket).
class TrishaExpertMessageSent extends TrishaChatEvent {
  final String text;
  const TrishaExpertMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// An expert message arrived over the WebSocket.
class TrishaExpertMessageReceived extends TrishaChatEvent {
  final String role;
  final String? author;
  final String text;
  final List<Map<String, dynamic>> cards;

  const TrishaExpertMessageReceived({required this.role, this.author, required this.text, this.cards = const []});

  @override
  List<Object?> get props => [role, author, text, cards];
}

/// The expert WebSocket connected or disconnected.
class TrishaExpertConnectionChanged extends TrishaChatEvent {
  final bool connected;
  const TrishaExpertConnectionChanged(this.connected);

  @override
  List<Object?> get props => [connected];
}

/// The expert chat was closed (by the expert).
class TrishaExpertChatClosed extends TrishaChatEvent {
  const TrishaExpertChatClosed();
}

/// User cancelled the login prompt for expert chat.
class TrishaExpertLoginCancelled extends TrishaChatEvent {
  const TrishaExpertLoginCancelled();
}

/// User starts a new chat from the chooser (closes previous expert chat if any).
class TrishaNewChatFromChooser extends TrishaChatEvent {
  const TrishaNewChatFromChooser();
}

/// Reopens a past chat from the history: its messages are shown and new
/// messages continue the same chat.
class TrishaChatOpened extends TrishaChatEvent {
  final String sessionId;

  const TrishaChatOpened(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
