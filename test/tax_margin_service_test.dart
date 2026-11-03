import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/core/services/tax_margin_service.dart';

void main() {
  group('TaxMarginFees.compute', () {
    test('percent-based fees', () {
      const fees = TaxMarginFees(
        convenienceType: 'percent',
        convenienceValue: 2,
        platformType: 'percent',
        platformValue: 1.5,
        bookingMgmtType: 'percent',
        bookingMgmtValue: 1,
      );
      final b = fees.compute(10000);
      expect(b.convenienceFee, 200); // 2% of 10000
      expect(b.platformFee, 150); // 1.5% of 10000
      expect(b.bookingMgmtFee, 100); // 1% of 10000
      expect(b.total, 450);
      expect(b.hasAnyFee, true);
    });

    test('flat fees', () {
      const fees = TaxMarginFees(
        convenienceType: 'flat',
        convenienceValue: 99,
        platformType: 'flat',
        platformValue: 50,
        bookingMgmtType: 'flat',
        bookingMgmtValue: 25,
      );
      final b = fees.compute(5000);
      expect(b.convenienceFee, 99);
      expect(b.platformFee, 50);
      expect(b.bookingMgmtFee, 25);
      expect(b.total, 174);
    });

    test('mixed percent and flat', () {
      const fees = TaxMarginFees(
        convenienceType: 'percent',
        convenienceValue: 3,
        platformType: 'flat',
        platformValue: 75,
        bookingMgmtType: 'percent',
        bookingMgmtValue: 0,
      );
      final b = fees.compute(2000);
      expect(b.convenienceFee, 60); // 3% of 2000
      expect(b.platformFee, 75);
      expect(b.bookingMgmtFee, 0);
      expect(b.total, 135);
    });

    test('zero fees', () {
      const fees = TaxMarginFees.empty;
      final b = fees.compute(10000);
      expect(b.total, 0);
      expect(b.hasAnyFee, false);
    });

    test('slabs override flat/percent when matching', () {
      final fees = TaxMarginFees(
        convenienceType: 'percent',
        convenienceValue: 10, // would be 1000 on 10000
        platformType: 'percent',
        platformValue: 5,
        bookingMgmtType: 'percent',
        bookingMgmtValue: 2,
        slabs: [
          TaxMarginSlab(
            service: 'flights',
            minAmount: 5000,
            maxAmount: 15000,
            conveniencePercent: 1,
            platformPercent: 0.5,
            bookingMgmtPercent: 0.25,
          ),
        ],
      );
      final b = fees.compute(10000);
      expect(b.convenienceFee, 100); // slab: 1% of 10000
      expect(b.platformFee, 50); // slab: 0.5%
      expect(b.bookingMgmtFee, 25); // slab: 0.25%
    });

    test('slab does not match — falls back to flat/percent', () {
      final fees = TaxMarginFees(
        convenienceType: 'flat',
        convenienceValue: 99,
        platformType: 'percent',
        platformValue: 1,
        bookingMgmtType: 'percent',
        bookingMgmtValue: 0,
        slabs: [
          TaxMarginSlab(
            service: 'flights',
            minAmount: 20000,
            maxAmount: 50000,
            conveniencePercent: 0.5,
            platformPercent: 0.25,
            bookingMgmtPercent: 0.1,
          ),
        ],
      );
      final b = fees.compute(5000); // below slab range
      expect(b.convenienceFee, 99); // flat fallback
      expect(b.platformFee, 50); // 1% of 5000
    });

    test('slab for wrong service is ignored', () {
      final fees = TaxMarginFees(
        convenienceType: 'percent',
        convenienceValue: 2,
        platformType: 'percent',
        platformValue: 1,
        bookingMgmtType: 'percent',
        bookingMgmtValue: 0.5,
        slabs: [
          TaxMarginSlab(
            service: 'hotels', // not flights
            minAmount: 0,
            maxAmount: 100000,
            conveniencePercent: 99,
            platformPercent: 99,
            bookingMgmtPercent: 99,
          ),
        ],
      );
      final b = fees.compute(10000);
      expect(b.convenienceFee, 200); // percent fallback, not 99%
    });
  });

  group('TaxMarginSlab', () {
    test('fromJson parses correctly', () {
      final slab = TaxMarginSlab.fromJson({
        'service': 'flights',
        'min_amount': '5000',
        'max_amount': '20000',
        'convenience_percent': '1.5',
        'platform_percent': '0.75',
        'booking_mgmt_percent': '0.25',
      });
      expect(slab.service, 'flights');
      expect(slab.minAmount, 5000);
      expect(slab.maxAmount, 20000);
      expect(slab.conveniencePercent, 1.5);
      expect(slab.coversAmount(10000), true);
      expect(slab.coversAmount(3000), false);
      expect(slab.coversAmount(25000), false);
    });
  });

  group('TaxMarginBreakdown', () {
    test('total sums all fees', () {
      const b = TaxMarginBreakdown(
        convenienceFee: 100,
        platformFee: 50,
        bookingMgmtFee: 25,
      );
      expect(b.total, 175);
      expect(b.hasAnyFee, true);
    });

    test('empty breakdown', () {
      const b = TaxMarginBreakdown();
      expect(b.total, 0);
      expect(b.hasAnyFee, false);
    });
  });
}
