import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../Dashboard/profile/screen/Profile_screen.dart';
import '../../../Dashboard/profile/screen/add_traveller_screen.dart';
import '../../data/data_source/trisha_api_service.dart';
import '../bloc/trisha_chat_bloc.dart';
import '../bloc/trisha_chat_event.dart';
import '../bloc/trisha_chat_state.dart';
import '../../../../UI_helper/auth_guard.dart';
import '../widgets/title.dart';
import '../widgets/trisha_cards.dart';
import '../widgets/trisha_chooser.dart';
import '../widgets/trisha_expert_banner.dart';
import '../widgets/trisha_input_bar.dart';
import '../widgets/trisha_messages.dart';
import '../widgets/trisha_style.dart';
import '../widgets/trisha_welcome.dart';
import 'trisha_history_screen.dart';

/// Trisha AI chat (Figma "AI 1", "AI 2", "AI 3"). Opened from the orb in the
/// home bottom bar.
class TrishaChatScreen extends StatelessWidget {
  final String? initialPrompt;
  const TrishaChatScreen({super.key, this.initialPrompt});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final bloc = TrishaChatBloc(api: sl<TrishaApiService>());
      final prompt = initialPrompt?.trim();
      if (prompt != null && prompt.isNotEmpty) {
        // If there's an initial prompt, go straight to AI mode
        bloc.add(const TrishaAiModeChosen());
        bloc.add(TrishaMessageSent(prompt));
      }
      return bloc;
    },
    child: const _TrishaChatView(),
  );
}

class _TrishaChatView extends StatefulWidget {
  const _TrishaChatView();

  @override
  State<_TrishaChatView> createState() => _TrishaChatViewState();
}

class _TrishaChatViewState extends State<_TrishaChatView> {
  final _scroll = ScrollController();
  late final Razorpay _razorpay;
  late final TrishaCardHandler _handler;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
    _handler = TrishaCardHandler(
      action: (type, {data, label}) => _bloc.add(TrishaActionSent(type, data: data ?? const {}, label: label)),
      addTraveller: _addTraveller,
      openProfile: _openProfile,
      pay: _pay,
      openFlights: () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _scroll.dispose();
    super.dispose();
  }

  TrishaChatBloc get _bloc => context.read<TrishaChatBloc>();

  String get _firstName {
    final name = sl<PreferencesManager>().getString('user_name')?.trim() ?? '';
    return name.isEmpty ? 'there' : name.split(RegExp(r'\s+')).first;
  }

  // ---- card handlers ----------------------------------------------------------

  Future<void> _addTraveller() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTravellerScreen()));
    if (mounted) _bloc.add(const TrishaActionSent('travellers_updated'));
  }

  Future<void> _openProfile({String? thenAction}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    if (mounted && thenAction != null) _bloc.add(TrishaActionSent(thenAction));
  }

  void _pay(Map<String, dynamic> checkout) {
    final prefill = (checkout['prefill'] as Map? ?? {}).cast<String, dynamic>();
    _razorpay.open({
      'key': checkout['key_id'],
      'order_id': checkout['order_id'],
      'amount': checkout['amount'],
      'currency': checkout['currency'] ?? 'INR',
      'name': 'Wander Nova',
      'description': checkout['description'] ?? 'Flight booking',
      'prefill': prefill,
      'theme': {'color': '#F97316'},
    });
  }

  void _onPaymentSuccess(PaymentSuccessResponse r) => _bloc.add(TrishaActionSent('payment_result', data: {
        'status': 'success',
        'razorpay_order_id': r.orderId,
        'razorpay_payment_id': r.paymentId,
        'razorpay_signature': r.signature,
      }));

  void _onPaymentError(PaymentFailureResponse r) => _bloc.add(TrishaActionSent('payment_result', data: {
        'status': r.code == Razorpay.PAYMENT_CANCELLED ? 'cancelled' : 'failed',
      }));

  /// Recent chats: reopen one, or start a new chat.
  Future<void> _openHistory() async {
    final current = _bloc.state.sessionId;
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => TrishaHistoryScreen(currentSessionId: current)),
    );
    if (!mounted || picked == null) return;
    if (picked.isEmpty) {
      _bloc.add(const TrishaChatStarted());
    } else if (picked != current) {
      _bloc.add(TrishaChatOpened(picked));
    }
  }

  Future<void> _handleExpertLogin() async {
    final loggedIn = await openLogin(context);
    if (!mounted) return;
    if (loggedIn) {
      _bloc.add(const TrishaExpertRequested(fromLoginReturn: true));
    } else {
      _bloc.add(const TrishaExpertLoginCancelled());
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---- UI ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrishaChatBloc, TrishaChatState>(
      listenWhen: (a, b) =>
          a.messages.length != b.messages.length ||
          a.waiting != b.waiting ||
          a.error != b.error ||
          (!a.needsLoginForExpert && b.needsLoginForExpert),
      listener: (context, state) {
        _scrollToEnd();
        if (state.needsLoginForExpert) {
          _handleExpertLogin();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // ---- Content (top bar + chooser/chat/welcome) ----
              Column(
                children: [
                  SafeArea(bottom: false, child: _topBar(state)),
                  Expanded(
                    child: state.isChooser
                        ? TrishaChooser(
                            name: _firstName,
                            busyCard: state.busyCard,
                            notice: state.error,
                            previousExpertChat: state.previousExpertChat,
                            onChatWithTisha: () => _bloc.add(const TrishaAiModeChosen()),
                            onChatWithExpert: () => _bloc.add(const TrishaExpertRequested()),
                            onContinuePrevious: () => _bloc.add(const TrishaExpertContinued()),
                            onStartNew: () => _bloc.add(const TrishaNewChatFromChooser()),
                          )
                        : state.isWelcome
                            ? TrishaWelcome(
                                name: _firstName,
                                onSuggestion: (text) => _bloc.add(TrishaMessageSent(text)),
                                notice: state.error == null
                                    ? null
                                    : TrishaErrorRow(
                                        message: state.error!,
                                        onRetry: () => _bloc.add(
                                          state.messages.isEmpty
                                              ? const TrishaChatStarted()
                                              : const TrishaRetried(),
                                        ),
                                      ),
                              )
                            : _chatBody(state),
                  ),
                  // Reserve the input bar's height so the content doesn't sit under it.
                  if (!state.isChooser) SizedBox(height: context.fx(96)),
                ],
              ),

              // ---- Bottom gradient (peach left → blue right, fades up) ----
              if (!state.isChooser)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: context.fx(280),
                  child: IgnorePointer(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect bounds) => const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.white, Colors.transparent],
                      ).createShader(bounds),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFF8C00).withOpacity(0.28),
                              Colors.transparent,
                              const Color(0xFF008AFF).withOpacity(0.14),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ---- Input bar ----
              if (!state.isChooser)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Talk to a travel expert instead" link (AI mode only, not in expert mode)
                      if (state.mode == TrishaChatMode.ai && !state.isWelcome)
                        TrishaExpertLink(
                          busy: state.waiting,
                          onTap: () => _bloc.add(const TrishaExpertRequested()),
                        ),
                      TrishaInputBar(
                        enabled: state.isExpert ? state.expertConnected : !state.waiting,
                        hintText: state.isExpert ? 'Message our travel expert…' : null,
                        onSend: (text) {
                          if (state.isExpert) {
                            _bloc.add(TrishaExpertMessageSent(text));
                          } else {
                            _bloc.add(TrishaMessageSent(text));
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(TrishaChatState state) => Padding(
        padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(24), context.fx(16), 0),
        child: Row(
          children: [
            TrishaCircleButton(
              icon: Icons.close_rounded,
              iconSize: context.fx(20),
              onTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: state.isChooser || state.isWelcome
                  ? Center(
                      child: state.isExpert
                          ? Text('Travel Expert', style: TrishaStyle.display(context, 18))
                          : const TrishaTitle(size: 20),
                    )
                  : state.isExpert
                      ? Center(
                          child: Column(
                            children: [
                              Text('Travel Expert', style: TrishaStyle.display(context, 16)),
                              Text(
                                state.expertConnected ? 'Online · Wander Nova team' : 'Connecting…',
                                style: TrishaStyle.body(context, 10, color: TrishaStyle.hint),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
            if (!state.isChooser && !state.isExpert) ...[
              TrishaCircleButton(
                icon: Icons.history_rounded,
                iconSize: context.fx(18),
                onTap: _openHistory,
              ),
              SizedBox(width: context.fx(8)),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'new') _bloc.add(const TrishaChatStarted());
                  if (v == 'history') _openHistory();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'new', child: Text('New chat')),
                  PopupMenuItem(value: 'history', child: Text('Recent chats')),
                ],
                child: Container(
                  width: context.fx(32),
                  height: context.fx(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: TrishaStyle.softShadow,
                  ),
                  child: Icon(Icons.more_vert_rounded, size: context.fx(16), color: TrishaStyle.text),
                ),
              ),
            ],
            if (state.isChooser)
              const SizedBox(width: 32), // balance the close button
          ],
        ),
      );

  Widget _chatBody(TrishaChatState state) {
    return Column(
      children: [
        // Expert banner
        if (state.isExpert && state.ticket != null)
          TrishaExpertBanner(ticketNumber: state.ticket!.ticketNumber),

        // Messages
        Expanded(child: _chat(state)),
      ],
    );
  }

  Widget _chat(TrishaChatState state) {
    final latestId = state.latestTrishaId;
    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(24), context.fx(16), context.fx(16)),
      itemCount: state.messages.length + (state.waiting || state.error != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == state.messages.length) {
          return state.waiting
              ? const TrishaTyping()
              : TrishaErrorRow(message: state.error!, onRetry: () => _bloc.add(const TrishaRetried()));
        }
        final m = state.messages[i];
        if (m.fromUser) return TrishaUserBubble(text: m.text);
        return TrishaReplyView(
          message: m,
          isLatest: m.id == latestId,
          busy: state.waiting,
          handler: _handler,
          onQuickReply: (text) => _bloc.add(TrishaMessageSent(text)),
          onFeedback: (liked) => _bloc.add(TrishaFeedbackGiven(m.id, liked: liked)),
          onSave: () => _bloc.add(TrishaMessageSaved(m.id)),
        );
      },
    );
  }
}
