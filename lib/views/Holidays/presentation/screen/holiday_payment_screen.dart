import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../flight_payment/data/ccavenue_service.dart';
import '../../../flight_payment/presentation/screen/ccavenue_payment_page.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';
import 'holiday_booking_success_screen.dart';

const Color _kAccent = Color(0xffFF3B3B);
const Color _kInk = Color(0xff1A1A2E);

/// Lets the user pick a payment method (Wallet or CCAvenue) and pay for a
/// holiday package. CCAvenue is the same hosted-checkout WebView flow used
/// by Flight/Hotel/Transport/Visa; there is no holiday booking backend yet,
/// so a successful payment simply routes to a confirmation screen.
class HolidayPaymentScreen extends StatefulWidget {
  final String packageTitle;
  final String packageImage;
  final String packageLocation;
  final int travellersCount;

  /// Amount to actually charge via CCAvenue (always INR, 2 decimals).
  final double grandTotalInr;

  /// Pre-formatted strings (already converted to the user's preferred
  /// currency) for display only.
  final String baseTotalDisplay;
  final String gstDisplay;
  final String grandTotalDisplay;
  final double gstPercent;

  /// Optional prefill values (e.g. from a traveller-details step collected
  /// before this screen). When omitted, contact fields fall back to the
  /// saved profile, exactly as before.
  final String? prefillName;
  final String? prefillEmail;
  final String? prefillPhone;

  /// Package identifiers + trip facts needed to save the booking via
  /// POST /holidays/bookings once payment succeeds.
  final int packageInventoryId;
  final String packageSlug;
  final String city;
  final int nights;
  final int days;
  final Map<String, dynamic> packageSnapshot;

  /// The departure date picked on the holiday search card. Used as the
  /// booking's check-in date; falls back to today if never provided.
  final DateTime? departureDate;

  const HolidayPaymentScreen({
    super.key,
    required this.packageTitle,
    required this.packageImage,
    required this.packageLocation,
    required this.travellersCount,
    required this.grandTotalInr,
    required this.baseTotalDisplay,
    required this.gstDisplay,
    required this.grandTotalDisplay,
    required this.gstPercent,
    this.prefillName,
    this.prefillEmail,
    this.prefillPhone,
    this.packageInventoryId = 0,
    this.packageSlug = '',
    this.city = '',
    this.nights = 0,
    this.days = 0,
    this.packageSnapshot = const {},
    this.departureDate,
  });

  @override
  State<HolidayPaymentScreen> createState() => _HolidayPaymentScreenState();
}

class _HolidayPaymentScreenState extends State<HolidayPaymentScreen> {
  final CCAvenueService _ccavenueService = CCAvenueService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedMethod; // 'wallet' | 'ccavenue'
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillContactDetails();
  }

  void _prefillContactDetails() {
    // Prefer values already collected on the traveller-details step.
    if ((widget.prefillName ?? '').isNotEmpty) _nameController.text = widget.prefillName!;
    if ((widget.prefillEmail ?? '').isNotEmpty) _emailController.text = widget.prefillEmail!;
    if ((widget.prefillPhone ?? '').isNotEmpty) _phoneController.text = widget.prefillPhone!;
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      return;
    }

    try {
      final userData = di.sl<PreferencesManager>().getUserData();
      if (userData == null) return;
      if (_nameController.text.isEmpty) {
        _nameController.text = '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim();
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = (userData['email'] ?? '').toString();
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = (userData['phone_number'] ?? '').toString();
      }
    } catch (_) {
      // No saved user data yet — fields stay blank for manual entry.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _snack(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateContactDetails() {
    if (_nameController.text.trim().isEmpty) {
      _snack('Please enter your full name');
      return false;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _snack('Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      _snack('Please enter a valid phone number');
      return false;
    }
    return true;
  }

  Future<void> _payWithWallet() async {
    if (!di.sl<PreferencesManager>().isLoggedIn()) {
      _snack('Please log in to pay with your wallet.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final response = await di.sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (balance >= widget.grandTotalInr) {
        final reference = 'WNHL${DateTime.now().millisecondsSinceEpoch}';
        await _saveBookingToBackend(paymentReference: reference, paidVia: 'wallet');
      } else {
        _snack(
          'Insufficient wallet balance (${balance.toStringAsFixed(2)} available). '
          'Please choose CCAvenue.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not fetch wallet balance. Please try again.');
    }
  }

  Future<void> _payWithCCAvenue() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final orderId = '${DateTime.now().millisecondsSinceEpoch}';
      final amount = double.parse(widget.grandTotalInr.toStringAsFixed(2));
      final nameParts = _nameController.text.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      final session = await _ccavenueService.createCheckout(
        orderId: orderId,
        amount: amount,
        currency: 'INR',
        transactionType: 'holiday',
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: phone,
        successUrl: Urls.ccavenueSuccessUrl,
        failureUrl: Urls.ccavenueFailureUrl,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final result = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (_) => CCAvenuePaymentPage(
            service: _ccavenueService,
            session: session,
          ),
        ),
      );

      if (!mounted) return;
      switch (result) {
        case PaymentResult.success:
          await _saveBookingToBackend(paymentReference: session.orderId, paidVia: 'ccavenue');
          break;
        case PaymentResult.failure:
          _snack('Payment failed. Please try again.');
          break;
        case PaymentResult.cancelled:
        case null:
          _snack('Payment cancelled.', color: Colors.grey.shade700);
          break;
      }
    } on CCAvenueException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not start payment. Please try again.');
    }
  }

  /// Persists the booking via POST /holidays/bookings once money has
  /// actually moved (CCAvenue or wallet). If this fails, the payment itself
  /// has still succeeded, so we surface the reference for support instead of
  /// silently retrying the charge.
  Future<void> _saveBookingToBackend({
    required String paymentReference,
    required String paidVia,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final prefs = di.sl<PreferencesManager>();
      final userId = prefs.isLoggedIn() ? prefs.getUserId() : null;
      final referenceId = 'WNHL${DateTime.now().millisecondsSinceEpoch}';

      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.holidayBookings,
        data: {
          'reference_id': referenceId,
          'user': userId,
          'package_inventory_id': widget.packageInventoryId,
          'package_slug': widget.packageSlug,
          'package_name': widget.packageTitle,
          'city': widget.city,
          'check_in': _formatCheckInDate(widget.departureDate ?? DateTime.now()),
          'nights': widget.nights,
          'days': widget.days,
          'guests': widget.travellersCount,
          'grand_total': widget.grandTotalInr,
          'currency': 'INR',
          'traveler_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'paid_via': paidVia,
          'payment_reference': paymentReference,
          'checkout_id': '',
          'status': 'paid',
          'package_snapshot': widget.packageSnapshot,
          if (userId == null) 'guest_reference': 'GUEST${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      if (body['success'] == true) {
        _onPaymentSuccess(paymentReference);
      } else {
        _snack(
          'Payment succeeded but the booking could not be saved. '
          'Please contact support with reference: $paymentReference',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack(
        'Payment succeeded but the booking could not be saved. '
        'Please contact support with reference: $paymentReference',
      );
    }
  }

  String _formatCheckInDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _onPaymentSuccess(String reference) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HolidayBookingSuccessScreen(
          packageTitle: widget.packageTitle,
          packageLocation: widget.packageLocation,
          travellersCount: widget.travellersCount,
          amountPaidDisplay: widget.grandTotalDisplay,
          bookingReference: reference,
        ),
      ),
    );
  }

  void _pay() {
    if (!_validateContactDetails()) return;
    if (_selectedMethod == null) {
      _snack('Please select a payment method');
      return;
    }
    if (_selectedMethod == 'wallet') {
      _payWithWallet();
    } else {
      _payWithCCAvenue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'Payment',
          style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold, color: _kInk),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _kInk),
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackageSummaryCard(),
            SizedBox(height: context.gapLarge),
            _buildFareCard(),
            SizedBox(height: context.gapLarge),
            _buildContactCard(),
            SizedBox(height: context.gapLarge),
            _buildPaymentMethodCard(),
            if (_error != null) ...[
              SizedBox(height: context.gapMedium),
              _buildErrorBanner(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPackageSummaryCard() {
    return _card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(8)),
            child: widget.packageImage.isNotEmpty
                ? Image.network(
                    widget.packageImage,
                    width: context.w(56),
                    height: context.w(56),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: context.w(56),
                      height: context.w(56),
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image),
                    ),
                  )
                : Container(
                    width: context.w(56),
                    height: context.w(56),
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image),
                  ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.packageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: _kInk),
                ),
                if (widget.packageLocation.isNotEmpty) ...[
                  SizedBox(height: context.h(4)),
                  Text(
                    widget.packageLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
                  ),
                ],
                SizedBox(height: context.h(4)),
                Text(
                  '${widget.travellersCount} traveller${widget.travellersCount > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: context.fs(bold ? 13 : 12),
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? _kInk : Colors.grey.shade700,
              )),
          Text(value,
              style: TextStyle(
                fontSize: context.fs(bold ? 13 : 12),
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: bold ? _kAccent : Colors.black87,
              )),
        ],
      ),
    );
  }

  Widget _buildFareCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fare Details', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _kInk)),
          SizedBox(height: context.h(12)),
          _fareRow('Base price × ${widget.travellersCount} traveller${widget.travellersCount > 1 ? 's' : ''}',
              widget.baseTotalDisplay),
          if (widget.gstPercent > 0) _fareRow('GST (${widget.gstPercent.toStringAsFixed(0)}%)', widget.gstDisplay),
          Divider(height: context.h(20)),
          _fareRow('Total Amount', widget.grandTotalDisplay, bold: true),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Details', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _kInk)),
          SizedBox(height: context.h(12)),
          _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline),
          SizedBox(height: context.h(10)),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: context.h(10)),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: context.fs(13)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: context.fs(12)),
        prefixIcon: Icon(icon, size: context.iconSmall, color: Colors.grey.shade600),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(12)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(8)),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(8)),
          borderSide: const BorderSide(color: _kAccent),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Payment Method',
              style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _kInk)),
          SizedBox(height: context.h(12)),
          _buildMethodTile(
            value: 'wallet',
            icon: Icons.account_balance_wallet_outlined,
            title: 'My Wallet',
            subtitle: 'Pay using your wallet balance',
          ),
          SizedBox(height: context.h(8)),
          _buildMethodTile(
            value: 'ccavenue',
            icon: Icons.credit_card,
            title: 'CCAvenue',
            subtitle: 'Cards, UPI, Net Banking',
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: isSelected ? _kAccent.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(
            color: isSelected ? _kAccent : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.iconMedium, color: isSelected ? _kAccent : Colors.grey.shade600),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, size: context.iconMedium, color: _kAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: context.iconMedium),
          SizedBox(width: context.w(8)),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: context.fs(12)))),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: context.buttonHeight + 10,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
            ),
            child: _isProcessing
                ? SizedBox(
                    width: context.w(20),
                    height: context.w(20),
                    child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : Text(
                    'Pay ${widget.grandTotalDisplay}',
                    style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
