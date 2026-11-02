import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/MainApi/data/models/general_settings_model.dart';
import 'package:wander_nova/views/MainApi/domain/entities/general_setting_entity.dart';

PromoCodeEntity promo(Map<String, dynamic> extra) => PromoCodeModel.fromJson({
      'code': 'SAVE10',
      'category': 'flight_booking',
      'discount_type': 'percent',
      'discount_value': '10.00',
      'description': '',
      ...extra,
    }).toEntity();

void main() {
  group('min purchase parsing', () {
    test('reads the admin value, with or without commas', () {
      expect(promo({'min_purchase': '50000.00'}).minPurchase, 50000);
      expect(promo({'min_purchase': '1,50,000'}).minPurchase, 150000);
      expect(promo({'minPurchase': '2500'}).minPurchase, 2500);
    });

    test('null, empty or junk means no minimum', () {
      expect(promo({'min_purchase': null}).minPurchase, 0);
      expect(promo({'min_purchase': ''}).minPurchase, 0);
      expect(promo({'min_purchase': 'abc'}).minPurchase, 0);
      expect(promo({}).minPurchase, 0);
    });
  });

  group('eligibility', () {
    test('no minimum → always eligible, even with a zero amount', () {
      final p = promo({'min_purchase': null});
      expect(p.isEligibleFor(0), isTrue);
      expect(p.isEligibleFor(1), isTrue);
    });

    test('the minimum itself qualifies; one rupee under does not', () {
      final p = promo({'min_purchase': '5000'});
      expect(p.isEligibleFor(5000), isTrue);
      expect(p.isEligibleFor(4999.99), isFalse);
      expect(p.isEligibleFor(12000), isTrue);
    });

    test('an unknown amount (0) fails closed when a minimum exists', () {
      expect(promo({'min_purchase': '5000'}).isEligibleFor(0), isFalse);
    });
  });

  group('hint text', () {
    test('uses Indian digit grouping and drops empty paise', () {
      expect(promo({'min_purchase': '5000'}).minPurchaseHint,
          'Applicable on bookings of ₹5,000 or more');
      expect(promo({'min_purchase': '150000'}).minPurchaseHint,
          'Applicable on bookings of ₹1,50,000 or more');
      expect(promo({'min_purchase': '999'}).minPurchaseHint,
          'Applicable on bookings of ₹999 or more');
      expect(promo({'min_purchase': '2500.50'}).minPurchaseHint,
          'Applicable on bookings of ₹2,500.50 or more');
    });
  });
}
