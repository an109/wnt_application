import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../UI_helper/auth_guard.dart';
import '../../data/data_source/trisha_api_service.dart';
import '../../data/model/trisha_models.dart';
import 'trisha_chat_event.dart';
import 'trisha_chat_state.dart';

class TrishaChatBloc extends Bloc<TrishaChatEvent, TrishaChatState> {
  final TrishaApiService api;
  int _seq = 0;
  Future<TrishaReply> Function(String sessionId)? _failedCall;

  WebSocketChannel? _socket;
  StreamSubscription? _socketSub;

  TrishaChatBloc({required this.api}) : super(const TrishaChatState()) {
    on<TrishaChatStarted>(_onStarted);
    on<TrishaMessageSent>(_onMessage);
    on<TrishaActionSent>(_onAction);
    on<TrishaRetried>(_onRetried);
    on<TrishaFeedbackGiven>(_onFeedback);
    on<TrishaMessageSaved>(_onSaved);
    on<TrishaChatOpened>(_onOpened);
    // Expert / chooser events
    on<TrishaAiModeChosen>(_onAiModeChosen);
    on<TrishaExpertRequested>(_onExpertRequested);
    on<TrishaExpertContinued>(_onExpertContinued);
    on<TrishaExpertMessageSent>(_onExpertMessage);
    on<TrishaExpertMessageReceived>(_onExpertReceived);
    on<TrishaExpertConnectionChanged>(_onExpertConnection);
    on<TrishaExpertChatClosed>(_onExpertClosed);
    on<TrishaExpertLoginCancelled>(_onExpertLoginCancelled);
    on<TrishaNewChatFromChooser>(_onNewChatFromChooser);

    // Check for a previous expert chat on creation
    _checkPreviousExpert();
  }

  @override
  Future<void> close() {
    _closeSocket();
    return super.close();
  }

  String _nextId() => 'm${_seq++}';

  // ---- Check for previous expert chat on init --------------------------------

  Future<void> _checkPreviousExpert() async {
    try {
      final chat = await api.getActiveExpertChat();
      if (chat.active && !isClosed) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(state.copyWith(previousExpertChat: () => chat));
      }
    } catch (_) {
      // Not critical; just show normal chooser
    }
  }

  // ---- Chooser events ---------------------------------------------------------

  Future<void> _onAiModeChosen(TrishaAiModeChosen event, Emitter<TrishaChatState> emit) async {
    emit(state.copyWith(mode: TrishaChatMode.ai, starting: true, busyCard: () => TrishaChooserAction.tisha));
    try {
      final reply = await api.startChat();
      emit(state.copyWith(sessionId: reply.sessionId, greeting: reply.text, starting: false, busyCard: () => null));
    } on TrishaException catch (e) {
      emit(state.copyWith(starting: false, error: () => e.message, busyCard: () => null));
    }
  }

  void _onExpertLoginCancelled(TrishaExpertLoginCancelled event, Emitter<TrishaChatState> emit) {
    emit(state.copyWith(needsLoginForExpert: false, busyCard: () => null));
  }

  Future<void> _onNewChatFromChooser(TrishaNewChatFromChooser event, Emitter<TrishaChatState> emit) async {
    emit(state.copyWith(busyCard: () => TrishaChooserAction.startNew));
    if (state.previousExpertChat?.active == true) {
      try {
        await api.closeActiveExpertChat();
      } catch (_) {}
    }
    _closeSocket();
    emit(TrishaChatState(mode: TrishaChatMode.ai, starting: true, busyCard: TrishaChooserAction.startNew));
    try {
      final reply = await api.startChat();
      emit(state.copyWith(sessionId: reply.sessionId, greeting: reply.text, starting: false, busyCard: () => null));
    } on TrishaException catch (e) {
      emit(state.copyWith(starting: false, error: () => e.message, busyCard: () => null));
    }
  }

  // ---- Expert events ----------------------------------------------------------

  Future<void> _onExpertRequested(TrishaExpertRequested event, Emitter<TrishaChatState> emit) async {
    if (!isUserLoggedIn() && !event.fromLoginReturn) {
      emit(state.copyWith(needsLoginForExpert: true, busyCard: () => TrishaChooserAction.expert));
      return;
    }
    emit(state.copyWith(waiting: true, error: () => null, needsLoginForExpert: false, busyCard: () => TrishaChooserAction.expert));
    try {
      var sessionId = state.sessionId;
      if (sessionId == null) {
        final start = await api.startChat();
        sessionId = start.sessionId;
      }
      final ticket = await api.requestExpert(sessionId);
      emit(state.copyWith(
        mode: TrishaChatMode.expert,
        sessionId: sessionId,
        waiting: false,
        ticket: () => ticket,
        busyCard: () => null,
      ));
      _connectSocket(ticket.chatUrl);
    } on TrishaException catch (e) {
      emit(state.copyWith(waiting: false, error: () => e.message, busyCard: () => null));
    }
  }

  Future<void> _onExpertContinued(TrishaExpertContinued event, Emitter<TrishaChatState> emit) async {
    emit(state.copyWith(waiting: true, error: () => null, busyCard: () => TrishaChooserAction.continuePrevious));
    try {
      final chat = await api.getActiveExpertChat();
      if (!chat.active) {
        emit(state.copyWith(
          waiting: false,
          previousExpertChat: () => null,
          error: () => 'That conversation has been closed. You can start a new chat.',
        ));
        return;
      }
      final messages = chat.messages.map((m) => TrishaMessage(
            id: _nextId(),
            fromUser: m.role == 'user',
            text: m.text,
            cards: m.cards,
          )).toList();
      final ticket = TrishaExpertTicket(
        ticketNumber: chat.ticketNumber ?? '',
        chatUrl: chat.chatUrl ?? '',
      );
      emit(state.copyWith(
        mode: TrishaChatMode.expert,
        waiting: false,
        messages: messages,
        ticket: () => ticket,
      ));
      if (chat.chatUrl != null && chat.chatUrl!.isNotEmpty) {
        _connectSocket(chat.chatUrl!);
      }
    } on TrishaException catch (e) {
      emit(state.copyWith(waiting: false, error: () => e.message));
    }
  }

  void _onExpertMessage(TrishaExpertMessageSent event, Emitter<TrishaChatState> emit) {
    final text = event.text.trim();
    if (text.isEmpty) return;
    if (_socket == null) {
      emit(state.copyWith(error: () => 'Reconnecting… your message will go through in a moment.'));
      return;
    }
    _socket!.sink.add(jsonEncode({'text': text}));
    emit(state.copyWith(
      messages: [...state.messages, TrishaMessage(id: _nextId(), fromUser: true, text: text)],
    ));
  }

  void _onExpertReceived(TrishaExpertMessageReceived event, Emitter<TrishaChatState> emit) {
    emit(state.copyWith(
      messages: [
        ...state.messages,
        TrishaMessage(
          id: _nextId(),
          fromUser: false,
          text: event.text,
          cards: event.cards.map((c) => TrishaCard.fromJson(c)).toList(),
        ),
      ],
    ));
  }

  void _onExpertConnection(TrishaExpertConnectionChanged event, Emitter<TrishaChatState> emit) {
    emit(state.copyWith(expertConnected: event.connected));
  }

  void _onExpertClosed(TrishaExpertChatClosed event, Emitter<TrishaChatState> emit) {
    emit(state.copyWith(error: () => 'This chat has been closed. Thank you!'));
    _closeSocket();
  }

  // ---- WebSocket management ---------------------------------------------------

  void _connectSocket(String url) {
    _closeSocket();
    if (url.isEmpty) return;
    try {
      _socket = WebSocketChannel.connect(Uri.parse(url));
    } catch (_) {
      if (!isClosed) add(const TrishaExpertConnectionChanged(false));
      return;
    }
    _socketSub = _socket!.stream.listen(
      (raw) {
        if (isClosed) return;
        Map<String, dynamic> data;
        try {
          data = jsonDecode(raw as String) as Map<String, dynamic>;
        } catch (_) {
          return;
        }
        if (data['kind'] == 'message') {
          if (data['sender'] == 'customer') return; // echo
          add(TrishaExpertMessageReceived(
            role: data['sender'] == 'system' ? 'system' : 'assistant',
            author: data['sender'] == 'agent' ? data['author_name']?.toString() : null,
            text: data['text']?.toString() ?? '',
            cards: (data['cards'] as List? ?? const []).whereType<Map>().map((c) => c.cast<String, dynamic>()).toList(),
          ));
        } else if (data['kind'] == 'closed') {
          add(const TrishaExpertChatClosed());
        }
      },
      onDone: () {
        if (!isClosed) add(const TrishaExpertConnectionChanged(false));
      },
      onError: (_) {
        if (!isClosed) add(const TrishaExpertConnectionChanged(false));
      },
    );
    if (!isClosed) add(const TrishaExpertConnectionChanged(true));
  }

  void _closeSocket() {
    _socketSub?.cancel();
    _socketSub = null;
    try {
      _socket?.sink.close();
    } catch (_) {}
    _socket = null;
  }

  // ---- Original AI chat handlers (unchanged) ---------------------------------

  Future<void> _onOpened(TrishaChatOpened event, Emitter<TrishaChatState> emit) async {
    _failedCall = null;
    emit(const TrishaChatState(mode: TrishaChatMode.ai, starting: true));
    try {
      final chat = await api.getChat(event.sessionId);
      emit(TrishaChatState(
        mode: TrishaChatMode.ai,
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

  Future<void> _onStarted(TrishaChatStarted event, Emitter<TrishaChatState> emit) async {
    emit(const TrishaChatState(mode: TrishaChatMode.ai, starting: true));
    try {
      final reply = await api.startChat();
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
