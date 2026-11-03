import '../../../UI_helper/currency_converter.dart';
import '../../../core/services/currency_service.dart';
import '../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../presentation/utils/visa_rules.dart';
import '../presentation/widgets/visa_checkout_sheets.dart';

/// What a visa costs in rupees. The fee is quoted in the destination's own
/// currency, so everything that charges or records a total needs this rate
/// first — a 350 AED fee must never be saved or charged as ₹350.
class VisaPricing {
  VisaPricing._();

  /// INR per unit of the fee currency, or null when no rate is available.
  static Future<double?> inrRate(VisaTypeEntity type) async {
    final currency = type.feesCurrency.toUpperCase();
    if (type.isFree || currency == 'INR') return 1;
    var rate = CurrencyConverter.convert(
      amount: 1,
      fromCurrency: currency,
      toCurrency: 'INR',
    );
    // Both converters return 1.0 when they have no rate.
    if (rate == 1) rate = await CurrencyService.instance.getRate(currency, 'INR');
    return rate == 1 ? null : rate;
  }

  /// Visa fee for one traveller.
  static double feeInr(VisaTypeEntity type, double rate) => type.feesInr.toDouble() * rate;

  /// Insurance for the whole party, or 0 when it was not added.
  static double insuranceInr(int? days, int travellers) =>
      days == null ? 0 : VisaInsurancePlan.perDayInr * days * travellers;

  /// What the traveller pays: the visa fee for everyone, plus insurance.
  static double totalInr(VisaTypeEntity type, double rate, int travellers, int? insuranceDays) =>
      feeInr(type, rate) * travellers + insuranceInr(insuranceDays, travellers);
}
