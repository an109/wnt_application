import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../UI_helper/navigation_queue.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../../login/presentation/screen/login.dart';
import '../../data/visa_draft_store.dart';
import '../../data/visa_form_data.dart';
import '../../data/visa_submit_service.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_checkout_sheets.dart';
import '../widgets/visa_flag.dart';
import 'visa_payment_screen.dart';
import 'visa_payment_success_screen.dart';

/// Checkout (Figma "Submit appli…" 2068:11243 with the insurance and visa
/// validity sheets).
class VisaCheckoutScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  final VisaTypeEntity visaType;
  final List<VisaTravellerForm> travellers;
  final VisaTripForm trip;

  /// Insurance days already chosen in the application flow.
  final int? insuranceDays;

  /// The application the documents step already saved, if there was one. The
  /// lead is in the CRM by then; checkout only has to collect the payment.
  final VisaCreatedApplication? created;

  /// Step header of the application flow; a plain "Checkout" bar otherwise.
  final Widget? header;

  const VisaCheckoutScreen({
    super.key,
    required this.destination,
    required this.visaType,
    required this.travellers,
    required this.trip,
    this.insuranceDays,
    this.created,
    this.header,
  });

  @override
  State<VisaCheckoutScreen> createState() => _VisaCheckoutScreenState();
}

class _VisaCheckoutScreenState extends State<VisaCheckoutScreen> {
  final _service = VisaSubmitService();

  late DateTime _validFrom;
  late final int _validityDays;
  int? _insuranceDays;
  bool _busy = false;
  VisaCreatedApplication? _created;

  /// The application is saved as soon as checkout opens, so the lead reaches
  /// the CRM and the mails go out even if the traveller never pays — the point
  /// the website creates it too. Guarded so editing the insurance or the
  /// validity afterwards does not keep adding records; that case falls back to
  /// creating at payment time, as before.
  bool _leadStarted = false;

  /// The save that is running, so paying waits for it instead of creating a
  /// second application.
  Future<void>? _leadInFlight;

  /// The coupon the server accepted for the saved application. It is reset
  /// whenever a change makes checkout save a fresh application.
  VisaPromoResult? _promo;
  bool _couponBusy = false;
  final _couponCtrl = TextEditingController();

  /// INR per unit of the visa fee currency; null until known. Payment stays
  /// blocked without it so a 350 AED fee is never charged as ₹350.
  double? _inrRate;
  bool _rateFailed = false;

  VisaPopularDestinationEntity get _d => widget.destination;
  VisaTypeEntity get _type => widget.visaType;
  int get _count => widget.travellers.length;
  String get _email => widget.trip.email.trim();

  double get _visaFeeInr => _type.feesInr.toDouble() * (_inrRate ?? 0);
  double get _insuranceInr => _insuranceDays == null
      ? 0
      : VisaInsurancePlan.perDayInr * _insuranceDays! * _count;
  double get _grossInr => _visaFeeInr * _count + _insuranceInr;
  double get _discountInr {
    final d = _promo?.discountInr ?? 0;
    return d > _grossInr ? _grossInr : d;
  }

  double get _totalInr => _grossInr - _discountInr;

  /// Checkout shows rupees: Razorpay charges INR.
  String _money(double inr) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(inr.round())}';

  Future<void> _loadRate() async {
    final currency = _type.feesCurrency.toUpperCase();
    if (_type.isFree || currency == 'INR') {
      setState(() => _inrRate = 1);
      return;
    }
    setState(() => _rateFailed = false);
    var rate = CurrencyConverter.convert(
      amount: 1,
      fromCurrency: currency,
      toCurrency: 'INR',
    );
    // Both converters return 1.0 when they have no rate.
    if (rate == 1)
      rate = await CurrencyService.instance.getRate(currency, 'INR');
    if (!mounted) return;
    setState(() {
      _inrRate = rate == 1 ? null : rate;
      _rateFailed = rate == 1;
    });
    _saveLead();
  }

  /// Creates the application behind the scenes once the total is known. It
  /// also uploads the scans and the documents picked on the Documents step.
  /// A failure is left silent: the traveller can still pay, and `_pay` tries
  /// again.
  void _saveLead() {
    if (_leadStarted || _created != null || _inrRate == null) return;
    if (!di.sl<PreferencesManager>().isLoggedIn()) return;
    if (_email.isEmpty) return;
    _leadStarted = true;
    _leadInFlight = _runSaveLead();
  }

  Future<void> _runSaveLead() async {
    await _submitEnquiry();
    try {
      final created = await _create();
      if (!mounted) return;
      setState(() => _created = created);
    } on VisaSubmitException {
      // Leave it to `_pay`, which reports the error to the traveller.
      _leadStarted = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _validFrom = widget.trip.arrivalDate ?? DateUtils.dateOnly(DateTime.now());
    _validityDays = visaValidityDays(
      _type.validity,
      fallback: visaValidityDays(_type.stay),
    );
    _insuranceDays = widget.insuranceDays;
    // Saved on the documents step: no second application, and the enquiry and
    // the documents went with it.
    _created = widget.created;
    if (_created != null) {
      _leadStarted = true;
      _enquirySent = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRate();
      final bloc = context.read<GeneralSettingsBloc>();
      if (bloc.state is! PromoCodesLoaded) bloc.add(const LoadPromoCodes());
    });
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  /// A new application is saved after an edit, and the coupon belonged to the
  /// old one, so it has to be applied again.
  void _dropPromo() {
    if (_promo == null) return;
    _promo = null;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _snack('Coupon removed because your order changed. Apply it again.'),
    );
  }

  Future<void> _applyCoupon(String raw) async {
    final code = raw.trim().toUpperCase();
    if (_couponBusy || _busy) return;
    if (code.isEmpty) {
      _snack('Enter a coupon code');
      return;
    }
    if (_inrRate == null) {
      _snack('Price is still loading. Try again in a moment.');
      return;
    }
    if (!di.sl<PreferencesManager>().isLoggedIn()) {
      _snack('Please sign in to apply a coupon.');
      return;
    }
    setState(() => _couponBusy = true);
    try {
      // The coupon lives on the saved application, so make sure it exists.
      await _leadInFlight;
      if (_created == null) {
        _leadStarted = true;
        _created = await _create();
      }
      final r = await _service.applyPromo(applicationId: _created!.id, email: _email, code: code);
      if (!mounted) return;
      setState(() {
        _promo = r;
        _couponCtrl.clear();
      });
      _snack('Coupon ${r.code} applied. You save ${_money(r.discountInr)}.');
    } on VisaSubmitException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _couponBusy = false);
    }
  }

  Future<void> _removeCoupon() async {
    if (_promo == null || _couponBusy || _busy) return;
    setState(() => _couponBusy = true);
    try {
      if (_created != null) {
        await _service.applyPromo(applicationId: _created!.id, email: _email, code: '');
      }
      if (mounted) setState(() => _promo = null);
    } on VisaSubmitException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _couponBusy = false);
    }
  }

  int get _tripDays {
    final a = widget.trip.arrivalDate, b = widget.trip.departureDate;
    if (a == null || b == null) return 7;
    return b.difference(a).inDays + 1;
  }

  Future<void> _openInsurance() async {
    final days = await showVisaSheet<int>(
      context,
      VisaInsuranceSheet(
        from: widget.trip.arrivalDate ?? DateTime.now(),
        initialDays: _insuranceDays ?? _tripDays,
      ),
    );
    // A changed total needs a fresh application record.
    if (days != null)
      setState(() {
        _insuranceDays = days;
        _created = null;
        _dropPromo();
      });
  }

  Future<void> _openValidity() async {
    final start = await showVisaSheet<DateTime>(
      context,
      VisaValiditySheet(start: _validFrom, days: _validityDays),
    );
    if (start != null)
      setState(() {
        _validFrom = start;
        _created = null;
        _dropPromo();
      });
  }

  // ---------------------------------------------------------------- submit

  Future<void> _pay() async {
    if (_busy || _inrRate == null) return;
    final prefs = di.sl<PreferencesManager>();
    if (!prefs.isLoggedIn()) {
      NavigationQueueService().setPendingNavigation(() {
        if (mounted) _pay();
      });
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const LoginSignupScreen(),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // A save started when checkout opened may still be running.
      await _leadInFlight;
      await _submitEnquiry();
      _created ??= await _create();
      if (_totalInr <= 0) {
        await _service.completePayment(
          applicationId: _created!.id,
          email: _email,
          reference: 'FREE-${DateTime.now().millisecondsSinceEpoch}',
          mode: 'free',
        );
        _done();
        return;
      }
      if (!mounted) return;
      setState(() => _busy = false);
      final count = widget.travellers.length;
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VisaPaymentScreen(
            applicationId: _created!.id,
            amountInr: double.parse(_totalInr.toStringAsFixed(2)),
            title: '${_d.shortName} ${_type.title}',
            subtitle: [
              if (widget.trip.arrivalDate != null)
                'Travel ${DateFormat('d MMM yyyy').format(widget.trip.arrivalDate!)}',
              if (_type.processing.isNotEmpty) 'Processing ${_type.processing}',
            ].join(' | '),
            image: _d.cardImage,
            travellersSummary:
                '$count traveller${count == 1 ? '' : 's'}'
                '${_insuranceDays != null ? ' · Travel insurance $_insuranceDays days' : ''}',
            email: _email,
            phone: widget.trip.phone.replaceAll(RegExp(r'[^0-9]'), ''),
          ),
        ),
      );
      if (paid == true && mounted) await _done();
    } on VisaSubmitException catch (e) {
      _snack(e.message);
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Visa enquiry, sent once per checkout before the application is created.
  bool _enquirySent = false;

  Future<void> _submitEnquiry() async {
    if (_enquirySent) return;
    _enquirySent = true;
    await _service.submitEnquiry(
      email: _email,
      contactNo: widget.trip.phone.replaceAll(RegExp(r'[^0-9+]'), ''),
      visaType: _type.title,
      travellers: '${widget.travellers.length}',
      destinationId: _d.id,
      attractionName: _d.shortName,
    );
  }

  Future<VisaCreatedApplication> _create() async {
    final created = await _service.create(
      destination: _d.name,
      visaTitle: _type.title,
      travellers: widget.travellers,
      trip: widget.trip,
      feePerTravellerInr: _visaFeeInr,
      totalInr: _totalInr,
      extraDetails: {
        'visa_category': _d.kindOf(_type).name,
        'fee_currency': _type.feesCurrency,
        'fee_amount': _type.feesInr.toString(),
        'inr_rate': _inrRate,
        'visa_valid_from': DateFormat('yyyy-MM-dd').format(_validFrom),
        'visa_valid_till': DateFormat(
          'yyyy-MM-dd',
        ).format(_validFrom.add(Duration(days: _validityDays - 1))),
        'length_of_stay': _type.stay,
        if (_insuranceDays != null)
          'insurance': {
            'plan': VisaInsurancePlan.title,
            'provider': VisaInsurancePlan.provider,
            'days': _insuranceDays,
            'travellers': _count,
            'amount_inr': _insuranceInr.toStringAsFixed(2),
          },
      },
    );
    final uploaded = await _service.uploadDocuments(
      created.id,
      _email,
      widget.travellers,
      documentLabels: {
        for (final doc in _d.requiredDocuments) doc.key: doc.label,
      },
    );
    if (!uploaded) {
      _snack(
        'Your documents could not be uploaded. Our team will collect them from you.',
      );
    }
    return created;
  }

  Future<void> _done() async {
    await VisaDraftStore.clear(_d.id);
    if (!mounted) return;
    setState(() => _busy = false);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VisaPaymentSuccessScreen(
          destination: _d,
          visaType: _type,
          travellers: widget.travellers,
          trip: widget.trip,
          totalInr: _totalInr,
          visaFeeInr: _visaFeeInr,
          insuranceInr: _insuranceInr,
          insuranceDays: _insuranceDays,
          bookingId: _created != null ? 'WNT-${_created!.id}' : '--',
          trackId: _created?.trackId,
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final processing = _type.parsedProcessing;
    final guaranteed = processing?.guaranteedFrom(DateTime.now());
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: widget.header != null
            ? null
            : AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: VisaColors.title),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                ),
                title: Text(
                  'Checkout',
                  style: visaText(
                    15,
                    weight: FontWeight.w600,
                    color: VisaColors.title,
                  ),
                ),
              ),
        body: SafeArea(
          bottom: false,
          top: widget.header != null,
          child: Column(
            children: [
              if (widget.header != null) widget.header!,
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _addOns(),
                    const SizedBox(height: 12),
                    _coupons(),
                    const SizedBox(height: 12),
                    _visaCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (guaranteed != null)
                // Container(
                //   width: double.infinity,
                //   color: VisaColors.primarySoft,
                //   padding: const EdgeInsets.symmetric(vertical: 7),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       // const Icon(
                //       //   Icons.verified,
                //       //   size: 12,
                //       //   color: VisaColors.primary,
                //       // ),
                //       // const SizedBox(width: 4),
                //       // Text(
                //       //   '${_d.shortName} visa guaranteed by ${DateFormat('d MMM, h:mm a').format(guaranteed)}',
                //       //   style: visaText(
                //       //     9,
                //       //     weight: FontWeight.w500,
                //       //     color: VisaColors.title,
                //       //   ),
                //       // ),
                //     ],
                //   ),
                // ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: _inrRate == null
                    ? VisaPrimaryButton(
                        label: _rateFailed
                            ? 'Price unavailable · retry'
                            : 'Fetching price',
                        loading: !_rateFailed,
                        onPressed: _rateFailed ? _loadRate : null,
                      )
                    : VisaPrimaryButton(
                        label: 'Pay ${_money(_totalInr)} & submit',
                        loading: _busy,
                        onPressed: _pay,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _insuranceDates() {
    final from = widget.trip.arrivalDate ?? DateUtils.dateOnly(DateTime.now());
    final until = from.add(Duration(days: _insuranceDays! - 1));
    final f = DateFormat('d MMM, yyyy');
    Widget col(String label, DateTime d, CrossAxisAlignment a) => Column(
      crossAxisAlignment: a,
      children: [
        Text(
          label,
          style: visaText(7.5, weight: FontWeight.w500, color: VisaColors.text),
        ),
        Text(
          f.format(d),
          style: visaText(
            10.5,
            weight: FontWeight.w600,
            color: VisaColors.title,
          ),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: VisaColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          col('FROM', from, CrossAxisAlignment.start),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFF5C9A8)),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: VisaColors.cta,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 12, color: Colors.white),
                ),
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFF5C9A8)),
                ),
              ],
            ),
          ),
          col('UNTIL', until, CrossAxisAlignment.end),
        ],
      ),
    );
  }

  Widget _addOns() {
    final added = _insuranceDays != null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Essential Add-Ons',
            style: visaText(
              11,
              weight: FontWeight.w600,
              color: VisaColors.title,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: added ? VisaColors.primarySoft : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: added ? VisaColors.primary : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, size: 22, color: VisaColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        VisaInsurancePlan.title,
                        style: visaText(
                          10.5,
                          weight: FontWeight.w600,
                          color: VisaColors.title,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openInsurance,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: added
                                    ? '$_insuranceDays days · $_count traveller${_count == 1 ? '' : 's'}  '
                                    : 'Medical, flight delays.  ',
                                style: visaText(8.5, color: VisaColors.text),
                              ),
                              TextSpan(
                                text: added ? 'edit' : 'more',
                                style: visaText(
                                  8.5,
                                  weight: FontWeight.w600,
                                  color: VisaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _busy
                          ? null
                          : added
                          ? () => setState(() {
                              _insuranceDays = null;
                              _created = null;
                              _dropPromo();
                            })
                          : _openInsurance,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: added ? Colors.white : VisaColors.primary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: VisaColors.primary),
                        ),
                        child: Icon(
                          added ? Icons.delete_outline : Icons.add,
                          size: 14,
                          color: added ? VisaColors.red : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(
                        VisaInsurancePlan.perDayInr *
                            (_insuranceDays ?? _tripDays) *
                            _count,
                      ),
                      style: visaText(
                        11,
                        weight: FontWeight.w700,
                        color: VisaColors.title,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (added) _insuranceDates(),
        ],
      ),
    );
  }

  /// Offers the admin tagged for Visa (or for everything), once each.
  List<PromoCodeEntity> _offers(GeneralSettingsState state) {
    if (state is! PromoCodesLoaded) return const [];
    final seen = <String>{};
    return state.promoCodes.where((p) {
      final cat = p.category.trim().toLowerCase();
      final code = p.code.trim().toUpperCase();
      return (cat == 'visa' || cat == 'all') && code.isNotEmpty && seen.add(code);
    }).toList();
  }

  Widget _coupons() {
    final applied = _promo;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 14, color: VisaColors.primary),
              const SizedBox(width: 6),
              Text('Coupons', style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
            ],
          ),
          const SizedBox(height: 10),
          if (applied != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VisaColors.greenSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: VisaColors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: VisaColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(applied.code, style: visaText(11, weight: FontWeight.w700, color: VisaColors.title)),
                        Text(
                          'You save ${_money(_discountInr)}',
                          style: visaText(9, weight: FontWeight.w500, color: VisaColors.green),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _couponBusy ? null : _removeCoupon,
                    child: Text('Remove', style: visaText(10, weight: FontWeight.w600, color: VisaColors.red)),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _couponCtrl,
                      enabled: !_couponBusy,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _applyCoupon,
                      style: visaText(11, weight: FontWeight.w600, color: VisaColors.title),
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: visaText(10.5, color: VisaColors.text),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: VisaColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: _couponBusy ? null : () => _applyCoupon(_couponCtrl.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: VisaColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _couponBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Apply', style: visaText(11, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
            BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
              builder: (context, state) {
                final offers = _offers(state);
                if (offers.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text('Available offers', style: visaText(9, weight: FontWeight.w600, color: VisaColors.text)),
                    const SizedBox(height: 6),
                    for (final p in offers.take(4))
                      _offerTile(p),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _offerTile(PromoCodeEntity p) {
    final eligible = _grossInr > 0 && p.isEligibleFor(_grossInr);
    final value = p.discountType == 'percent' ? '${p.discountValue}% off' : '₹${p.discountValue} off';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: VisaColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.code} · $value',
                  style: visaText(10.5, weight: FontWeight.w700, color: VisaColors.title),
                ),
                if (p.description.isNotEmpty)
                  Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: visaText(8.5, color: VisaColors.text)),
                if (!eligible && p.minPurchase > 0)
                  Text(p.minPurchaseHint, style: visaText(8.5, color: VisaColors.red)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: (_couponBusy || !eligible) ? null : () => _applyCoupon(p.code),
            child: Text(
              'Apply',
              style: visaText(
                10.5,
                weight: FontWeight.w700,
                color: eligible ? VisaColors.primary : VisaColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visaCard() {
    final validTill = _validFrom.add(Duration(days: _validityDays - 1));
    final adults = '$_count Adult${_count == 1 ? '' : 's'}';
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                VisaFlag(countryCode: _d.countryCode, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_d.shortName} ${_type.isFree ? 'Entry Form' : 'Visa'}',
                    style: visaText(
                      12,
                      weight: FontWeight.w600,
                      color: VisaColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: VisaColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              children: [
                _row(
                  Icons.schedule,
                  'Length of Stay',
                  Text(_type.stay.isEmpty ? '—' : _type.stay, style: _value),
                ),
                _row(
                  Icons.event_available_outlined,
                  'Visa Validity',
                  GestureDetector(
                    onTap: _openValidity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${visaShortDateFormat.format(_validFrom)} - ${visaShortDateFormat.format(validTill)}',
                          style: _value,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 12,
                          color: VisaColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                _row(
                  Icons.people_outline,
                  'Travelers',
                  Text(adults, style: _value),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: VisaColors.divider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'PRICE BREAKDOWN',
                      style: visaText(
                        8.5,
                        weight: FontWeight.w600,
                        color: VisaColors.text,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.auto_awesome,
                      size: 11,
                      color: VisaColors.green,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Zero Surcharges',
                      style: visaText(
                        8.5,
                        weight: FontWeight.w600,
                        color: VisaColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _priceRow(
                  _type.isFree
                      ? 'Govt. Visa Fee (Exemption Waiver)'
                      : 'Govt. Visa Fee × $_count',
                  _type.isFree ? 'FREE' : _money(_visaFeeInr * _count),
                  free: _type.isFree,
                ),
                _priceRow('WNTProtect™ Full Guarantee', 'FREE', free: true),
                if (_insuranceDays != null)
                  _priceRow(
                    'Travel insurance · $_insuranceDays days',
                    _money(_insuranceInr),
                  ),
                if (_promo != null)
                  _priceRow(
                    'Coupon ${_promo!.code}',
                    '− ${_money(_discountInr)}',
                    free: true,
                  ),
                const Divider(height: 18, color: VisaColors.divider),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Payable',
                            style: visaText(
                              12,
                              weight: FontWeight.w700,
                              color: VisaColors.title,
                            ),
                          ),
                          Text(
                            'Includes all GST, taxes & consular fees',
                            style: visaText(7.5, color: VisaColors.text),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money(_totalInr),
                      style: visaText(
                        16,
                        weight: FontWeight.w800,
                        color: VisaColors.title,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _value =>
      visaText(10, weight: FontWeight.w600, color: VisaColors.title);

  Widget _row(IconData icon, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 13, color: VisaColors.text),
          const SizedBox(width: 6),
          Text(label, style: visaText(10, color: VisaColors.text)),
          const Spacer(),
          value,
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool free = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: visaText(9.5, color: VisaColors.text)),
          ),
          Text(
            value,
            style: visaText(
              10,
              weight: FontWeight.w600,
              color: free ? VisaColors.green : VisaColors.title,
            ),
          ),
        ],
      ),
    );
  }
}
