import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';

Future<void> _setUp({String currency = 'USD', Map<String, double>? rates}) async {
  SharedPreferences.setMockInitialValues({
    'preferred_currency': currency,
    if (rates != null) 'exchange_rates_cache': jsonEncode(rates),
  });
  if (sl.isRegistered<PreferencesManager>()) await sl.unregister<PreferencesManager>();
  sl.registerSingleton<PreferencesManager>(await PreferencesManager.create(await SharedPreferences.getInstance()));
}

void main() {
  test('converts INR to the chosen currency with USD-based rates', () async {
    await _setUp(rates: {'USD': 1, 'INR': 80, 'AED': 3.6725});
    await sl<PreferencesManager>().savePreferredCurrency('USD');
    expect(CurrencyConverter.display(8000), '\$100');
    expect(CurrencyConverter.display(400, toCurrency: 'USD'), '\$5');
    expect(CurrencyConverter.display(367.25, fromCurrency: 'AED', toCurrency: 'INR'), '₹8,000');
  });

  test('without rates the amount stays in its own currency', () async {
    await _setUp();
    expect(CurrencyConverter.canConvert('INR', 'USD'), isFalse);
    expect(CurrencyConverter.display(350, fromCurrency: 'AED', toCurrency: 'INR'), 'د.إ 350');
    expect(CurrencyConverter.display(1250, toCurrency: 'USD'), '₹1,250');
  });

  test('formats rupees with Indian grouping and small foreign amounts with cents', () async {
    await _setUp();
    expect(CurrencyConverter.format(1234567, 'INR'), '₹12,34,567');
    expect(CurrencyConverter.format(1234567, 'USD'), '\$1,234,567');
    expect(CurrencyConverter.format(4.5, 'USD'), '\$4.5');
    expect(CurrencyConverter.format(99.5, 'INR'), '₹100');
    expect(CurrencyConverter.getSymbol('SGD'), 'S\$');
    expect(CurrencyConverter.getSymbol('XYZ'), 'XYZ ');
  });
}
