import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';

class VisaApplyPopup extends StatefulWidget {
  final String destinationName;
  final String price;
  final String currency;
  final VoidCallback? onSuccess;

  const VisaApplyPopup({
    Key? key,
    required this.destinationName,
    required this.price,
    required this.currency,
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
  String? _selectedVisaType;
  String? _selectedTravellers;
  String _countryCode = '+91';
  bool _isExpanded = true;
  bool _isSubmitting = false;

  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  final List<String> _visaTypes = [
    '30 Days Tourist E-Visa',
    '1 Year Tourist E-Visa',
    'Business Visitor E-Visa',
  ];

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
  ];


  /// Parse traveller count from dropdown value (e.g., "3 Travellers" → 3)
  int _getTravellerCount(String? travellersValue) {
    if (travellersValue == null) return 1;
    final match = RegExp(r'(\d+)').firstMatch(travellersValue);
    return match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
  }

  /// Calculate total price based on base price × travellers
  String _calculateTotalPrice(String basePrice, String? travellersValue) {
    final base = double.tryParse(basePrice) ?? 0;
    final count = _getTravellerCount(travellersValue);
    final total = base * count;
    return total.toStringAsFixed(total % 1 == 0 ? 0 : 2);
  }

  /// Add this method to display dynamic price
  Widget _buildPriceDisplay() {
    final count = _getTravellerCount(_selectedTravellers);
    final total = _calculateTotalPrice(widget.price, _selectedTravellers);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(context.wp(3)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total for $count traveller${count > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.currency} $total',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff0D47A1),
                ),
              ),
            ],
          ),
          // Optional: Show per-person breakdown
          if (_selectedTravellers != null && count > 1)
            Padding(
              padding: EdgeInsets.only(top: context.gapXXSmall),
              child: Text(
                '${widget.currency} ${widget.price} × $count',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
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

            /// POPUP CONTENT WITH SLIDE UP
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: AnimatedBuilder(
            //     animation: _slideAnimation,
            //     builder: (_, child) => Transform.translate(
            //       offset: Offset(0, context.screenHeight * _slideAnimation.value),
            //       child: child,
            //     ),
            //     child: _buildPopupContent(),
            //   ),
            // ),
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
      // margin: EdgeInsets.only(
      //   bottom: context.isMobile ? context.hp(2) : context.hp(4),
      //   left: context.wp(4),
      //   right: context.wp(4),
      // ),
      constraints: BoxConstraints(
        maxWidth: context.isDesktop ? context.wp(60) : context.wp(92),
        maxHeight: context.isMobile ? context.hp(85) : context.hp(90),
      ),
      margin: EdgeInsets.all(context.isMobile ? context.wp(4) : context.wp(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.only(
        //   topLeft: Radius.circular(context.borderRadiusLarge),
        //   topRight: Radius.circular(context.borderRadiusLarge),
        // ),
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -4),
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
                        'Starting from ${widget.currency} ${widget.price}',
                        style: TextStyle(
                          fontSize: context.labelMedium,
                          color: const Color(0xff0D47A1),
                          fontWeight: FontWeight.w600,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

          /// SINGLE APPLY BUTTON (Fixed at bottom)
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
                  offset: Offset(0, -2),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Apply Visa',
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
            decoration: BoxDecoration(
              color: const Color(0xff0D47A1),
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
              constraints: BoxConstraints(),
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
            SizedBox(height: context.gapSmall),
            _buildPhoneField(),
            SizedBox(height: context.gapSmall),
            _buildDropdownField(
              value: _selectedVisaType,
              label: 'Visa type *',
              hint: 'Select visa type',
              items: _visaTypes,
              onChanged: (val) => setState(() => _selectedVisaType = val),
            ),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
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
            borderSide: BorderSide(color: const Color(0xff0D47A1), width: 2),
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
            offset: Offset(0, 2),
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
              underline: SizedBox(),
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
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Phone number',
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,           // Fill available width
        isDense: true,              // Reduce internal padding
        dropdownColor: Colors.white, // Consistent background
        iconEnabledColor: const Color(0xff0D47A1), // Match theme
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
            borderSide: BorderSide(color: const Color(0xff0D47A1), width: 2),
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
          style: TextStyle(fontSize: context.labelMedium, color: Colors.grey.shade400),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Padding(  //  Add padding to dropdown items
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: context.gapSmall),
              Text('Application submitted successfully!'),
            ],
          ),
          backgroundColor: const Color(0xff10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
          ),
        ),
      );
      widget.onSuccess?.call();
      _closePopup();
    }
  }
}