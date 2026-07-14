import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'holiday_payment_screen.dart';

const Color _kAccent = Color(0xffFF3B3B);
const Color _kInk = Color(0xff1A1A2E);

/// Holds one traveller's form state (title/name/DOB/nationality/gender).
class _TravellerForm {
  String title = 'Mr';
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  DateTime? dob;
  final nationalityController = TextEditingController(text: 'Indian');
  String gender = 'Male';

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    nationalityController.dispose();
  }
}

/// Collects traveller details (one form per traveller already selected on
/// the package details screen) and contact info, then hands off to
/// [HolidayPaymentScreen] for payment method selection.
class HolidayTravellerDetailsScreen extends StatefulWidget {
  final String packageTitle;
  final String packageImage;
  final String packageLocation;
  final int travellersCount;
  final double grandTotalInr;
  final String baseTotalDisplay;
  final String gstDisplay;
  final String grandTotalDisplay;
  final double gstPercent;

  /// Package identifiers + trip facts, forwarded to [HolidayPaymentScreen]
  /// so it can save the booking once payment succeeds.
  final int packageInventoryId;
  final String packageSlug;
  final String city;
  final int nights;
  final int days;
  final Map<String, dynamic> packageSnapshot;

  /// The departure date picked on the holiday search card, forwarded to
  /// [HolidayPaymentScreen] so the booking's check-in reflects the actual
  /// searched date instead of defaulting to today.
  final DateTime? departureDate;

  const HolidayTravellerDetailsScreen({
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
    this.packageInventoryId = 0,
    this.packageSlug = '',
    this.city = '',
    this.nights = 0,
    this.days = 0,
    this.packageSnapshot = const {},
    this.departureDate,
  });

  @override
  State<HolidayTravellerDetailsScreen> createState() => _HolidayTravellerDetailsScreenState();
}

class _HolidayTravellerDetailsScreenState extends State<HolidayTravellerDetailsScreen> {
  late final List<_TravellerForm> _travellers;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _travellers = List.generate(widget.travellersCount.clamp(1, 999), (_) => _TravellerForm());
  }

  @override
  void dispose() {
    for (final t in _travellers) {
      t.dispose();
    }
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  bool _validate() {
    for (int i = 0; i < _travellers.length; i++) {
      final t = _travellers[i];
      final label = _travellers.length > 1 ? 'Traveller ${i + 1}' : 'Traveller';
      if (t.firstNameController.text.trim().isEmpty) {
        _snack('Please enter first name for $label');
        return false;
      }
      if (t.lastNameController.text.trim().isEmpty) {
        _snack('Please enter last name for $label');
        return false;
      }
      if (t.dob == null) {
        _snack('Please select date of birth for $label');
        return false;
      }
      if (t.nationalityController.text.trim().isEmpty) {
        _snack('Please enter nationality for $label');
        return false;
      }
    }
    if (_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      _snack('Please enter a valid contact number');
      return false;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _snack('Please enter a valid email address');
      return false;
    }
    if (!_agreedToTerms) {
      _snack('Please accept the Terms & Conditions to continue');
      return false;
    }
    return true;
  }

  void _onContinue() {
    if (!_validate()) return;

    final firstTraveller = _travellers.first;
    final prefillName =
        '${firstTraveller.title} ${firstTraveller.firstNameController.text.trim()} ${firstTraveller.lastNameController.text.trim()}'
            .trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HolidayPaymentScreen(
          packageTitle: widget.packageTitle,
          packageImage: widget.packageImage,
          packageLocation: widget.packageLocation,
          travellersCount: widget.travellersCount,
          grandTotalInr: widget.grandTotalInr,
          baseTotalDisplay: widget.baseTotalDisplay,
          gstDisplay: widget.gstDisplay,
          grandTotalDisplay: widget.grandTotalDisplay,
          gstPercent: widget.gstPercent,
          packageInventoryId: widget.packageInventoryId,
          packageSlug: widget.packageSlug,
          city: widget.city,
          nights: widget.nights,
          days: widget.days,
          packageSnapshot: widget.packageSnapshot,
          departureDate: widget.departureDate,
          prefillName: prefillName,
          prefillEmail: _emailController.text.trim(),
          prefillPhone: _phoneController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'Traveller Details',
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
            for (int i = 0; i < _travellers.length; i++) ...[
              _buildTravellerCard(i),
              SizedBox(height: context.gapLarge),
            ],
            _buildContactCard(),
            SizedBox(height: context.gapLarge),
            _buildTermsCheckbox(),
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

  Widget _buildTravellerCard(int index) {
    final t = _travellers[index];
    final label = _travellers.length > 1 ? 'Traveller ${index + 1}' : 'Traveller Details';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: context.iconMedium, color: _kAccent),
              SizedBox(width: context.w(8)),
              Text(label, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _kInk)),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  label: 'Title',
                  value: t.title,
                  items: const ['Mr', 'Mrs', 'Ms'],
                  onChanged: (v) => setState(() => t.title = v!),
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                flex: 2,
                child: _buildTextField(controller: t.firstNameController, label: 'First Name'),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: t.lastNameController, label: 'Last Name')),
              SizedBox(width: context.w(8)),
              Expanded(child: _buildDateField(t)),
            ],
          ),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: t.nationalityController, label: 'Nationality')),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _buildDropdown(
                  label: 'Gender',
                  value: t.gender,
                  items: const ['Male', 'Female', 'Other'],
                  onChanged: (v) => setState(() => t.gender = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail_outlined, size: context.iconMedium, color: _kAccent),
              SizedBox(width: context.w(8)),
              Text('Contact Information',
                  style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _kInk)),
            ],
          ),
          SizedBox(height: context.h(12)),
          _buildTextField(
            controller: _phoneController,
            label: 'Contact Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: context.h(10)),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return _card(
      child: GestureDetector(
        onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: context.w(20),
              height: context.w(20),
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: _kAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: context.h(2)),
                child: Text(
                  'I confirm the traveller details above are accurate and agree to the '
                  'Terms & Conditions and Cancellation Policy for this booking.',
                  style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: context.fs(13)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: context.fs(12)),
        prefixIcon: icon != null ? Icon(icon, size: context.iconSmall, color: Colors.grey.shade600) : null,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.r(8)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: context.iconSmall),
              items: items
                  .map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(fontSize: context.fs(13)))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(_TravellerForm t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        InkWell(
          onTap: () => _pickDob(t),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(12)),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: context.iconSmall, color: Colors.grey.shade600),
                SizedBox(width: context.w(6)),
                Expanded(
                  child: Text(
                    t.dob != null
                        ? '${t.dob!.day.toString().padLeft(2, '0')}/${t.dob!.month.toString().padLeft(2, '0')}/${t.dob!.year}'
                        : 'dd/mm/yyyy',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      color: t.dob != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDob(_TravellerForm t) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: t.dob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => t.dob = picked);
    }
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
            onPressed: _onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
            ),
            child: Text(
              'Continue',
              style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
