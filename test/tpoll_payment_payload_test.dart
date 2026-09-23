// What the transport booking sends to the reservation API: supplier add-ons in
// `optional_amenities`, the coupon + discount, and a correctly-prefixed phone.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wander_nova/views/TResevation/data/data_source/TReservation_api_service.dart';
import 'package:wander_nova/views/TResevation/data/repository/TReposiotry_impl.dart';
import 'package:wander_nova/views/TResevation/domain/entities/TReservation-entity.dart';

class _CapturingApi implements TransportReservationApiService {
  Map<String, dynamic>? sent;

  @override
  Future<Response> createReservation(Map<String, dynamic> requestData) async {
    sent = requestData;
    return Response(
      requestOptions: RequestOptions(path: '/x'),
      data: {
        'success': true,
        'local': {'status': 'pending'},
      },
    );
  }
}

Future<Map<String, dynamic>> _send({
  required String phone,
  List<String> amenities = const [],
  double discount = 0,
  String? coupon,
}) async {
  final api = _CapturingApi();
  await TransportReservationRepositoryImpl(api).createReservation(
    searchId: 's',
    resultId: 'r',
    firstName: 'Anjli',
    email: 'a@b.com',
    phoneNumber: phone,
    customerInfo: CustomerInfoEntity(
        firstName: 'Anjli', lastName: 'Singh', email: 'a@b.com', phoneNumber: phone),
    passengers: const [
      PassengerEntity(firstName: 'Anjli', lastName: 'Singh', email: 'a@b.com'),
    ],
    numPassengers: 2,
    currency: 'USD',
    selectedCurrency: 'INR',
    displayCurrency: 'INR',
    displayTotalPrice: 3120,
    displayBasePrice: 3000,
    displayRideBasePrice: 3000,
    displayDiscountAmount: discount,
    optionalAmenities: amenities,
    tripStartAddress: 'A',
    tripEndAddress: 'B',
    tripPickupDatetime: '2026-09-17T10:00:00',
    tripType: 'one_way',
    vehicleName: 'Standard',
    providerName: 'KiwiTaxi',
    paidVia: 'razorpay',
    paymentGateway: 'razorpay',
    paymentReferenceId: 'pay_1',
    razorpayOrderId: '',
    razorpayPaymentId: '',
    flightNumber: 'AI101',
    airline: 'AI',
    couponCode: coupon,
  );
  return api.sent!;
}

void main() {
  test('add-ons, coupon and discount are in the request', () async {
    final body = await _send(
      phone: '+919876543212',
      amenities: ['child_seat', 'razorpay_payment'],
      discount: 150,
      coupon: 'WNTAPPLY',
    );
    expect(body['optional_amenities'], ['child_seat', 'razorpay_payment']);
    expect(body['coupon_code'], 'WNTAPPLY');
    expect(body['display_discount_amount'], 150);
    expect(body['display_total_price'], 3120);
  });

  test('no coupon → no coupon_code key', () async {
    final body = await _send(phone: '+919876543212');
    expect(body.containsKey('coupon_code'), isFalse);
    expect(body['display_discount_amount'], 0);
  });

  test('phone: international number is not double-prefixed', () async {
    final body = await _send(phone: '+919876543212');
    expect(body['phone_number'], '919876543212');
    expect((body['customer_info'] as Map)['phone_number'], '919876543212');

    final uae = await _send(phone: '+971501234567');
    expect(uae['phone_number'], '971501234567');
  });

  test('phone: a bare national number keeps the legacy 91 prefix', () async {
    final body = await _send(phone: '9876543212');
    expect(body['phone_number'], '919876543212');
  });
}
