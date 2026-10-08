import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/injection_container.dart' show sl;
import 'package:wander_nova/views/TrishaAI/data/data_source/trisha_api_service.dart';
import 'package:wander_nova/views/TrishaAI/data/model/trisha_models.dart';
import 'package:wander_nova/views/TrishaAI/presentation/bloc/trisha_chat_bloc.dart';
import 'package:wander_nova/views/TrishaAI/presentation/bloc/trisha_chat_event.dart';
import 'package:wander_nova/views/TrishaAI/presentation/screen/trisha_history_screen.dart';
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
  Future<TrishaReply> sendAction({
    required String sessionId,
    required String type,
    Map<String, dynamic> data = const {},
    String? label,
  }) async {
    sent.add('action:$type${label == null ? '' : ':$label'}');
    return TrishaReply(sessionId: sessionId, text: 'ok');
  }

  @override
  Future<List<TrishaChatSummary>> listChats({DateTime? before, int limit = 20}) async => [
        TrishaChatSummary(sessionId: 'old1', title: 'delhi airport se taj palace cab', flow: 'transfer',
            lastMessage: 'Here are cars…', updatedAt: DateTime.now()),
        TrishaChatSummary(sessionId: 'old2', title: 'goa hotels', flow: 'hotel', lastMessage: 'Pick a room',
            updatedAt: DateTime.now().subtract(const Duration(days: 1))),
      ];

  @override
  Future<TrishaChatHistory> getChat(String sessionId) async => TrishaChatHistory.fromJson({
        'session_id': sessionId,
        'messages': [
          {'role': 'assistant', 'text': 'Hi Arun!', 'cards': [], 'quick_replies': ['Book a flight']},
          {'role': 'user', 'text': 'goa hotels', 'cards': [], 'quick_replies': []},
          {'role': 'assistant', 'text': 'Pick a room', 'cards': [{'type': 'web_sources', 'data': {'sources': []}}],
           'quick_replies': ['Room 1']},
        ],
      });

  @override
  Future<void> deleteChat(String sessionId) async => sent.add('delete:$sessionId');
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
  const TrishaCard(type: 'transfer_option', data: {
    'option_number': 2, 'vehicle_type': 'Private Van', 'car': 'Kia Carnival with a very long model name here',
    'car_class': 'Business', 'image': null, 'provider': 'First-Choice Taxi Services Private Limited',
    'provider_rating': 4.6, 'provider_reviews': 16965, 'seats': 5, 'bags': 5, 'num_vehicles': 2, 'price': 123456,
    'currency': 'INR', 'passengers': 4, 'minutes': 25, 'free_cancel_hours': 6.0, 'wait_minutes': 60,
    'included': ['Meet & Greet', 'WiFi', 'English speaking driver', 'In-seat power'],
  }),
  const TrishaCard(type: 'transfer_review', data: {
    'pickup': 'Manohar International Airport (GOX)', 'dropoff': 'Calangute, Goa, India, a long address line here',
    'date': '2026-11-20', 'time': '18:00', 'passengers': 4, 'car': 'Kia Carnival', 'vehicle_type': 'Private Van',
    'image': null, 'provider': 'First-Choice Taxi', 'seats': 5, 'bags': 5, 'flight_number': '6E 2134',
    'free_cancel_hours': null, 'included': [], 'price': 2931, 'currency': 'INR',
  }),
  const TrishaCard(type: 'transfer_booking_confirmed', data: {
    'confirmation_number': 'MZ12345', 'pickup': 'GOX', 'dropoff': 'Calangute', 'date': '2026-11-20', 'time': '18:00',
    'passengers': 1, 'car': 'Kia Carnival', 'provider': 'First-Choice Taxi', 'image': null, 'flight_number': null,
    'free_cancel_hours': 6.5, 'amount_paid': 2931, 'currency': 'INR',
  }),
  const TrishaCard(type: 'insurance_plan', data: {
    'option_number': 1, 'plan_id': 'P1', 'name': 'Travel Assure Explorer Gold with a very long plan name',
    'logo': null, 'document': 'https://x/wording.pdf', 'recommended': true,
    'provider': 'ICICI Lombard General Insurance', 'premium': 145123, 'currency': 'INR',
    'sum_insured': 250000, 'cover_currency': 'USD', 'highlights': ['Medical', 'Baggage loss', 'Trip delay'],
  }),
  const TrishaCard(type: 'insurance_plan_details', data: {
    'name': 'Explorer', 'provider': 'RELIGARE', 'premium': 1720, 'currency': 'INR', 'sum_insured': 100000,
    'cover_currency': 'USD', 'more_benefits': 4, 'terms': ['https://x/tnc.pdf'], 'notes': ['Ages 0-70 only'],
    'benefits': [
      {'title': 'Medical expenses including hospitalisation abroad', 'cover': 'USD 100,000', 'deductible': 'USD 100'},
      {'title': 'Loss of checked-in baggage', 'cover': 'USD 500', 'deductible': ''},
    ],
  }),
  const TrishaCard(type: 'insurance_details_form', data: {
    'questions': [{'title': 'Diabetes', 'code': 'PEDDiabetes', 'selection_type': 'checkbox'}],
    'nominee_relations': ['Spouse', 'Mother'], 'states': ['Rajasthan', 'Delhi'],
    'prefill': {'city': 'Jaipur', 'state': 'Rajasthan'},
  }),
  const TrishaCard(type: 'insurance_review', data: {
    'plan': 'Explorer', 'provider': 'RELIGARE', 'countries': ['Thailand', 'United Arab Emirates'],
    'start_date': '2026-11-01', 'end_date': '2026-11-10', 'policy_type': 'Family',
    'travellers': ['Rakesh Khatri', 'Priya Khatri', 'Aarav Khatri'], 'nominee': 'Sunita Khatri (Mother)',
    'health': 'No pre-existing disease', 'sum_insured': 100000, 'cover_currency': 'USD', 'premium': 1720,
    'currency': 'INR',
  }),
  const TrishaCard(type: 'insurance_confirmed', data: {
    'policy_number': 'POL-778899', 'transaction_id': 'TXN-1', 'plan': 'Explorer', 'provider': 'RELIGARE',
    'countries': ['Thailand'], 'start_date': '2026-11-01', 'end_date': null, 'travellers': 1,
    'amount_paid': 1720, 'currency': 'INR',
  }),
  const TrishaCard(type: 'traveller_picker', data: {
    'travellers': [{'id': 1, 'number': 1, 'name': 'Rakesh K.', 'pax_type': 'ADT', 'missing': []}],
    'required': {}, 'min': 1, 'max': 6, 'title': "Select who's travelling",
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

  testWidgets('insurance form sends its details as an action, never as chat text', (tester) async {
    final sent = <Map<String, dynamic>>[];
    String? bubble;
    final handler = TrishaCardHandler(
      action: (type, {data, label}) {
        sent.add({'type': type, ...?data});
        bubble = label;
      },
      addTraveller: () {},
      openProfile: ({thenAction}) {},
      pay: (_) {},
      openFlights: () {},
    );
    await pumpPhone(
      tester,
      SingleChildScrollView(
        child: TrishaCardView(
          active: true,
          handler: handler,
          card: const TrishaCard(type: 'insurance_details_form', data: {
            'questions': [{'title': 'Diabetes', 'code': 'PEDDiabetes', 'selection_type': 'checkbox'}],
            'nominee_relations': ['Spouse', 'Mother'], 'states': ['Rajasthan', 'Delhi'],
            'prefill': {'city': 'Jaipur', 'state': 'Rajasthan', 'nominee': {'relation': 'Mother'}},
          }),
        ),
      ),
    );
    Future<void> type(String label, String text) async {
      final field = find.widgetWithText(TextField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
    }

    await type('First name', 'Sunita');
    await type('Last name', 'Khatri');
    await type('Address line 1', '12 MG Road');
    await type('Pincode', '302001');
    await tester.ensureVisible(find.text('Yes'));
    await tester.tap(find.text('Yes'));
    await tester.pump();
    await tester.ensureVisible(find.text('Diabetes'));
    await tester.tap(find.text('Diabetes'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    expect(sent.single['type'], 'insurance_details');
    expect(sent.single['nominee'], {'first_name': 'Sunita', 'last_name': 'Khatri', 'relation': 'Mother'});
    expect((sent.single['address'] as Map)['state'], 'Rajasthan');
    expect(sent.single['health'], containsPair('conditions', ['PEDDiabetes']));
    expect(bubble, 'Details added');
  });

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

  testWidgets('recent chats lists past chats and returns the tapped one', (tester) async {
    final api = FakeTrishaApi();
    sl.registerSingleton<TrishaApiService>(api);
    addTearDown(() => sl.unregister<TrishaApiService>());
    String? picked = 'unset';
    await pumpPhone(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const TrishaHistoryScreen(currentSessionId: 'old1')),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('delhi airport se taj palace cab'), findsOneWidget);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    await tester.tap(find.text('goa hotels'));
    await tester.pumpAndSettle();
    expect(picked, 'old2');
  });

  test('bloc: a past chat reopens with its messages and continues in the same session', () async {
    final api = FakeTrishaApi();
    final bloc = TrishaChatBloc(api: api)..add(const TrishaChatOpened('old2'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.sessionId, 'old2');
    expect(bloc.state.messages.map((m) => m.text), ['Hi Arun!', 'goa hotels', 'Pick a room']);
    expect(bloc.state.isWelcome, isFalse);
    expect(bloc.state.messages.last.cards.single.type, 'web_sources');
    bloc.add(const TrishaActionSent('confirm_booking', label: 'Confirm & pay'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(api.sent.last, 'action:confirm_booking:Confirm & pay');
    await bloc.close();
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
