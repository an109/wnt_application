import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

class AddTravellerModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onTravellerAdded;

  const AddTravellerModal({
    super.key,
    required this.onTravellerAdded,
  });

  @override
  State<AddTravellerModal> createState() => _AddTravellerModalState();
}

class _AddTravellerModalState extends State<AddTravellerModal> {
  // final _formKey = GlobalKey<FormState>();

  // Controllers
  final _paxTypeController = TextEditingController(text: 'Adult');
  final _titleController = TextEditingController(text: 'Mr');
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Indian');
  final _visaTypeController = TextEditingController(text: 'Tourist');
  final _passportNumberController = TextEditingController();
  final _placeOfIssueController = TextEditingController();
  final _passportExpiryController = TextEditingController();
  final _issuingCountryController = TextEditingController(text: 'India');

  late final GlobalKey<FormState> _formKey;

  bool _isLoading = false;

  @override
  void dispose() {
    _paxTypeController.dispose();
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _visaTypeController.dispose();
    _passportNumberController.dispose();
    _placeOfIssueController.dispose();
    _passportExpiryController.dispose();
    _issuingCountryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Create a unique key for each instance
    _formKey = GlobalKey<FormState>(debugLabel: 'add_traveller_form_${hashCode}');

  }

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  void _saveTraveller() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final travellerData = {
        'paxType': _paxTypeController.text,
        'title': _titleController.text,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text,
        'nationality': _nationalityController.text,
        'visaType': _visaTypeController.text,
        'passportNumber': _passportNumberController.text.trim(),
        'placeOfIssue': _placeOfIssueController.text.trim(),
        'passportExpiry': _passportExpiryController.text,
        'issuingCountry': _issuingCountryController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onTravellerAdded(travellerData);
          Navigator.pop(context);
        }
      });
    }
  }

  bool get _useGridLayout => true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: context.isMobile ? 0.94 : 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.borderRadiusLarge),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Drag Handle
                  Padding(
                    padding: EdgeInsets.only(top: context.gapSmall),
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: context.responsivePadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Add Traveller',
                            style: TextStyle(
                              fontSize: context.titleLarge,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            size: context.iconMedium,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  // BODY
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: context.scrollPhysics,
                      padding: EdgeInsets.only(
                        left: context.wp(4),
                        right: context.wp(4),
                        top: context.gapMedium,
                        bottom: MediaQuery.of(context).viewInsets.bottom +
                            context.gapXLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===================================================
                          // PERSONAL DETAILS
                          // ===================================================

                          _buildSectionCard(
                            context,
                            title: 'Personal Details',
                            child: Column(
                              children: [
                                _buildResponsiveFields(
                                  context,
                                  children: [
                                    _buildDropdownField(
                                      context: context,
                                      label: 'Pax Type',
                                      controller: _paxTypeController,
                                      items: [
                                        'Adult',
                                        'Child',
                                        'Infant'
                                      ],
                                    ),
                                    _buildDropdownField(
                                      context: context,
                                      label: 'Title',
                                      controller: _titleController,
                                      items: [
                                        'Mr',
                                        'Mrs',
                                        'Ms',
                                        'Dr',
                                        'Master'
                                      ],
                                      isRequired: true,
                                    ),
                                    _buildTextField(
                                      context: context,
                                      label: 'First Name',
                                      controller: _firstNameController,
                                      hintText: 'First name',
                                      isRequired: true,
                                    ),
                                    _buildTextField(
                                      context: context,
                                      label: 'Last Name',
                                      controller: _lastNameController,
                                      hintText: 'Last name',
                                      isRequired: true,
                                    ),
                                  ],
                                ),

                                SizedBox(height: context.gapMedium),

                                _buildResponsiveFields(
                                  context,
                                  children: [
                                    _buildDateField(
                                      context: context,
                                      label: 'Date of Birth',
                                      controller:
                                      _dateOfBirthController,
                                      hintText: 'dd-mm-yyyy',
                                      isRequired: true,
                                    ),
                                    _buildDropdownField(
                                      context: context,
                                      label: 'Nationality',
                                      controller:
                                      _nationalityController,
                                      items: [
                                        'Indian',
                                        'American',
                                        'British',
                                        'Australian',
                                        'Canadian',
                                        'Other'
                                      ],
                                      isRequired: true,
                                    ),
                                    _buildDropdownField(
                                      context: context,
                                      label: 'Visa Type',
                                      controller:
                                      _visaTypeController,
                                      items: [
                                        'Tourist',
                                        'Business',
                                        'Student',
                                        'Work',
                                        'Transit'
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.gapLarge),

                          // ===================================================
                          // PASSPORT DETAILS
                          // ===================================================

                          _buildSectionCard(
                            context,
                            title: 'Passport Details',
                            child: Column(
                              children: [
                                _buildResponsiveFields(
                                  context,
                                  children: [
                                    _buildTextField(
                                      context: context,
                                      label: 'Passport Number',
                                      controller:
                                      _passportNumberController,
                                      hintText: 'Passport number',
                                    ),
                                    _buildTextField(
                                      context: context,
                                      label: 'Place of Issue',
                                      controller:
                                      _placeOfIssueController,
                                      hintText: 'Place of issue',
                                    ),
                                  ],
                                ),

                                SizedBox(height: context.gapMedium),

                                _buildResponsiveFields(
                                  context,
                                  children: [
                                    _buildDateField(
                                      context: context,
                                      label: 'Passport Expiry',
                                      controller:
                                      _passportExpiryController,
                                      hintText: 'dd-mm-yyyy',
                                    ),
                                    _buildDropdownField(
                                      context: context,
                                      label: 'Issuing Country',
                                      controller:
                                      _issuingCountryController,
                                      items: [
                                        'India',
                                        'USA',
                                        'UK',
                                        'Australia',
                                        'Canada',
                                        'Other'
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.gapXXLarge),

                          // ===================================================
                          // BUTTONS
                          // ===================================================

                          context.isMobile
                              ? Column(
                            children: [
                              _buildSaveButton(context),
                              SizedBox(
                                  height: context.gapMedium),
                              _buildCancelButton(context),
                            ],
                          )
                              : Row(
                            children: [
                              Expanded(
                                child:
                                _buildCancelButton(context),
                              ),
                              SizedBox(
                                  width: context.gapMedium),
                              Expanded(
                                child: _buildSaveButton(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =======================================================
  // SECTION CARD
  // =======================================================

  Widget _buildSectionCard(
      BuildContext context, {
        required String title,
        required Widget child,
      }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(context.borderRadiusMedium),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: context.gapMedium),
          child,
        ],
      ),
    );
  }

  // =======================================================
  // RESPONSIVE FIELDS
  // =======================================================

  Widget _buildResponsiveFields(
      BuildContext context, {
        required List<Widget> children,
      }) {
    final isSmallMobile = MediaQuery.of(context).size.width < 380;

    // Mobile → 2 fields per row
    if (context.isMobile && !isSmallMobile && _useGridLayout) {
      return Wrap(
        spacing: context.gapMedium,
        runSpacing: context.gapMedium,
        children: children.map((child) {
          return SizedBox(
            width:
            (MediaQuery.of(context).size.width -
                context.wp(8) -
                context.gapMedium -
                32) /
                2,
            child: child,
          );
        }).toList(),
      );
    }

    // Very small devices → single column
    if (context.isMobile) {
      return Column(
        children: children
            .map(
              (child) => Padding(
            padding:
            EdgeInsets.only(bottom: context.gapMedium),
            child: child,
          ),
        )
            .toList(),
      );
    }

    // Tablet/Desktop
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((child) {
        return Expanded(
          child: Padding(
            padding:
            EdgeInsets.symmetric(horizontal: context.gapXSmall),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  // =======================================================
  // TEXT FIELD
  // =======================================================

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label, isRequired),
        SizedBox(height: context.gapSmall),

        TextFormField(
          controller: controller,
          style: TextStyle(fontSize: context.bodyMedium),
          decoration: _inputDecoration(
            context,
            hintText: hintText,
          ),
          validator: (value) {
            if (isRequired &&
                (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  // =======================================================
  // DROPDOWN FIELD
  // =======================================================

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required List<String> items,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label, isRequired),
        SizedBox(height: context.gapSmall),

        DropdownButtonFormField<String>(
          value: controller.text,
          isExpanded: true,
          decoration: _inputDecoration(context),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.bodyMedium),
              ),
            );
          }).toList(),
          onChanged: (value) {
            controller.text = value ?? '';
          },
          validator: (value) {
            if (isRequired && value == null) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  // =======================================================
  // DATE FIELD
  // =======================================================

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label, isRequired),
        SizedBox(height: context.gapSmall),

        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context, controller),
          decoration: _inputDecoration(
            context,
            hintText: hintText,
            suffixIcon:
            const Icon(Icons.calendar_month_outlined),
          ),
          validator: (value) {
            if (isRequired &&
                (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  // =======================================================
  // COMMON INPUT DECORATION
  // =======================================================

  InputDecoration _inputDecoration(
      BuildContext context, {
        String? hintText,
        Widget? suffixIcon,
      }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: context.bodySmall,
        color: Colors.grey.shade500,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapMedium,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(context.borderRadiusSmall),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(context.borderRadiusSmall),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(context.borderRadiusSmall),
        borderSide: BorderSide(
          color: AppColors.accent,
          width: 1.5,
        ),
      ),
    );
  }

  // =======================================================
  // LABEL
  // =======================================================

  Widget _buildLabel(
      BuildContext context,
      String label,
      bool isRequired,
      ) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: context.bodySmall,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  // =======================================================
  // SAVE BUTTON
  // =======================================================

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTraveller,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(context.borderRadiusSmall),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          'Save Traveller',
          style: TextStyle(
            fontSize: context.bodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =======================================================
  // CANCEL BUTTON
  // =======================================================

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(context.borderRadiusSmall),
          ),
        ),
        child: Text(
          'Cancel',
          style: TextStyle(
            fontSize: context.bodyMedium,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}