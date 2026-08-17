import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../core/constants/urls.dart';
import '../../core/error/data_state.dart';
import '../../core/network/dio_client.dart';
import '../../injection_container.dart' as di;
import '../AKInsurance/domain/entity/AKInsurance_entity.dart';
import '../AKInsurance/domain/usecase/AKInsurance_usecase.dart';
import '../countries/domain/entities/country_entity.dart';
import '../countries/presentation/bloc/country_bloc.dart';
import '../countries/presentation/bloc/country_state.dart';
import '../wallet/data/data_source/wallet_api_service.dart';
import 'insurance_models.dart';

/// Proposer details collected on [InsuranceBookingScreen] and carried over
/// read-only to this screen — no re-entry, no re-validation here.
class InsuranceProposerInfo {
  final String mobile;
  final String email;
  final String addr1;
  final String addr2;
  final String state;
  final String city;
  final String district;
  final String pincode;
  final String gst;
  final String pan;

  const InsuranceProposerInfo({
    required this.mobile,
    required this.email,
    required this.addr1,
    required this.addr2,
    required this.state,
    required this.city,
    required this.district,
    required this.pincode,
    required this.gst,
    required this.pan,
  });
}

/// One traveller's details collected on [InsuranceBookingScreen].
class InsuranceTravellerInfo {
  final String title;
  final String gender;
  final String firstName;
  final String lastName;
  final DateTime? dob;
  final String passport;
  final String relationship;
  final String nationality;

  const InsuranceTravellerInfo({
    required this.title,
    required this.gender,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.passport,
    required this.relationship,
    required this.nationality,
  });
}

/// Review + payment screen: shows back the details entered on
/// [InsuranceBookingScreen] (read-only) and, below that, the Wallet/Razorpay
/// picker. StartPay (step 6/7) only runs once a charge actually clears here —
/// ValidateKYC (step 5/7) is intentionally not called anywhere in this flow.
class InsurancePaymentScreen extends StatefulWidget {
  final InsuranceQuoteRequest request;
  final InsurancePolicy policy;
  final String tui;
  final InsuranceProposerInfo proposer;
  final List<InsuranceTravellerInfo> travellers;
  final String nomineeFirst;
  final String nomineeLast;
  final String nomineeRelation;
  final int totalAmount;

  const InsurancePaymentScreen({
    super.key,
    required this.request,
    required this.policy,
    required this.tui,
    required this.proposer,
    required this.travellers,
    required this.nomineeFirst,
    required this.nomineeLast,
    required this.nomineeRelation,
    required this.totalAmount,
  });

  @override
  State<InsurancePaymentScreen> createState() => _InsurancePaymentScreenState();
}

class _InsurancePaymentScreenState extends State<InsurancePaymentScreen> {
  static const Color _brandBlue = Color(0xFF003B95);
  static const Color _accentOrange = Color(0xFFE23A1E);

  late final Razorpay _razorpay;
  bool _isProcessing = false;
  String? _selectedMethod; // 'wallet' | 'razorpay'
  String _reference = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    final df = DateFormat('dd MMM yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: _brandBlue),
        title: Text(
          'Review & Pay',
          style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                context,
                title: 'Policy',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.policy.planName,
                        style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: Colors.black87)),
                    SizedBox(height: context.h(4)),
                    Text(
                      '${df.format(widget.request.startDate)} - ${df.format(widget.request.endDate)} · ${widget.request.destination}',
                      style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),
              _card(
                context,
                title: 'Proposer Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Mobile', widget.proposer.mobile),
                    _kv(context, 'Email', widget.proposer.email),
                    _kv(context, 'Address',
                        [widget.proposer.addr1, widget.proposer.addr2].where((s) => s.isNotEmpty).join(', ')),
                    _kv(context, 'City / State',
                        '${widget.proposer.city}${widget.proposer.state.isNotEmpty ? ', ${widget.proposer.state}' : ''}'),
                    _kv(context, 'Pincode', widget.proposer.pincode),
                    if (widget.proposer.pan.isNotEmpty) _kv(context, 'PAN', widget.proposer.pan),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),
              for (int i = 0; i < widget.travellers.length; i++) ...[
                _card(
                  context,
                  title: 'Traveller ${i + 1}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv(context, 'Name',
                          '${widget.travellers[i].title} ${widget.travellers[i].firstName} ${widget.travellers[i].lastName}'),
                      _kv(context, 'DOB',
                          widget.travellers[i].dob != null ? df.format(widget.travellers[i].dob!) : '—'),
                      _kv(context, 'Relationship', widget.travellers[i].relationship),
                      _kv(context, 'Passport', widget.travellers[i].passport),
                    ],
                  ),
                ),
                SizedBox(height: context.h(12)),
              ],
              _card(
                context,
                title: 'Nominee',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Name', '${widget.nomineeFirst} ${widget.nomineeLast}'),
                    _kv(context, 'Relationship', widget.nomineeRelation),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),
              _card(
                context,
                title: 'Fare Summary',
                child: Row(
                  children: [
                    Text('Total Premium',
                        style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: Colors.black87)),
                    const Spacer(),
                    Text('₹${numberFormat.format(widget.totalAmount)}',
                        style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _accentOrange)),
                  ],
                ),
              ),
              SizedBox(height: context.h(16)),
              Text('Choose Payment Method',
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: Colors.black87)),
              SizedBox(height: context.h(10)),
              _paymentMethodTile(
                context,
                value: 'wallet',
                icon: Icons.account_balance_wallet_outlined,
                title: 'My Wallet',
                subtitle: 'Pay using your wallet balance',
              ),
              SizedBox(height: context.h(8)),
              _paymentMethodTile(
                context,
                value: 'razorpay',
                icon: Icons.payment,
                title: 'Razorpay',
                subtitle: 'Cards, UPI, Net Banking, Wallets',
              ),
              SizedBox(height: context.h(20)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isProcessing || _selectedMethod == null) ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentOrange,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: context.h(14)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          width: context.w(20),
                          height: context.w(20),
                          child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text(
                          _selectedMethod == null ? 'SELECT A PAYMENT METHOD' : 'PAY ₹${numberFormat.format(widget.totalAmount)}',
                          style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              SizedBox(height: context.h(12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _brandBlue)),
          SizedBox(height: context.h(8)),
          child,
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.w(90),
            child: Text(label, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(
      BuildContext context, {
        required String value,
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: _isProcessing ? null : () => setState(() => _selectedMethod = value),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: isSelected ? _brandBlue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: isSelected ? _brandBlue : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.iconMedium, color: isSelected ? _brandBlue : Colors.grey.shade600),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: context.fs(10.5), color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, size: context.iconMedium, color: _brandBlue),
          ],
        ),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (_selectedMethod == 'wallet') {
      await _payWithWallet();
    } else {
      await _createRazorpayOrder();
    }
  }

  /// Checks the wallet balance client-side and, if sufficient, treats it as
  /// paid and proceeds straight to StartPay (there is no wallet-debit
  /// endpoint yet — same known gap as Hotel/Visa checkout).
  Future<void> _payWithWallet() async {
    setState(() => _isProcessing = true);
    try {
      final response = await di.sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;

      if (balance < widget.totalAmount) {
        setState(() => _isProcessing = false);
        _snack('Insufficient wallet balance (₹${balance.toStringAsFixed(2)} available). '
            'Please choose Razorpay.');
        return;
      }

      final walletReference = 'WALLET${DateTime.now().millisecondsSinceEpoch}';
      final issued = await _issueInsurancePolicy(gateway: 'wallet', paymentReference: walletReference);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (issued != null) {
        _showSuccessDialog(issued);
      } else {
        _snack('Payment received, but the policy could not be issued yet. '
            'Please contact support with reference: $walletReference');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not fetch wallet balance. Please try again.');
    }
  }

  Future<void> _createRazorpayOrder() async {
    setState(() => _isProcessing = true);
    try {
      final dio = di.sl<DioClient>().instance;
      final reference = 'insurance-${DateTime.now().millisecondsSinceEpoch}';
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'reference_id': reference,
          'amount': widget.totalAmount,
          'currency': 'INR',
          'transaction_type': 'insurance',
        },
      );

      final orderId = response.data['order_id'] as String?;
      final keyId = response.data['key_id'] as String?;

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _reference = reference;
      });

      _razorpay.open({
        'key': keyId ?? '',
        'amount': widget.totalAmount * 100,
        'currency': 'INR',
        'name': 'WanderNova',
        'description': '${widget.policy.planName} — Travel Insurance',
        'order_id': orderId ?? '',
        'prefill': {
          'contact': widget.proposer.mobile,
          'email': widget.proposer.email,
        },
        'theme': {'color': '#E23A1E'},
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not create payment order. Please try again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not start payment. Please try again.');
    }
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final dio = di.sl<DioClient>().instance;
      final verify = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'reference_id': _reference,
        },
      );
      if (verify.data['success'] != true) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _snack('Payment could not be verified. If money was deducted, contact '
            'support with reference: ${response.paymentId ?? _reference}');
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Payment could not be verified. If money was deducted, contact '
          'support with reference: ${response.paymentId ?? _reference}');
      return;
    }

    // StartPay's payment guard looks up the payment by the SAME reference_id
    // that was sent to create-order/verify above — not Razorpay's own
    // payment id — so that exact value must be echoed back here.
    final issued = await _issueInsurancePolicy(gateway: 'razorpay', paymentReference: _reference);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (issued != null) {
      _showSuccessDialog(issued);
    } else {
      _snack('Payment received, but the policy could not be issued yet. '
          'Please contact support with reference: ${response.paymentId ?? _reference}');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack('Payment failed: ${response.message ?? 'Please try again.'}');
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {}

  /// Runs StartPay (step 6/7, retried while the provider reports
  /// `bookingInProgress`) then GetItinerary (step 7/7). Returns the issued
  /// transaction id, or null if issuance failed — the caller decides how to
  /// message that against an already-collected payment. ValidateKYC (step
  /// 5/7) is intentionally not called anywhere in this flow.
  Future<String?> _issueInsurancePolicy({
    required String gateway,
    required String paymentReference,
  }) async {
    final lead = widget.travellers.first;
    final countryState = context.read<CountryBloc>().state;
    final countries = countryState is CountryLoaded ? countryState.countries : const <CountryEntity>[];
    final countryCodes = widget.request.travellingCountries.map((name) {
      final matches = countries.where((c) => c.name == name);
      return matches.isNotEmpty ? matches.first.code : '';
    }).toList();
    // The API doc's example StartDate/EndDate/BirthDate are full ISO
    // datetimes at midnight ("2026-08-20T00:00:00"). widget.request.startDate
    // defaults to DateTime.now() on the search form when the user doesn't
    // explicitly re-pick it, which was leaking the actual current
    // time-of-day into StartDate instead of midnight — dateOnly() strips
    // that regardless of what time the source DateTime carries.
    final dateTimeFmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    String dateOnly(DateTime d) => dateTimeFmt.format(DateTime(d.year, d.month, d.day));

    // Reused on every traveller too — the booking form only collects one
    // contact number/email/address (the proposer's), not one per traveller.
    final proposerContact = AkInsuranceContactInfoEntity(
      number: widget.proposer.mobile,
      code: '+91',
      emailAddress: widget.proposer.email,
    );
    final proposerAddress = AkInsuranceAddressEntity(
      line1: widget.proposer.addr1.isEmpty ? 'NA' : widget.proposer.addr1,
      pinCode: widget.proposer.pincode.isEmpty ? '000000' : widget.proposer.pincode,
      cityName: widget.proposer.city,
      stateName: widget.proposer.state,
    );

    final request = AkInsuranceStartPayRequestEntity(
      paymentReference: paymentReference,
      gateway: gateway,
      panNo: widget.proposer.pan,
      countryCodes: countryCodes,
      countryNames: widget.request.travellingCountries,
      startDate: dateOnly(widget.request.startDate),
      endDate: dateOnly(widget.request.endDate),
      // Title case ("Individual"), matching the doc's own example and
      // Plans[].Type below — was uppercased ("INDIVIDUAL") inconsistently.
      policyType: widget.request.insuranceType,
      customer: AkInsuranceCustomerEntity(
        title: lead.title,
        firstName: lead.firstName,
        lastName: lead.lastName,
        birthDate: lead.dob != null ? dateOnly(lead.dob!) : '',
        contactInfo: proposerContact,
        addresses: [proposerAddress],
        gstin: widget.proposer.gst,
      ),
      plans: [
        AkInsurancePlanBookingEntity(
          id: widget.policy.planId,
          type: widget.request.insuranceType,
          travellers: [
            for (int i = 0; i < widget.travellers.length; i++)
              AkInsuranceBookingTravellerEntity(
                id: i,
                title: widget.travellers[i].title,
                firstName: widget.travellers[i].firstName,
                lastName: widget.travellers[i].lastName,
                birthDate: widget.travellers[i].dob != null
                    ? dateOnly(widget.travellers[i].dob!)
                    : '',
                passportNumber: widget.travellers[i].passport,
                gender: widget.travellers[i].gender,
                relationship: widget.travellers[i].relationship.toUpperCase(),
                isProposer: i == 0,
                // Same nominee applies to every traveller — the booking form
                // only collects one. Required by Benzy's schema; omitting it
                // (along with QuestionsAnswers below) is what was crashing
                // StartPay with a 500/502 upstream.
                nominee: AkInsuranceNomineeEntity(
                  firstName: widget.nomineeFirst,
                  lastName: widget.nomineeLast,
                  relation: widget.nomineeRelation,
                ),
                questionsAnswers: const [AkInsuranceQuestionAnswerEntity.defaultPed],
                addresses: [proposerAddress],
                contactInfo: proposerContact,
              ),
          ],
        ),
      ],
      amount: widget.totalAmount,
      onlinePayment: false,
      depositPayment: true,
      tui: widget.tui,
    );

    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 4);
    var attempt = 0;

    while (attempt < maxAttempts) {
      final result = await di.sl<AkInsuranceStartPayUseCase>().call(request);
      if (result is! DataSuccess<AkInsuranceStartPayEntity>) return null;

      final data = result.data!;
      if (data.isBooked) {
        // Best-effort confirmation fetch — the policy is already issued
        // either way, so a failure here doesn't flip the outcome to null.
        await di.sl<AkInsuranceGetItineraryUseCase>().call(
          AkInsuranceItineraryRequestEntity(tui: widget.tui, transactionId: data.transactionId),
        );
        return data.transactionId;
      }
      if (data.bookingInProgress) {
        attempt++;
        await Future.delayed(retryDelay);
        continue;
      }
      return null;
    }
    return null;
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(16))),
        icon: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: context.w(48)),
        title: Text('Policy Issued',
            textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: context.fs(18))),
        content: Text(
          'Your travel insurance policy has been booked.\nReference: $transactionId',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade700),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('DONE', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
