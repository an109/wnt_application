import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/data_source/trisha_api_service.dart';
import '../../data/model/trisha_models.dart';
import 'trisha_chat_event.dart';
import 'trisha_chat_state.dart';

class TrishaChatBloc extends Bloc<TrishaChatEvent, TrishaChatState> {
  final TrishaApiService api;
  int _seq = 0;
  Future<TrishaReply> Function(String sessionId)? _failedCall;

  TrishaChatBloc({required this.api}) : super(const TrishaChatState()) {
    on<TrishaChatStarted>(_onStarted);
    on<TrishaMessageSent>(_onMessage);
    on<TrishaActionSent>(_onAction);
    on<TrishaRetried>(_onRetried);
    on<TrishaFeedbackGiven>(_onFeedback);
    on<TrishaMessageSaved>(_onSaved);
    on<TrishaChatOpened>(_onOpened);
  }

  Future<void> _onOpened(TrishaChatOpened event, Emitter<TrishaChatState> emit) async {
    _failedCall = null;
    emit(const TrishaChatState(starting: true));
    try {
      final chat = await api.getChat(event.sessionId);
      emit(TrishaChatState(
        sessionId: chat.sessionId,
        messages: [
          for (final m in chat.messages)
            TrishaMessage(
              id: _nextId(),
              fromUser: m.fromUser,
              text: m.text,
              cards: m.cards,
              quickReplies: m.quickReplies,
            ),
        ],
      ));
    } on TrishaException catch (e) {
      emit(state.copyWith(starting: false, error: () => e.message));
    }
  }

  String _nextId() => 'm${_seq++}';

  Future<void> _onStarted(TrishaChatStarted event, Emitter<TrishaChatState> emit) async {
    emit(const TrishaChatState(starting: true));
    try {
      final reply = await api.startChat();
      // The user may already have typed (their message opens a session of its
      // own); keep their conversation and only fill in what's missing.
      emit(state.copyWith(sessionId: state.sessionId ?? reply.sessionId, greeting: reply.text, starting: false));
    } on TrishaException catch (e) {
      emit(state.copyWith(starting: false, error: () => e.message));
    }
  }

  Future<void> _onMessage(TrishaMessageSent event, Emitter<TrishaChatState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty || state.waiting) return;
    await _exchange(
      emit,
      userText: text,
      call: (sessionId) => api.sendMessage(sessionId: sessionId, text: text),
    );
  }

  Future<void> _onAction(TrishaActionSent event, Emitter<TrishaChatState> emit) async {
    if (state.waiting) return;
    await _exchange(
      emit,
      userText: event.label,
      call: (sessionId) => api.sendAction(sessionId: sessionId, type: event.type, data: event.data, label: event.label),
    );
  }

  Future<void> _onRetried(TrishaRetried event, Emitter<TrishaChatState> emit) async {
    final call = _failedCall;
    if (call == null || state.waiting) return;
    await _exchange(emit, userText: null, call: call);
  }

  Future<void> _exchange(
    Emitter<TrishaChatState> emit, {
    required String? userText,
    required Future<TrishaReply> Function(String sessionId) call,
  }) async {
    var sessionId = state.sessionId;
    final messages = [...state.messages];
    if (userText != null) {
      messages.add(TrishaMessage(id: _nextId(), fromUser: true, text: userText));
    }
    emit(state.copyWith(messages: messages, waiting: true, error: () => null));

    try {
      if (sessionId == null) {
        // The opening call failed earlier; open a session now.
        final start = await api.startChat();
        sessionId = start.sessionId;
      }
      final reply = await call(sessionId);
      emit(state.copyWith(
        sessionId: reply.sessionId,
        waiting: false,
        messages: [
          ...state.messages,
          TrishaMessage(
            id: _nextId(),
            fromUser: false,
            text: reply.text,
            cards: reply.cards,
            quickReplies: reply.quickReplies,
          ),
        ],
      ));
      _failedCall = null;
    } on TrishaException catch (e) {
      _failedCall = call;
      emit(state.copyWith(waiting: false, error: () => e.message));
    }
  }

  void _onFeedback(TrishaFeedbackGiven event, Emitter<TrishaChatState> emit) {
    emit(state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == event.messageId)
            m.copyWith(liked: () => m.liked == event.liked ? null : event.liked)
          else
            m,
      ],
    ));
  }

  void _onSaved(TrishaMessageSaved event, Emitter<TrishaChatState> emit) {
    emit(state.copyWith(
      messages: [
        for (final m in state.messages) m.id == event.messageId ? m.copyWith(saved: !m.saved) : m,
      ],
    ));
  }
}
