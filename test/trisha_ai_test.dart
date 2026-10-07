import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/views/TrishaAI/data/data_source/trisha_api_service.dart';
import 'package:wander_nova/views/TrishaAI/data/model/trisha_models.dart';
import 'package:wander_nova/views/TrishaAI/presentation/bloc/trisha_chat_bloc.dart';
import 'package:wander_nova/views/TrishaAI/presentation/bloc/trisha_chat_event.dart';
import 'package:wander_nova/views/TrishaAI/presentation/widgets/trisha_cards.dart';
import 'package:wander_nova/views/TrishaAI/presentation/widgets/trisha_input_bar.dart';
import 'package:wander_nova/views/TrishaAI/presentation/widgets/trisha_messages.dart';
import 'package:wander_nova/views/TrishaAI/presentation/widgets/trisha_welcome.dart';

/// Records what the chat sends and answers with canned replies.
class FakeTrishaApi extends TrishaApiService {
  FakeTrishaApi() : super(Dio());
  final sent = <String>[];

  @override
  Future<TrishaReply> startChat() async =>
      const TrishaReply(sessionId: 's1', text: 'Hi Arun! 👋 How may I help you today?');

  @override
  Future<TrishaReply> sendMessage({required String sessionId, required String text}) async {
    sent.add('msg:$text');
    return TrishaReply(sessionId: sessionId, text: 'Where are you flying from?', quickReplies: const ['Delhi']);
  }

  @override
  Future<TrishaReply> sendAction({required String sessionId, required String type, Map<String, dynamic> data = const {}}) async {
    sent.add('action:$type');
    return TrishaReply(sessionId: sessionId, text: 'ok');
  }
}

const flights = [
  {'leg': 'onward', 'airline': 'IndiGo', 'flight_no': '6E 201', 'from': 'DEL', 'to': 'GOI',
   'departure_time': '08:05', 'arrival_time': '10:30', 'duration': '2h 25m', 'stops': 0},
];

final allCards = <TrishaCard>[
  const TrishaCard(type: 'flight_option', data: {
    'option_number': 1, 'leg': 'onward', 'airline': 'Air India Express', 'flight_no': 'IX 1234', 'from': 'DEL',
    'to': 'GOI', 'departure_time': '08:05', 'arrival_time': '10:30', 'duration': '2h 25m', 'stops': 1,
    'fare_total': 612345, 'travellers': 4, 'refundable': true,
    'highlights': ['Cheapest', 'Fastest', 'Non-stop', 'At your preferred time', 'Air India Express (your preferred airline)'],
  }),
  const TrishaCard(type: 'traveller_picker', data: {
    'travellers': [
      {'id': 11, 'number': 1, 'name': 'Rakesh K.', 'pax_type': 'ADT', 'missing': []},
      {'id': 12, 'number': 2, 'name': 'Priya K.', 'pax_type': 'ADT', 'missing': ['date of birth']},
    ],
    'required': {'adults': 2},
  }),
  const TrishaCard(type: 'add_traveller', data: {'pax_types': ['adult']}),
  const TrishaCard(type: 'edit_traveller', data: {'traveller_id': 12, 'missing': ['date of birth']}),
  const TrishaCard(type: 'update_profile', data: {'missing': ['mobile number']}),
  const TrishaCard(type: 'booking_review', data: {
    'flights': flights, 'travellers': [{'name': 'Rakesh K.', 'pax_type': 'ADT'}],
    'fare_total': 6100, 'previous_fare': 5900, 'currency': 'INR',
    'baggage': {'checkin': '15 Kg', 'cabin': '7 Kg'}, 'refundable': false,
  }),
  const TrishaCard(type: 'razorpay_checkout', data: {
    'order_id': 'order_1', 'key_id': 'rzp_test', 'amount': 610000, 'currency': 'INR',
    'display_amount': 6100, 'description': 'DEL → GOI 6E 201', 'prefill': {},
  }),
  const TrishaCard(type: 'booking_confirmed', data: {
    'pnr': 'PNR123', 'booking_reference': 'TXN-9', 'flights': flights,
    'travellers': [{'name': 'Rakesh K.', 'pax_type': 'ADT'}], 'amount_paid': 6100,
  }),
  const TrishaCard(type: 'open_flight_booking', data: {'tui': 't', 'indexes': ['a']}),
  const TrishaCard(type: 'web_sources', data: {
    'sources': [
      {'title': 'India Meteorological Department — Goa weather forecast for the week', 'url': 'https://mausam.imd.gov.in'},
      {'title': 'ixigo.com', 'url': 'https://www.ixigo.com'},
    ],
    'search_html': '<div>Google</div>',
  }),
  const TrishaCard(type: 'holiday_option', data: {
    'option_number': 1, 'share_id': 's1', 'title': 'Affectionate Kerala – Honeymoon Special with a very long name indeed',
    'destination': 'Alleppey', 'nights': 3, 'days': 4, 'image': null, 'themes': ['honeymoon', 'wellness'],
    'origin': 'New Delhi', 'adults': 2, 'price_with_flight': 9570679, 'price_without_flight': 2510479,
  }),
  const TrishaCard(type: 'holiday_quote', data: {
    'title': 'Affectionate Kerala', 'image': null, 'destination': 'Alleppey', 'nights': 3, 'start_date': '2026-11-15',
    'adults': 2, 'children': 1, 'flight_included': true, 'origin': 'Mumbai', 'total': 64371, 'per_person': 32185,
    'tax': 3065, 'is_final': true, 'notes': [], 'counts': {},
    'changes': ['Changed your Munnar hotel to Blanket Hotel'], 'days': [{'day': 1, 'date': '2026-11-15', 'label': 'Arrival in Cochin',
              'items': ['✈️ BOM to COK', '🚗 Cochin to Munnar', '🏨 Tea County Resort and Spa by the river']}],
  }),
  const TrishaCard(type: 'package_choice', data: {
    'kind': 'hotel', 'option_number': 1, 'title': 'Blanket Hotel & Spa with a very long name that wraps around',
    'subtitle': '5★ · 4.6/5 (900 reviews) · Pallivasal, Munnar, Kerala 685565, a long address line',
    'details': ['Breakfast included', 'Swimming pool', 'Spa and wellness centre'], 'image': null,
    'delta': 12000, 'delta_text': '+₹12,000', 'is_selected': false,
  }),
  const TrishaCard(type: 'package_choice', data: {
    'kind': 'addon', 'option_number': 2, 'title': 'Kolukkumalai Sunrise Jeep Safari', 'subtitle': 'Munnar · 6h',
    'details': ['Recharge on your trip with an exciting trek to Kolukkumalai! Board your Jeep from Chinnakanal'],
    'image': null, 'delta': null, 'delta_text': '₹4,194 per person', 'is_selected': true,
  }),
  const TrishaCard(type: 'holiday_review', data: {
    'title': 'Affectionate Kerala', 'image': null, 'nights': 3, 'start_date': '2026-11-15', 'flight_included': false,
    'origin': '', 'travellers': [{'name': 'Arun S.', 'pax_type': 'ADT'}], 'total': 49451, 'tax': 2355,
  }),
  const TrishaCard(type: 'holiday_payment_options', data: {
    'reference': 'WN-021B26', 'grand_total': 49451, 'amount_paid': 0, 'balance': 49451, 'balance_due_on': null,
    'instalments': [{'percent': 25, 'pay_now': 12363, 'balance': 37088, 'balance_due_on': '2026-10-31'},
                    {'percent': 100, 'pay_now': 49451, 'balance': 0, 'balance_due_on': null}],
    'cancellation_policy': [{'label': '30+ days before', 'fee_percent': 10, 'note': ''},
                            {'label': 'Within 7 days', 'fee_percent': null, 'note': ''}],
  }),
  const TrishaCard(type: 'holiday_booking_confirmed', data: {
    'reference': 'WN-021B26', 'title': 'Affectionate Kerala', 'image': null, 'start_date': '2026-11-15', 'nights': 3,
    'travellers': [{'name': 'Arun S.', 'pax_type': 'ADT'}], 'grand_total': 49451, 'amount_paid': 12363,
    'balance': 37088, 'balance_due_on': '2026-10-31', 'currency': 'INR',
  }),
  const TrishaCard(type: 'hotel_option', data: {
    'option_number': 2, 'hotel_id': 'H2', 'name': 'Palm Grove Beach Resort & Spa by a Very Long Brand Name',
    'stars': 5, 'rating': 4.7, 'reviews': 1203, 'address': 'Calangute Beach Road, North Goa, Goa 403516, India',
    'image': null, 'price_total': 2100000, 'price_per_night': 700000, 'nights': 3,
    'free_breakfast': true, 'free_cancellation': true,
    'highlights': ['Best price', 'Top rated', 'Breakfast included', 'Free cancellation'],
  }),
  const TrishaCard(type: 'room_option', data: {
    'option_number': 3, 'room_name': 'Premier Sea View Room with Balcony and Private Plunge Pool', 'meal': 'Breakfast',
    'refundable': true, 'cancellation': 'Free cancellation until 2026-10-13', 'price_total': 26000,
    'price_per_night': 8667, 'nights': 3,
  }),
  const TrishaCard(type: 'hotel_review', data: {
    'hotel': 'Palm Grove', 'address': 'Calangute, Goa', 'image': null, 'stars': 5, 'check_in': '2026-10-15',
    'check_out': '2026-10-18', 'nights': 3, 'rooms': 2, 'room_name': 'Deluxe Room', 'meal': 'Breakfast',
    'refundable': false, 'cancellation': '', 'guests': [{'name': 'Rakesh K.', 'pax_type': 'ADT'},
    {'name': 'Aarav K.', 'pax_type': 'CHD'}], 'price_total': 23500, 'previous_price': 21000, 'currency': 'INR',
  }),
  const TrishaCard(type: 'hotel_booking_confirmed', data: {
    'booking_reference': '260138984', 'confirmation_number': 'HTL123', 'hotel': 'Palm Grove', 'address': 'Goa',
    'check_in': '2026-10-15', 'check_out': '2026-10-18', 'nights': 3, 'room_name': 'Deluxe Room', 'meal': 'Breakfast',
    'guests': [{'name': 'Rakesh K.', 'pax_type': 'ADT'}], 'amount_paid': 23500, 'currency': 'INR',
  }),
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpPhone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pump();
  }

  testWidgets('every card type renders on a phone without overflow', (tester) async {
    final actions = <String>[];
    final handler = TrishaCardHandler(
      action: (type, {data, label}) => actions.add(type),
      addTraveller: () => actions.add('add'),
      openProfile: ({thenAction}) => actions.add('profile:$thenAction'),
      pay: (_) => actions.add('pay'),
      openFlights: () => actions.add('flights'),
    );
    await pumpPhone(
      tester,
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: TrishaReplyView(
          message: TrishaMessage(id: 'm1', fromUser: false, text: 'Here you go', cards: allCards,
              quickReplies: const ['Confirm & pay', 'Change travellers']),
          isLatest: true,
          busy: false,
          handler: handler,
          onQuickReply: (_) {},
          onFeedback: (_) {},
          onSave: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('PNR123'), findsOneWidget);
    expect(find.text('HTL123'), findsOneWidget);
    expect(find.text('2. ixigo.com'), findsOneWidget);
    expect(find.text('WN-021B26'), findsOneWidget);
    expect(find.text('• Within 7 days: fee to be confirmed by our team'), findsOneWidget);

    await tester.ensureVisible(find.text('Pay 25% now'));
    await tester.tap(find.text('Pay 25% now'));
    expect(actions, contains('select_instalment'));
    expect(find.text('Thu, 15 Oct → Sun, 18 Oct · 3 nights'), findsNWidgets(2));
    expect(find.text('2 × Deluxe Room · Breakfast'), findsOneWidget);
    expect(find.text('Select 2 adults'), findsOneWidget);

    await tester.ensureVisible(find.text('View rooms ›'));
    await tester.tap(find.text('View rooms ›'));
    await tester.ensureVisible(find.text('Room 3'));
    await tester.tap(find.text('Room 3'));
    expect(actions.where((a) => a == 'select_option').length, 2);

    await tester.ensureVisible(find.text('Option 1'));
    await tester.tap(find.text('Option 1'));
    expect(actions, contains('select_option'));
    actions.clear();

    // Continue is disabled until exactly the required number is picked.
    await tester.ensureVisible(find.text('Rakesh K.').first);
    await tester.tap(find.text('Rakesh K.').first);
    await tester.pump();
    expect(actions, isNot(contains('select_travellers')));
  });

  testWidgets('welcome screen and input bar lay out on a phone', (tester) async {
    final sent = <String>[];
    await pumpPhone(
      tester,
      Column(children: [
        Expanded(child: TrishaWelcome(name: 'Anjli', onSuggestion: sent.add)),
        TrishaInputBar(enabled: true, onSend: sent.add, onMic: () {}),
      ]),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Hi, ANJLI'), findsOneWidget);

    await tester.tap(find.text('Search for your next holiday destination'));
    await tester.enterText(find.byType(TextField), 'kal delhi se goa');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(sent, ['Book a flight', 'kal delhi se goa']);
  });

  test('bloc: start, message, action', () async {
    final api = FakeTrishaApi();
    final bloc = TrishaChatBloc(api: api);
    bloc.add(const TrishaChatStarted());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.sessionId, 's1');
    expect(bloc.state.isWelcome, isTrue);

    bloc.add(const TrishaMessageSent('Book a flight'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.isWelcome, isFalse);
    expect(bloc.state.messages.map((m) => m.text), ['Book a flight', 'Where are you flying from?']);

    bloc.add(const TrishaActionSent('payment_result', data: {'status': 'cancelled'}));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(api.sent, ['msg:Book a flight', 'action:payment_result']);
    // Actions without a label add no user bubble
    expect(bloc.state.messages.where((m) => m.fromUser).length, 1);
    await bloc.close();
  });

  test('bloc: a message sent before the chat opens is not wiped by the late start', () async {
    final api = SlowStartApi();
    final bloc = TrishaChatBloc(api: api);
    bloc.add(const TrishaChatStarted());
    bloc.add(const TrishaMessageSent('kal delhi se goa'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.messages.map((m) => m.text), ['kal delhi se goa', 'Where are you flying from?']);
    expect(bloc.state.starting, isFalse);
    await bloc.close();
  });

  test('bloc: a failed send shows an error and Retry resends without a duplicate bubble', () async {
    final api = FlakyApi();
    final bloc = TrishaChatBloc(api: api);
    bloc.add(const TrishaChatStarted());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const TrishaMessageSent('Book a flight'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.error, contains("can't reach"));
    expect(bloc.state.messages.length, 1);

    api.down = false;
    bloc.add(const TrishaRetried());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.error, isNull);
    expect(bloc.state.messages.map((m) => m.text), ['Book a flight', 'Where are you flying from?']);
    await bloc.close();
  });
}

class FlakyApi extends FakeTrishaApi {
  bool down = true;

  @override
  Future<TrishaReply> sendMessage({required String sessionId, required String text}) async {
    if (down) throw const TrishaException("I can't reach Trisha at http://x. Please check the server.");
    return super.sendMessage(sessionId: sessionId, text: text);
  }
}

class SlowStartApi extends FakeTrishaApi {
  int starts = 0;

  @override
  Future<TrishaReply> startChat() async {
    // The first (screen-open) start is slow; the one the message triggers is quick.
    if (starts++ == 0) await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.startChat();
  }
}
