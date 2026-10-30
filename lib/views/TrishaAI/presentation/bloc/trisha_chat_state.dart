import 'package:equatable/equatable.dart';

import '../../data/model/trisha_models.dart';

/// Which screen the chat is on.
enum TrishaChatMode { chooser, ai, expert }

/// Which chooser card is currently loading (null = none).
enum TrishaChooserAction { tisha, expert, continuePrevious, startNew }

class TrishaChatState extends Equatable {
  final TrishaChatMode mode;
  final String? sessionId;

  /// Trisha's opening line from /v1/chat/start. Shown on the welcome screen,
  /// not as a bubble.
  final String? greeting;
  final List<TrishaMessage> messages;
  final bool starting;
  final bool waiting;
  final String? error;

  // Expert-mode fields
  final TrishaExpertTicket? ticket;
  final bool expertConnected;
  final TrishaExpertChat? previousExpertChat;

  /// Which chooser card triggered the current loading state.
  final TrishaChooserAction? busyCard;

  /// True when expert was requested but user is not logged in.
  final bool needsLoginForExpert;

  const TrishaChatState({
    this.mode = TrishaChatMode.chooser,
    this.sessionId,
    this.greeting,
    this.messages = const [],
    this.starting = false,
    this.waiting = false,
    this.error,
    this.ticket,
    this.expertConnected = false,
    this.previousExpertChat,
    this.busyCard,
    this.needsLoginForExpert = false,
  });

  bool get isChooser => mode == TrishaChatMode.chooser;
  bool get isExpert => mode == TrishaChatMode.expert;

  /// True until the user has said something: the welcome layout (AI 1 / AI 2).
  bool get isWelcome => mode == TrishaChatMode.ai && !messages.any((m) => m.fromUser);

  /// Quick replies belong to Trisha's latest reply only.
  String? get latestTrishaId {
    for (final m in messages.reversed) {
      if (!m.fromUser) return m.id;
    }
    return null;
  }

  TrishaChatState copyWith({
    TrishaChatMode? mode,
    String? sessionId,
    String? greeting,
    List<TrishaMessage>? messages,
    bool? starting,
    bool? waiting,
    String? Function()? error,
    TrishaExpertTicket? Function()? ticket,
    bool? expertConnected,
    TrishaExpertChat? Function()? previousExpertChat,
    TrishaChooserAction? Function()? busyCard,
    bool? needsLoginForExpert,
  }) =>
      TrishaChatState(
        mode: mode ?? this.mode,
        sessionId: sessionId ?? this.sessionId,
        greeting: greeting ?? this.greeting,
        messages: messages ?? this.messages,
        starting: starting ?? this.starting,
        waiting: waiting ?? this.waiting,
        error: error != null ? error() : this.error,
        ticket: ticket != null ? ticket() : this.ticket,
        expertConnected: expertConnected ?? this.expertConnected,
        previousExpertChat: previousExpertChat != null ? previousExpertChat() : this.previousExpertChat,
        busyCard: busyCard != null ? busyCard() : this.busyCard,
        needsLoginForExpert: needsLoginForExpert ?? this.needsLoginForExpert,
      );

  @override
  List<Object?> get props => [mode, sessionId, greeting, messages, starting, waiting, error, ticket, expertConnected, previousExpertChat, busyCard, needsLoginForExpert];
}
