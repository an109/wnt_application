// Responsiveness + null-safety checks for the redesigned
// [AkHotelBookingConfirmedScreen].
//
// Pumps the screen at a spread of phone sizes with both a full real-data
// booking and a sparse one (no RetrieveBooking read-back, empty threaded
// extras), and fails on any RenderFlex overflow or other build exception.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wander_nova/views/AKHotelRetrieveBooking/domain/entity/AKHotelRetrieveBooking_entity.dart';
import 'package:wander_nova/views/AKHotelBooking/presentation/screen/ak_hotel_booking_confirmed_screen.dart';

AkHotelRetrieveBookingEntity _booking() {
  return const AkHotelRetrieveBookingEntity(
    transactionId: 'txn_123456',
    currentStatus: 'B0',
    grossFare: 54507,
    netFare: 54507,
    hotelName: 'Bloom Hotel - Sector 62',
    starRating: 4,
    city: 'Noida',
    country: 'India',
    rooms: [
      AkHotelBookingRoomEntity(
        name: 'Deluxe Room',
        guests: [
          AkHotelBookingGuestEntity(title: 'Ms', firstName: 'Anjli', lastName: 'Singh'),
        ],
        totalRate: 54507,
        baseRate: 54432,
        cancellationPolicyTexts: ['Free cancellation until 4 Sept'],
      ),
    ],
  );
}

Widget _host(Widget child) => MaterialApp(home: child);

const _sizes = <Size>[
  Size(320, 568), // iPhone SE (1st gen) — smallest common
  Size(360, 640), // small Android
  Size(375, 812), // design baseline
  Size(430, 932), // iPhone 15 Pro Max
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(WidgetTester tester, Size size, Widget screen) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(screen));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull, reason: 'build/layout threw at $size');
  }

  testWidgets('renders a full booking with no overflow at every size', (tester) async {
    for (final size in _sizes) {
      await pumpAt(
        tester,
        size,
        AkHotelBookingConfirmedScreen(
          hotelName: 'Bloom Hotel - Sector 62',
          transactionId: 'txn_123456',
          crsPnr: 'ASDFGHJKL',
          checkIn: '09/05/2026',
          checkOut: '09/06/2026',
          checkInTime: '2:00 PM',
          checkOutTime: '11:00 AM',
          hotelImage: 'https://example.com/hotel.jpg',
          hotelAddress: 'C30/4, C block Phase 2, Industrial Area',
          hotelCity: 'Sector 62',
          hotelCountry: 'India',
          starRating: 4,
          reviewRating: 4.2,
          roomType: 'Deluxe Room',
          mealPlan: 'Breakfast',
          roomsCount: 1,
          adultsCount: 2,
          childrenCount: 1,
          baseFare: 54432,
          netAmount: 54507,
          leadGuestName: 'Anjli Singh',
          leadGuestEmail: 'anjliuxdev@gmail.com',
          leadGuestPhone: '+91 9876543212',
          paymentGateway: 'razorpay',
          bookedAt: DateTime(2026, 9, 6),
          booking: _booking(),
        ),
      );

      expect(find.text('Payment Successful!'), findsOneWidget);
      expect(find.text('Your booking is confirmed.'), findsOneWidget);
      expect(find.textContaining('txn_123456'), findsWidgets);
      expect(find.text('ASDFGHJKL'), findsOneWidget);
      expect(find.text('Anjli Singh'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    }
  });

  testWidgets('handles missing / no RetrieveBooking read-back without overflow', (tester) async {
    for (final size in _sizes) {
      await pumpAt(
        tester,
        size,
        const AkHotelBookingConfirmedScreen(
          hotelName: '',
          transactionId: 'txn_only',
          crsPnr: '',
          checkIn: '',
          checkOut: '',
          booking: null,
        ),
      );

      expect(find.text('Payment Successful!'), findsOneWidget);
      expect(find.textContaining('txn_only'), findsWidgets);
    }
  });
}
