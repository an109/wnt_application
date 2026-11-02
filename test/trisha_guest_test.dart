import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/views/TrishaAI/data/data_source/trisha_api_service.dart';
import 'package:wander_nova/views/TrishaAI/data/model/trisha_models.dart';
import 'package:wander_nova/views/TrishaAI/presentation/bloc/trisha_chat_bloc.dart';
import 'package:wander_nova/views/TrishaAI/presentation/bloc/trisha_chat_event.dart';
import 'package:wander_nova/views/TrishaAI/presentation/widgets/trisha_cards.dart';

/// Answers every request with [status] and [body], and keeps what was asked.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = {'session_id': 's1', 'text': 'Hi', 'cards': [], 'quick_replies': []};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(TrishaApiService, _Adapter) service({String Function()? guestId}) {
  final adapter = _Adapter();
  final dio = Dio()..httpClientAdapter = adapter;
  TrishaApiService.resolvedBaseForTest = 'https://thrisha.test';
  return (TrishaApiService(dio, guestId: guestId), adapter);
}

class _FakeApi extends TrishaApiService {
  _FakeApi() : super(Dio());
  var starts = 0;

  @override
  Future<TrishaReply> startChat() async {
    starts++;
    return TrishaReply(sessionId: 'new$starts', text: 'Hi Arun! How may I help?', quickReplies: const ['Book a flight']);
  }

  @override
  Future<TrishaReply> sendMessage({required String sessionId, required String text}) async =>
      TrishaReply(sessionId: sessionId, text: 'Please log in to book.', cards: const [
        TrishaCard(type: 'login_required', data: {'reason': 'booking'}),
      ]);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => TrishaApiService.resolvedBaseForTest = null);

  group('a visitor who has not logged in', () {
    test('every chat call carries the guest id', () async {
      final (api, adapter) = service(guestId: () => 'guest-abc-0000000000000001');
      await api.startChat();
      await api.sendMessage(sessionId: 's1', text: 'hello');
      await api.sendAction(sessionId: 's1', type: 'select_option', data: {'option_number': 1});
      expect(adapter.requests, hasLength(3));
      for (final r in adapter.requests) {
        expect(r.headers['X-Guest-Id'], 'guest-abc-0000000000000001', reason: r.path);
      }
      expect(adapter.requests.first.path, 'https://thrisha.test/v1/chat/start');
    });

    test('so do the history and expert calls', () async {
      final (api, adapter) = service(guestId: () => 'guest-abc-0000000000000001');
      adapter.body = {'chats': [], 'active': false};
      await api.listChats();
      await api.getActiveExpertChat();
      expect(adapter.requests.every((r) => r.headers['X-Guest-Id'] == 'guest-abc-0000000000000001'), isTrue);
    });

    test('no guest id configured → no header (nothing invented)', () async {
      final (api, adapter) = service();
      await api.startChat();
      expect(adapter.requests.single.headers.containsKey('X-Guest-Id'), isFalse);
    });

    test('having no expert chat is not an error', () async {
      final (api, adapter) = service(guestId: () => 'guest-abc-0000000000000001');
      adapter
        ..status = 401
        ..body = {'detail': 'Login required'};
      final chat = await api.getActiveExpertChat();
      expect(chat.active, isFalse);
    });

    test('past chats say a login is needed', () async {
      final (api, adapter) = service(guestId: () => 'guest-abc-0000000000000001');
      adapter
        ..status = 401
        ..body = {'detail': 'Login required'};
      expect(api.listChats(), throwsA(isA<TrishaException>().having((e) => e.message, 'message', contains('log in'))));
    });

    test('a refused chat still reports that a login is needed', () async {
      final (api, adapter) = service();
      adapter
        ..status = 401
        ..body = {'detail': 'Login required'};
      expect(api.startChat(), throwsA(isA<TrishaException>().having((e) => e.message, 'message', contains('log in'))));
    });
  });

  group('the guest id', () {
    test('is made once, long enough for the server, and kept', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PreferencesManager.create(await SharedPreferences.getInstance());
      final first = prefs.getThrishaGuestId();
      expect(first.length, greaterThanOrEqualTo(16));
      expect(RegExp(r'^[A-Za-z0-9-]+$').hasMatch(first), isTrue);
      expect(prefs.getThrishaGuestId(), first);
    });

    test('comes back after the app restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs1 = await PreferencesManager.create(await SharedPreferences.getInstance());
      final id = prefs1.getThrishaGuestId();
      final prefs2 = await PreferencesManager.create(await SharedPreferences.getInstance());
      expect(prefs2.getThrishaGuestId(), id);
    });

    test('is different on another device', () async {
      SharedPreferences.setMockInitialValues({});
      final a = (await PreferencesManager.create(await SharedPreferences.getInstance())).getThrishaGuestId();
      SharedPreferences.setMockInitialValues({});
      final b = (await PreferencesManager.create(await SharedPreferences.getInstance())).getThrishaGuestId();
      expect(a, isNot(b));
    });

    test('a too-short stored id is replaced', () async {
      SharedPreferences.setMockInitialValues({'thrisha_guest_id': 'short'});
      final prefs = await PreferencesManager.create(await SharedPreferences.getInstance());
      expect(prefs.getThrishaGuestId().length, greaterThanOrEqualTo(16));
    });
  });

  group('"Log in" card', () {
    Future<void> pump(WidgetTester tester, {required bool active, required void Function(String?) onLogin, String? reason}) async {
      tester.view.physicalSize = const Size(412 * 3, 917 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TrishaCardView(
              active: active,
              card: TrishaCard(type: 'login_required', data: {if (reason != null) 'reason': reason}),
              handler: TrishaCardHandler(
                action: (type, {data, label}) {},
                addTraveller: () {},
                openProfile: ({thenAction}) {},
                pay: (_) {},
                openFlights: () {},
                login: onLogin,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('shows a button that opens login with the reason', (tester) async {
      String? got = 'untouched';
      await pump(tester, active: true, reason: 'expert', onLogin: (r) => got = r);
      expect(find.text('Log in or sign up'), findsOneWidget);
      expect(find.textContaining('travel expert'), findsOneWidget);
      await tester.tap(find.text('Log in or sign up'));
      expect(got, 'expert');
    });

    testWidgets('a booking card says so', (tester) async {
      await pump(tester, active: true, reason: 'booking', onLogin: (_) {});
      expect(find.textContaining('booking'), findsOneWidget);
    });

    testWidgets('an older card (not the latest reply) does nothing', (tester) async {
      var taps = 0;
      await pump(tester, active: false, reason: 'booking', onLogin: (_) => taps++);
      await tester.tap(find.text('Log in or sign up'), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('after a guest logs in mid-chat', () {
    test('the conversation stays and carries on under a new chat', () async {
      final api = _FakeApi();
      final bloc = TrishaChatBloc(api: api);
      bloc.add(const TrishaMessageSent('book me a flight'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.messages, hasLength(2)); // the user's text + the login ask
      expect(bloc.state.messages.last.cards.single.type, 'login_required');
      final sessionBefore = bloc.state.sessionId;

      bloc.add(const TrishaLoggedIn());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.messages, hasLength(3));
      expect(bloc.state.messages.last.text, contains('Hi Arun'));
      expect(bloc.state.messages.last.quickReplies, ['Book a flight']);
      expect(bloc.state.sessionId, isNot(sessionBefore));
      expect(bloc.state.waiting, isFalse);
      expect(bloc.state.error, isNull);
      await bloc.close();
    });
  });
}
