import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

// Traveller Information Widget with Login Statement
class TravellerInformationSection extends StatefulWidget {
  final GlobalKey<TravellerFormState>? formKey;
  final VoidCallback onDepartureDateTap;
  final VoidCallback onReturnDateTap;
  final DateTime? departureDate;
  final DateTime? returnDate;

  const TravellerInformationSection({
    super.key,
    this.formKey,
    required this.onDepartureDateTap,
    required this.onReturnDateTap,
    this.departureDate,
    this.returnDate,
  });

  @override
  State<TravellerInformationSection> createState() => _TravellerInformationSectionState();
}

class _TravellerInformationSectionState extends State<TravellerInformationSection> with TravellerFormMixin {
  final _internalFormKey = GlobalKey<FormState>();

  // List to manage multiple travelers - initialized with one adult
  List<TravellerData> _travelers = [];
  List<bool> _expandedStates = [];

  // Controllers for the first traveler (initial)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();
  final _destinationController = TextEditingController();
  final _hotelController = TextEditingController();

  // New controllers
  final _genderController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _passportExpiryController = TextEditingController();
  bool _requiresWheelchair = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one traveler (Adult 1)
    _travelers = [
      TravellerData(id: '1', title: 'Adult 1'),
    ];
    _expandedStates = [true]; // Start expanded
  }

  void _toggleExpansion(int index) {
    setState(() {
      _expandedStates[index] = !_expandedStates[index];
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _destinationController.dispose();
    _hotelController.dispose();
    _genderController.dispose();
    _nationalityController.dispose();
    _passportExpiryController.dispose();
    super.dispose();
  }

  @override
  TextEditingController get firstNameController => _firstNameController;
  @override
  TextEditingController get lastNameController => _lastNameController;
  @override
  TextEditingController get emailController => _emailController;
  @override
  TextEditingController get phoneController => _phoneController;
  @override
  TextEditingController get passportController => _passportController;
  @override
  TextEditingController get destinationController => _destinationController;
  @override
  TextEditingController get hotelController => _hotelController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.gapLarge),

        // Traveller Information Section
        _buildTravellerSection(context),
      ],
    );
  }

  Widget _buildTravellerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Traveller Information",
          style: TextStyle(
            fontSize: context.titleLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.gapLarge),

        // List of collapsible traveler cards
        ...List.generate(_travelers.length, (index) {
          return _buildCollapsibleTravellerCard(context, index);
        }),
      ],
    );
  }

  Widget _buildCollapsibleTravellerCard(BuildContext context, int index) {
    final traveler = _travelers[index];
    final isExpanded = _expandedStates[index];

    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible Header
          InkWell(
            onTap: () => _toggleExpansion(index),
            borderRadius: BorderRadius.circular(context.borderRadius),
            child: Container(
              padding: EdgeInsets.all(context.gapMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      traveler.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.titleMedium,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isExpanded ? 0.5 : 0.0,
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content with smooth animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
              padding: EdgeInsets.all(context.gapMedium),
              child: _buildTravellerForm(context, index),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTravellerForm(BuildContext context, int index) {
    return Form(
      key: _internalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title field with red asterisk
          _buildRequiredTitle(context, "Title *"),
          SizedBox(height: context.gapSmall),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _firstNameController,
                  label: "First Name *",
                  hintText: "John",
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'First name is required' : null,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _lastNameController,
                  label: "Last Name *",
                  hintText: "Doe",
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Last name is required' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Mobile Number & Email
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _phoneController,
                  label: "Mobile Number *",
                  hintText: "+1 234 567 8900",
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Mobile number is required' : null,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _emailController,
                  label: "Email *",
                  hintText: "john.doe@example.com",
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Gender & Nationality
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  context,
                  controller: _genderController,
                  label: "Gender *",
                  items: ['Male', 'Female', 'Other'],
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Gender is required' : null,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _nationalityController,
                  label: "Nationality *",
                  hintText: "e.g., American",
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Nationality is required' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Passport Number & Passport Expiry
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _passportController,
                  label: "Passport Number *",
                  hintText: "A12345678",
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Passport number is required' : null,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildDatePickerField(
                  context,
                  controller: _passportExpiryController,
                  label: "Passport Expiry *",
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Passport expiry is required' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Wheelchair Checkbox
          // CheckboxListTile(
          //   value: _requiresWheelchair,
          //   onChanged: (bool? value) {
          //     setState(() {
          //       _requiresWheelchair = value ?? false;
          //     });
          //   },
          //   title: Text(
          //     "I require wheelchair (optional)",
          //     style: TextStyle(
          //       fontSize: context.bodySmall,
          //       color: Colors.grey.shade700,
          //     ),
          //   ),
          //   controlAffinity: ListTileControlAffinity.leading,
          //   dense: true,
          //   contentPadding: EdgeInsets.zero,
          //   activeColor: Colors.red.shade600,
          // ),

          SizedBox(height: context.gapLarge),

          // Travel Details Section (from parent)
          Text(
            "Travel Details",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.bodyLarge,
            ),
          ),
          SizedBox(height: context.gapMedium),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  label: "Departure Date *",
                  value: widget.departureDate,
                  onTap: widget.onDepartureDateTap,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildDateField(
                  context,
                  label: "Return Date *",
                  value: widget.returnDate,
                  onTap: widget.onReturnDateTap,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapLarge),

          Text(
            "Destination Details",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.bodyLarge,
            ),
          ),
          SizedBox(height: context.gapMedium),

          _buildTextField(
            context,
            controller: _destinationController,
            label: "Destination City/Country *",
            hintText: "Dubai, UAE",
            isRequired: true,
            validator: (value) => value?.isEmpty ?? true ? 'Destination is required' : null,
          ),
          SizedBox(height: context.gapMedium),

          _buildTextField(
            context,
            controller: _hotelController,
            label: "Hotel/Resort Preference",
            hintText: "Optional",
            isRequired: false,
            validator: null,
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredTitle(BuildContext context, String title) {
    return RichText(
      text: TextSpan(
        text: title.split('*')[0],
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: context.bodySmall,
          color: Colors.grey.shade700,
        ),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        String? hintText,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        bool isRequired = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired ? _buildRequiredTitle(context, label) : Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: context.bodySmall,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.gapSmall),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: context.bodySmall),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        required List<String> items,
        String? Function(String?)? validator,
        bool isRequired = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired ? _buildRequiredTitle(context, label) : Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: context.bodySmall,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.gapSmall),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {
            controller.text = value ?? '';
          },
          validator: validator,
          hint: Text('Select $label'),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        String? Function(String?)? validator,
        bool isRequired = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired ? _buildRequiredTitle(context, label) : Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: context.bodySmall,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.gapSmall),
        InkWell(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (pickedDate != null) {
              controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
              setState(() {});
            }
          },
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text.isEmpty ? "Select Date" : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? Colors.grey.shade400 : Colors.black,
                    fontSize: context.bodySmall,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey.shade600,
                  size: context.iconSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context, {
        required String label,
        required DateTime? value,
        required VoidCallback onTap,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredTitle(context, label),
        SizedBox(height: context.gapSmall),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value == null
                      ? "Select Date"
                      : DateFormat('dd MMM yyyy').format(value),
                  style: TextStyle(
                    color: value == null ? Colors.grey.shade400 : Colors.black,
                    fontSize: context.bodySmall,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey.shade600,
                  size: context.iconSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool validateForm() {
    return _internalFormKey.currentState?.validate() ?? false;
  }

  Map<String, dynamic> getTravellerData() {
    return {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'gender': _genderController.text,
      'nationality': _nationalityController.text,
      'passport': _passportController.text,
      'passportExpiry': _passportExpiryController.text,
      'requiresWheelchair': _requiresWheelchair,
      'destination': _destinationController.text,
      'hotel': _hotelController.text,
      'departureDate': widget.departureDate,
      'returnDate': widget.returnDate,
    };
  }
}

// Data class for traveler
class TravellerData {
  final String id;
  String title;

  TravellerData({
    required this.id,
    required this.title,
  });
}

// Mixin for form validation and data access
mixin TravellerFormMixin {
  TextEditingController get firstNameController;
  TextEditingController get lastNameController;
  TextEditingController get emailController;
  TextEditingController get phoneController;
  TextEditingController get passportController;
  TextEditingController get destinationController;
  TextEditingController get hotelController;

  bool validateForm() {
    final formKey = (this is _TravellerInformationSectionState)
        ? (this as _TravellerInformationSectionState)._internalFormKey
        : null;

    if (formKey != null) {
      return formKey.currentState?.validate() ?? false;
    }
    return false;
  }

  Map<String, dynamic> getTravellerData() {
    return {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'passport': passportController.text,
      'destination': destinationController.text,
      'hotel': hotelController.text,
    };
  }
}

// Global key for accessing form state from parent
class TravellerFormState extends State<TravellerInformationSection> {
  @override
  Widget build(BuildContext context) {
    return widget;
  }

  bool validateForm() {
    final state = this.widget as TravellerInformationSection;
    final internalState = state.formKey?.currentState;
    if (internalState is _TravellerInformationSectionState) {
      return internalState!.validateForm();
    }
    return false;
  }

  Map<String, dynamic> getTravellerData() {
    final state = this.widget as TravellerInformationSection;
    final internalState = state.formKey?.currentState;
    if (internalState is _TravellerInformationSectionState) {
      return internalState!.getTravellerData();
    }
    return {};
  }
}