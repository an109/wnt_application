import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../widgets/diy_common.dart';
import 'diy_enquiry_success_screen.dart';

/// Enquiry form — **API 15: POST /packages/{share_id}/enquiry/**.
///
/// `quoted_total` is sent as the exact string the customer was shown, so the
/// consultant picks up the same number. Note the enquiry is keyed on the
/// package's `share_id`, not the trip: [tripId] is only carried through for
/// the consultant's reference.
class DiyEnquiryScreen extends StatefulWidget {
  final String shareId;
  final DiySearchQuery query;
  final bool withFlight;
  final List<String> addOnIds;
  final double quotedTotal;
  final String currency;
  final String packageTitle;
  final String? tripId;

  const DiyEnquiryScreen({
    super.key,
    required this.shareId,
    required this.query,
    required this.withFlight,
    required this.addOnIds,
    required this.quotedTotal,
    required this.packageTitle,
    this.currency = 'INR',
    this.tripId,
  });

  @override
  State<DiyEnquiryScreen> createState() => _DiyEnquiryScreenState();
}

class _DiyEnquiryScreenState extends State<DiyEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  /// Saves the customer typing details the app already knows.
  void _prefillFromProfile() {
    try {
      final prefs = sl<PreferencesManager>();
      final user = prefs.getUserData();
      if (user == null) return;
      _name.text = (user['name'] ?? user['full_name'] ?? '').toString();
      _email.text = (user['email'] ?? '').toString();
      _phone.text = (user['phone'] ?? user['mobile'] ?? '').toString();
      setState(() {});
    } catch (_) {
      // Prefill is a convenience only — never block the form on it.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final date = widget.query.departureDate;
    if (date == null) {
      diySnack(context, 'Pick a starting date first', isError: true);
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await sl<DiyHolidayApi>().submitEnquiry(
        shareId: widget.shareId,
        customerName: _name.text.trim(),
        customerPhone: _phone.text.trim(),
        customerEmail: _email.text.trim(),
        departureDate: date,
        adults: widget.query.adults,
        children: widget.query.children,
        withFlight: widget.withFlight,
        addOnIds: widget.addOnIds,
        quotedTotal: widget.quotedTotal.toStringAsFixed(2),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiyEnquirySuccessScreen(
            reference: result.reference,
            message: result.message,
            packageTitle: widget.packageTitle,
            quotedTotal: widget.quotedTotal,
            currency: widget.currency,
          ),
        ),
      );
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: diyAppBar(context, title: 'Your details'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.w(14),
            context.h(14),
            context.w(14),
            context.h(24),
          ),
          children: [
            _summaryCard(),
            SizedBox(height: context.h(14)),
            _field(
              controller: _name,
              label: 'Full name',
              hint: 'Meera Rao',
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Please enter your name'
                  : null,
            ),
            _field(
              controller: _phone,
              label: 'Phone number',
              hint: '9812345678',
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 10 ? 'Enter a valid phone number' : null;
              },
            ),
            _field(
              controller: _email,
              label: 'Email',
              hint: 'meera@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                final ok = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value);
                return ok ? null : 'Enter a valid email address';
              },
            ),
            _field(
              controller: _message,
              label: 'Anything we should know? (optional)',
              hint: 'Sea facing room, late check-in…',
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          context.w(14),
          context.h(10),
          context.w(14),
          context.h(10) + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: DiyTokens.line)),
        ),
        child: DiyPrimaryButton(
          label: 'SEND ENQUIRY',
          busy: _sending,
          onPressed: _submit,
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final date = widget.query.departureDate;
    return DiyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.packageTitle,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            [
              if (date != null) diyFullDate(date),
              '${widget.query.adults} adult'
                  '${widget.query.adults == 1 ? '' : 's'}',
              if (widget.query.children > 0) '${widget.query.children} child',
              widget.withFlight ? 'with flight' : 'without flight',
              if (widget.addOnIds.isNotEmpty)
                '${widget.addOnIds.length} add-on'
                    '${widget.addOnIds.length == 1 ? '' : 's'}',
            ].join(' · '),
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(10)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quoted total',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ),
              Text(
                diyMoney(widget.quotedTotal, currency: widget.currency),
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w800,
                  color: DiyTokens.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(11.5),
              fontWeight: FontWeight.w600,
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(6)),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(fontSize: context.fs(14), color: DiyTokens.navy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: context.fs(13),
                color: DiyTokens.labelGrey,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: const BorderSide(color: DiyTokens.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: const BorderSide(color: DiyTokens.blue),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
