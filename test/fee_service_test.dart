import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/core/services/fee_service.dart';

void main() {
  final fees = FeeService.instance;

  setUp(fees.reset);

  test('default slabs apply when the admin has set nothing', () {
    fees.applyResponse({'tax_margin': {}, 'fee_slabs': []});
    // ₹10,000 sits in the ₹3,000–14,999 band: 5% / 0.7% / 0.3%.
    final f = fees.feeFor(FeeServiceType.flights, 10000);
    expect(f.convenienceFee, 500);
    expect(f.platformFee, 70);
    expect(f.bookingMgmtFee, 30);
    expect(f.source, 'default');
  });

  test('admin single values override the defaults (percent and flat)', () {
    fees.applyResponse({
      'tax_margin': {
        'hotels_convenience_type': 'percent',
        'hotels_convenience_value': '2.00',
        'hotels_platform_type': 'flat',
        'hotels_platform_value': '150.00',
        'hotels_booking_mgmt_type': 'percent',
        'hotels_booking_mgmt_value': '0.00',
      },
      'fee_slabs': [],
    });
    final f = fees.feeFor(FeeServiceType.hotels, 20000);
    expect(f.convenienceFee, 400);
    expect(f.platformFee, 150);
    expect(f.bookingMgmtFee, 0);
    expect(f.source, 'master');
    // Other services are untouched by hotels' settings.
    expect(fees.feeFor(FeeServiceType.flights, 20000).source, 'default');
  });

  test('admin fare-range slabs win over single values', () {
    fees.applyResponse({
      'tax_margin': {
        'flights_convenience_type': 'percent',
        'flights_convenience_value': '9.00',
      },
      'fee_slabs': [
        {
          'service': 'flights',
          'min_amount': '0',
          'max_amount': '10000',
          'convenience_percent': '1.00',
          'platform_percent': '1.00',
          'booking_mgmt_percent': '1.00',
        },
        {
          'service': 'flights',
          'min_amount': '10000',
          'max_amount': null,
          'convenience_percent': '3.00',
          'platform_percent': '2.00',
          'booking_mgmt_percent': '1.00',
        },
      ],
    });
    final low = fees.feeFor(FeeServiceType.flights, 5000);
    expect([low.convenienceFee, low.platformFee, low.bookingMgmtFee], [50, 50, 50]);
    expect(low.source, 'admin-slab');
    final high = fees.feeFor(FeeServiceType.flights, 10000);
    expect([high.convenienceFee, high.platformFee, high.bookingMgmtFee], [300, 200, 100]);
    // A service with no slabs of its own falls back to the next rule.
    expect(fees.feeFor(FeeServiceType.hotels, 5000).source, 'default');
  });

  test('transfers keep paise, flights round to whole rupees', () {
    fees.applyResponse({'tax_margin': {}, 'fee_slabs': []});
    // ₹1,234.56 → below ₹3,000: 2.5% / 2% / 1.5%.
    final t = fees.feeFor(FeeServiceType.transfers, 1234.56);
    expect(t.convenienceFee, 30.86);
    expect(t.platformFee, 24.69);
    expect(t.bookingMgmtFee, 18.52);
    final fl = fees.feeFor(FeeServiceType.flights, 1234.56);
    expect(fl.convenienceFee, 31);
  });

  test('no fare, no fee; toJson uses the keys the backend stores', () {
    expect(fees.feeFor(FeeServiceType.flights, 0).isZero, isTrue);
    const b = FeeBreakdown(convenienceFee: 1, platformFee: 2, bookingMgmtFee: 3);
    expect(b.total, 6);
    expect(b.toJson(), {'convenience_fee': 1.0, 'platform_fee': 2.0, 'booking_mgmt_fee': 3.0});
  });
}
