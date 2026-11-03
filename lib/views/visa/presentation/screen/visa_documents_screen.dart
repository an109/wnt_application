import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/navigation_queue.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../../login/presentation/screen/login.dart';
import '../../data/visa_form_data.dart';
import '../../data/visa_pricing.dart';
import '../../data/visa_submit_service.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_checkout_sheets.dart';
import '../widgets/visa_documents_step.dart';

/// What the documents step hands back when the traveller continues: the
/// application it saved, or null when saving did not get through. Popping
/// without this (the back arrow) means they stayed behind.
class VisaDocumentsOutcome {
  final VisaCreatedApplication? created;
  const VisaDocumentsOutcome(this.created);
}

/// Documents step, between the traveller details and the payment.
///
/// Opening it saves the application, which is what puts the visa lead in the
/// CRM and sends the confirmation mails — the same point the website creates
/// it (its step 1 posts `/api/visa-applications/` and then moves to the upload
/// step). Payment comes later, so a traveller who stops here is still a lead.
/// Pops the created application, or null when nothing was saved.
class VisaDocumentsScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  final VisaTypeEntity visaType;
  final List<VisaTravellerForm> travellers;
  final VisaTripForm trip;

  /// Insurance days already chosen, or null when it was declined.
  final int? insuranceDays;

  /// Visa validity start, when the flow let the traveller pick one.
  final DateTime? validFrom;

  /// Step header of the application flow; a plain bar otherwise.
  final Widget? header;

  /// Called when a file is attached or removed, so a host screen can save
  /// its draft.
  final VoidCallback? onChanged;

  const VisaDocumentsScreen({
    super.key,
    required this.destination,
    required this.visaType,
    required this.travellers,
    required this.trip,
    this.insuranceDays,
    this.validFrom,
    this.header,
    this.onChanged,
  });

  @override
  State<VisaDocumentsScreen> createState() => _VisaDocumentsScreenState();
}

class _VisaDocumentsScreenState extends State<VisaDocumentsScreen> {
  final _service = VisaSubmitService();

  VisaCreatedApplication? _created;
  bool _saving = false;
  bool _uploading = false;

  VisaPopularDestinationEntity get _d => widget.destination;
  VisaTypeEntity get _type => widget.visaType;
  int get _count => widget.travellers.length;
  String get _email => widget.trip.email.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveApplication());
  }

  // ------------------------------------------------------------ the lead

  /// Saves the application as soon as this step opens. Without it the
  /// traveller would only become a lead once they paid.
  Future<void> _saveApplication() async {
    if (_created != null || _saving) return;
    if (!di.sl<PreferencesManager>().isLoggedIn()) {
      NavigationQueueService().setPendingNavigation(() {
        if (mounted) _saveApplication();
      });
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const LoginSignupScreen(),
      );
      return;
    }
    if (_email.isEmpty) return;

    setState(() => _saving = true);
    try {
      final rate = await VisaPricing.inrRate(_type);
      if (!mounted) return;
      if (rate == null) {
        // Saving a total in the wrong currency is worse than saving nothing;
        // checkout retries once it has a rate.
        setState(() => _saving = false);
        return;
      }
      // The enquiry the website sends too, before the application itself.
      await _service.submitEnquiry(
        email: _email,
        contactNo: widget.trip.phone.replaceAll(RegExp(r'[^0-9+]'), ''),
        visaType: _type.title,
        travellers: '$_count',
        destinationId: _d.id,
        attractionName: _d.shortName,
      );
      final created = await _service.create(
        destination: _d.name,
        visaTitle: _type.title,
        travellers: widget.travellers,
        trip: widget.trip,
        feePerTravellerInr: VisaPricing.feeInr(_type, rate),
        totalInr: VisaPricing.totalInr(_type, rate, _count, widget.insuranceDays),
        extraDetails: _extraDetails(rate),
      );
      if (!mounted) return;
      setState(() {
        _created = created;
        _saving = false;
      });
    } on VisaSubmitException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.message);
    }
  }

  Map<String, dynamic> _extraDetails(double rate) {
    final validFrom = widget.validFrom ??
        widget.trip.arrivalDate ??
        DateUtils.dateOnly(DateTime.now());
    final validityDays = visaValidityDays(
      _type.validity,
      fallback: visaValidityDays(_type.stay),
    );
    final iso = DateFormat('yyyy-MM-dd');
    return {
      'visa_category': _d.kindOf(_type).name,
      'fee_currency': _type.feesCurrency,
      'fee_amount': _type.feesInr.toString(),
      'inr_rate': rate,
      'visa_valid_from': iso.format(validFrom),
      'visa_valid_till': iso.format(validFrom.add(Duration(days: validityDays - 1))),
      'length_of_stay': _type.stay,
      'documents_step': true,
      if (widget.insuranceDays != null)
        'insurance': {
          'plan': VisaInsurancePlan.title,
          'provider': VisaInsurancePlan.provider,
          'days': widget.insuranceDays,
          'travellers': _count,
          'amount_inr':
              VisaPricing.insuranceInr(widget.insuranceDays, _count).toStringAsFixed(2),
        },
    };
  }

  // ------------------------------------------------------------ continue

  Future<void> _continue() async {
    if (_saving || _uploading) return;
    final missing = VisaDocumentsStep.missing(_d, widget.travellers);
    if (missing != null) {
      _snack(missing);
      return;
    }
    // Saving may have been skipped (not signed in yet, no rate); try once more
    // so the documents have an application to go to.
    if (_created == null) await _saveApplication();
    if (!mounted) return;
    final created = _created;
    if (created == null) {
      // Checkout creates the application and uploads everything again, so the
      // traveller is not stuck here.
      Navigator.pop(context, const VisaDocumentsOutcome(null));
      return;
    }

    setState(() => _uploading = true);
    final uploaded = await _service.uploadDocuments(
      created.id,
      _email,
      widget.travellers,
      documentLabels: {for (final doc in _d.requiredDocuments) doc.key: doc.label},
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (!uploaded) {
      _snack('Your documents could not be uploaded. Our team will collect them from you.');
    }
    Navigator.pop(context, VisaDocumentsOutcome(created));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.header != null
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: VisaColors.title),
              title: Text('Documents',
                  style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.header != null) widget.header!,
            Expanded(
              child: VisaDocumentsStep(
                destination: _d,
                travellers: widget.travellers,
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: VisaPrimaryButton(
            label: _uploading ? 'Uploading…' : 'Continue',
            onPressed: _uploading ? null : _continue,
          ),
        ),
      ),
    );
  }
}
