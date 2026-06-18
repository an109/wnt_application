import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/navigation_queue.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../VisaApplication/Screen/visa_Application_screen.dart';
import '../../../login/presentation/screen/login.dart';
import '../../domain/entity/visaDestin_Entity.dart';
import '../../../../UI_helper/currency_converter.dart';

class VisaApplyPopup extends StatefulWidget {
  final String destinationName;
  final String price;
  final String currency;
  final List<VisaTypeEntity> visaTypes;  // Add this - receive actual visa types
  final VoidCallback? onSuccess;

  const VisaApplyPopup({
    Key? key,
    required this.destinationName,
    required this.price,
    required this.currency,
    required this.visaTypes,  // Required now
    this.onSuccess,
  }) : super(key: key);

  @override
  State<VisaApplyPopup> createState() => _VisaApplyPopupState();
}

class _VisaApplyPopupState extends State<VisaApplyPopup>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  VisaTypeEntity? _selectedVisaType;
  String? _selectedTravellers;
  String _countryCode = '+91';
  bool _isExpanded = true;
  bool _isSubmitting = false;
  String? _emailError;
  String? _phoneError;

  // Currency
  String _preferredCurrency = 'INR';
  String _preferredSymbol = '₹';
  double _conversionRate = 1.0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final List<String> _travellers = [
    '1 Traveller',
    '2 Travellers',
    '3 Travellers',
    '4 Travellers',
    '5 Travellers',
    '6 Travellers',
    '7 Travellers',
    '8 Travellers',
    '9 Travellers',
    '10 Travellers',
  ];

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    final emailRegex = RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
    );

    setState(() {
      _emailError =
      emailRegex.hasMatch(value) ? null : 'Please enter a valid email address';
    });
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }

    setState(() {
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        _phoneError = 'Only numbers are allowed';
      } else if (value.length < 10) {
        _phoneError = 'Phone number must be 10 digits';
      } else if (value.length > 10) {
        _phoneError = 'Phone number cannot exceed 10 digits';
      } else {
        _phoneError = null;
      }
    });
  }

  /// Get list of visa type names for dropdown
  List<String> get _visaTypeNames {
    return widget.visaTypes.map((visa) => visa.title).toList();
  }

  /// Parse traveller count from dropdown value (e.g., "3 Travellers" → 3)
  int _getTravellerCount(String? travellersValue) {
    if (travellersValue == null) return 1;
    final match = RegExp(r'(\d+)').firstMatch(travellersValue);
    return match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
  }

  /// Raw visa fee in its own feesCurrency (e.g. 90 USD).
  double get _rawVisaPrice {
    if (_selectedVisaType != null) return _selectedVisaType!.feesInr.toDouble();
    return double.tryParse(widget.price) ?? 0;
  }

  /// Converted single-visa price in the user's preferred currency.
  /// Uses CurrencyConverter (cached rates) so it handles per-type currencies.
  double get _convertedVisaPrice {
    final sourceCurrency = _selectedVisaType?.feesCurrency ?? 'USD';
    final amount = _rawVisaPrice;
    final preferred = CurrencyConverter.getPreferredCurrency();

    // Direct conversion using CurrencyConverter
    return CurrencyConverter.convert(
      amount: amount,
      fromCurrency: sourceCurrency,
      toCurrency: preferred,
    );
  }

  /// Formatted total (converted price × travellers).
  String _calculateTotalPrice() {
    final total = _convertedVisaPrice * _getTravellerCount(_selectedTravellers);
    final formatted = total.toStringAsFixed(total % 1 == 0 ? 0 : 2);
    return formatted;
  }

  /// Build dynamic price display
  Widget _buildPriceDisplay() {
    final count = _getTravellerCount(_selectedTravellers);
    final total = _calculateTotalPrice();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              '$_preferredSymbol$total',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w800,
                color: const Color(0xffFF6B00),
              ),
            ),
          ],
        ),

        // Show breakdown if applicable
        if (_selectedTravellers != null && count > 0 && _selectedVisaType != null)
          Padding(
            padding: EdgeInsets.only(top: context.gapXSmall),
            child: Text(
              '$_preferredSymbol${_convertedVisaPrice.toStringAsFixed(_convertedVisaPrice % 1 == 0 ? 0 : 2)} × $count traveller${count > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade500,
              ),
            ),
          ),

        // // Show visa type info
        // if (_selectedVisaType != null)
        //   Padding(
        //     padding: EdgeInsets.only(top: context.gapXSmall),
        //     child: Row(
        //       children: [
        //         Icon(
        //           Icons.check_circle_outline,
        //           size: context.iconXSmall,
        //           color: Colors.green,
        //         ),
        //         const SizedBox(width: 4),
        //         Expanded(
        //           child: Text(
        //             '${_selectedVisaType!.title} • Stay: ${_selectedVisaType!.stay} • Processing: ${_selectedVisaType!.processing}',
        //             style: TextStyle(
        //               fontSize: context.labelSmall,
        //               color: Colors.grey.shade600,
        //             ),
        //             maxLines: 1,
        //             overflow: TextOverflow.ellipsis,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Auto-select first visa type if available
    if (widget.visaTypes.isNotEmpty) {
      _selectedVisaType = widget.visaTypes.first;
    }

    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final preferred = CurrencyConverter.getPreferredCurrency();
    // Use the actual fees_currency from the first visa type (e.g. "USD").
    final sourceCurrency = widget.visaTypes.isNotEmpty
        ? widget.visaTypes.first.feesCurrency
        : (widget.currency.isNotEmpty ? widget.currency : 'USD');
    final rate =
        await CurrencyService.instance.getRate(sourceCurrency, preferred);
    if (!mounted) return;
    setState(() {
      _preferredCurrency = preferred;
      _preferredSymbol = CurrencyConverter.getSymbol(preferred);
      _conversionRate = rate;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _closePopup(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            /// BACKDROP WITH FADE
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (_, child) => Container(
                color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
              ),
            ),

            /// POPUP CONTENT - Centered
            Center(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (_, child) => Transform.scale(
                  scale: 0.9 + (0.1 * _fadeAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                ),
                child: _buildPopupContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupContent() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.isDesktop ? context.wp(50) : context.wp(92),
        maxHeight: context.isMobile ? context.hp(85) : context.hp(90),
      ),
      margin: EdgeInsets.all(context.isMobile ? context.wp(4) : context.wp(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// DRAG HANDLE
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: context.hp(1.5)),
              width: context.wp(12),
              height: context.hp(0.6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          /// HEADER WITH CLOSE BUTTON
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply for ${widget.destinationName} Visa',
                        style: TextStyle(
                          fontSize: context.titleMedium,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff0D1B3D),
                        ),
                      ),
                      SizedBox(height: context.gapXXSmall),
                      Text(
                        'Choose your visa type and proceed',
                        style: TextStyle(
                          fontSize: context.labelMedium,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _closePopup(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(context.wp(2)),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: context.iconSmall,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: context.hp(2), color: Colors.grey.shade200),

          /// FORM CONTENT
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// PRICE DISPLAY
                  _buildPriceDisplay(),
                  SizedBox(height: context.gapMedium),
                  /// QUICK INFO CARD
                  _buildQuickInfoCard(),
                  SizedBox(height: context.gapMedium),
                  /// APPLY FORM
                  _buildApplyForm(),
                  SizedBox(height: context.gapLarge),
                ],
              ),
            ),
          ),

          /// SUBMIT BUTTON
          Container(
            padding: EdgeInsets.fromLTRB(
              context.wp(4),
              context.gapSmall,
              context.wp(4),
              context.isMobile ? context.hp(3) : context.hp(4),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: context.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                    height: context.iconMedium,
                    width: context.iconMedium,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Apply Visa • $_preferredSymbol${_calculateTotalPrice()}',
                    style: TextStyle(
                      fontSize: context.labelLarge,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    return Container(
      padding: EdgeInsets.all(context.wp(3)),
      decoration: BoxDecoration(
        color: const Color(0xffE3F2FD),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        border: Border.all(color: const Color(0xff0D47A1).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.wp(2)),
            decoration: const BoxDecoration(
              color: Color(0xff0D47A1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time,
              size: context.iconSmall,
              color: Colors.white,
            ),
          ),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Application',
                  style: TextStyle(
                    fontSize: context.labelMedium,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D47A1),
                  ),
                ),
                Text(
                  'Less than 2 minutes to complete',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_up,
                size: context.iconMedium,
                color: const Color(0xff0D47A1),
              ),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyForm() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isExpanded
          ? Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _emailController,
              label: 'Email *',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
            ),
            if (_emailError != null)
              Padding(
                padding: EdgeInsets.only(
                  top: context.gapXSmall,
                  left: context.wp(1),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailError!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            SizedBox(height: context.gapSmall),
            _buildPhoneField(),
            SizedBox(height: context.gapSmall),

            // Dynamic Visa Type Dropdown
            _buildDynamicVisaTypeDropdown(),
            SizedBox(height: context.gapSmall),

            _buildDropdownField(
              value: _selectedTravellers,
              label: 'Travellers *',
              hint: 'No. of travellers',
              items: _travellers,
              onChanged: (val) => setState(() => _selectedTravellers = val),
            ),
          ],
        ),
      )
          : Container(),
    );
  }

  /// New: Dynamic Visa Type Dropdown that shows visa details
  Widget _buildDynamicVisaTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<VisaTypeEntity>(
        value: _selectedVisaType,
        isExpanded: true,
        isDense: true,
        dropdownColor: Colors.white,
        iconEnabledColor: const Color(0xff0D47A1),
        iconDisabledColor: Colors.grey.shade400,
        decoration: InputDecoration(
          labelText: 'Visa Type *',
          labelStyle: TextStyle(
            fontSize: context.labelMedium,
            color: Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: const BorderSide(color: Color(0xff0D47A1), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.wp(3),
            vertical: context.hp(1.2),
          ),
        ),
        hint: Text(
          'Select visa type',
          style: TextStyle(
            fontSize: context.labelMedium,
            color: Colors.grey.shade400,
          ),
        ),
        items: widget.visaTypes.map((visa) {
          return DropdownMenuItem(
            value: visa,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.hp(0.5)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      visa.title,  // Only show the title
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff0D1B3D),
                      ),
                    ),
                  ),
                  if (visa.popular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xff0D47A1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: const Color(0xff0D47A1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (VisaTypeEntity? newValue) {
          setState(() {
            _selectedVisaType = newValue;
          });
        },
        validator: (value) => value == null ? 'Please select a visa type' : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        onChanged: label.contains('Email')
            ? _validateEmail
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontSize: context.labelMedium,
            color: Colors.grey.shade600,
          ),
          hintStyle: TextStyle(
            fontSize: context.labelMedium,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(icon, size: context.iconMedium, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: const BorderSide(color: Color(0xff0D47A1), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.wp(3),
            vertical: context.hp(1.5),
          ),
        ),
        style: TextStyle(fontSize: context.bodyMedium),
        validator: (value) {
          if (value == null || value.isEmpty) return 'This field is required';
          if (label.contains('Email') && !value.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.wp(3)),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: DropdownButton<String>(
              value: _countryCode,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, size: context.iconSmall),
              items: ['+91', '+1', '+44', '+971'].map((code) {
                return DropdownMenuItem(
                  value: code,
                  child: Text(code, style: TextStyle(fontSize: context.bodyMedium)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _countryCode = val!),
            ),
          ),
          Expanded(
            child: TextFormField(
              maxLength: 10,
              onChanged: _validatePhone,
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Phone number',
                counterText: '',
                hintStyle: TextStyle(
                  fontSize: context.labelMedium,
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(1.5),
                ),
              ),
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: context.bodyMedium),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Phone is required';
                if (value.length < 10) return 'Enter valid phone number';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        dropdownColor: Colors.white,
        iconEnabledColor: const Color(0xff0D47A1),
        iconDisabledColor: Colors.grey.shade400,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: context.labelMedium,
            color: Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            borderSide: const BorderSide(color: Color(0xff0D47A1), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.wp(3),
            vertical: context.hp(1.2),
          ),
        ),
        hint: Text(
          hint,
          style: TextStyle(
            fontSize: context.labelMedium,
            color: Colors.grey.shade400,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.hp(0.5)),
              child: Text(item, style: TextStyle(fontSize: context.bodyMedium)),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, size: context.iconMedium),
        validator: (value) => value == null ? 'Please select an option' : null,
      ),
    );
  }

  void _closePopup() {
    _animationController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Prepare application data
    final applicationData = {
      'destination': widget.destinationName,
      'visaType': _selectedVisaType?.title,
      'visaStay': _selectedVisaType?.stay,
      'visaEntry': _selectedVisaType?.entry,
      'travellers': _getTravellerCount(_selectedTravellers),
      'totalAmount': _calculateTotalPrice(),
      'currency': _preferredCurrency,
      'email': _emailController.text.trim(),
      'phone': '$_countryCode ${_phoneController.text.trim()}',
      'countryCode': _countryCode,
    };

    // Check if user is authenticated
    final prefs = await SharedPreferences.getInstance();
    final preferencesManager = await PreferencesManager.create(prefs);
    final isLoggedIn = preferencesManager.isLoggedIn();

    print(' Is user logged in? $isLoggedIn');

    if (isLoggedIn) {
      // User is authenticated, get user data and navigate directly
      final userData = preferencesManager.getUserData();
      final filledData = {
        ...applicationData,
        'userEmail': userData?['email'] ?? _emailController.text.trim(),
        'userName': userData?['name'] ?? '',
      };

      if (mounted) {
        Navigator.pop(context); // Close popup first
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisaApplicationScreen(
              destinationName: widget.destinationName,
              price: widget.price,
              currency: widget.currency,
              visaType: _selectedVisaType ?? widget.visaTypes.first,
              preFilledData: filledData,
            ),
          ),
        );
      }
    } else {
      // User not authenticated, store data and show login
      if (mounted) {
        // Store application data temporarily (you can use a simple map or service)
        // For now, we'll pass it through the navigation queue
        NavigationQueueService().setPendingNavigation(() {
          // After login, get user data and navigate
          _navigateToApplicationWithUserData(applicationData);
        });

        // Close current popup
        Navigator.pop(context);

        // Show login popup
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const LoginSignupScreen(),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

// Helper method to navigate after login with user data
  Future<void> _navigateToApplicationWithUserData(Map<String, dynamic> applicationData) async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesManager = await PreferencesManager.create(prefs);
    final userData = preferencesManager.getUserData();

    final filledData = {
      ...applicationData,
      'userEmail': userData?['email'] ?? applicationData['email'],
      'userName': userData?['name'] ?? '',
    };

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisaApplicationScreen(
            destinationName: widget.destinationName,
            price: widget.price,
            currency: widget.currency,
            visaType: _selectedVisaType ?? widget.visaTypes.first,
            preFilledData: filledData,
          ),
        ),
      );
    }
  }
}