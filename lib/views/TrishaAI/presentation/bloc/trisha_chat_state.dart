import 'package:equatable/equatable.dart';

import '../../data/model/trisha_models.dart';

class TrishaChatState extends Equatable {
  final String? sessionId;

  /// Trisha's opening line from /v1/chat/start. Shown on the welcome screen,
  /// not as a bubble.
  final String? greeting;
  final List<TrishaMessage> messages;
  final bool starting;
  final bool waiting;
  final String? error;

  const TrishaChatState({
    this.sessionId,
    this.greeting,
    this.messages = const [],
    this.starting = false,
    this.waiting = false,
    this.error,
  });

  /// True until the user has said something: the welcome layout (AI 1 / AI 2).
  bool get isWelcome => !messages.any((m) => m.fromUser);

  /// Quick replies belong to Trisha's latest reply only.
  String? get latestTrishaId {
    for (final m in messages.reversed) {
      if (!m.fromUser) return m.id;
    }
    return null;
  }

  TrishaChatState copyWith({
    String? sessionId,
    String? greeting,
    List<TrishaMessage>? messages,
    bool? starting,
    bool? waiting,
    String? Function()? error,
  }) =>
      TrishaChatState(
        sessionId: sessionId ?? this.sessionId,
        greeting: greeting ?? this.greeting,
        messages: messages ?? this.messages,
        starting: starting ?? this.starting,
        waiting: waiting ?? this.waiting,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props => [sessionId, greeting, messages, starting, waiting, error];
}
