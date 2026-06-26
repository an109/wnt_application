import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CustomerSupportSection extends StatefulWidget {
  const CustomerSupportSection({super.key});

  @override
  State<CustomerSupportSection> createState() => _CustomerSupportSectionState();
}

class _CustomerSupportSectionState extends State<CustomerSupportSection> {
  bool _isEmailSupport = true;
  final _formKey = GlobalKey<FormState>();
  String? _selectedQueryType;
  String _travelType = 'Domestic';

  // Controllers
  final _bookingRefController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isPickingFile = false;

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isPickingFile = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected: ${_selectedFile!.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPickingFile = false;
      });
    }
  }

  final List<String> _queryTypes = [
    'Cancellation',
    'Flight Rescheduling Charges',
    'Flight Booking Status',
    'Flight Refund Status',
    'Others',
  ];

  @override
  void dispose() {
    _bookingRefController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: context.shadowOffsetSmall,
          ),
        ],
      ),
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Support',
              style: TextStyle(
                fontSize: context.responsiveFontSize(20, 18, 16),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: context.gapLarge),

            // Support Type Tabs
            Row(
              children: [
                Expanded(
                  child: _buildSupportTypeTab('Email Support', Icons.email, true),
                ),
                SizedBox(width: context.gapMedium),
                Expanded(
                  child: _buildSupportTypeTab('Call Support', Icons.phone, false),
                ),
              ],
            ),

            SizedBox(height: context.gapLarge),

            // Animated Switcher between Email and Call Support
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isEmailSupport
                  ? _buildEmailSupportForm()
                  : _buildCallSupportView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSupportForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Fields Row
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Booking Reference *',
                  controller: _bookingRefController,
                  hintText: 'Eg XXXXXXX',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter booking reference';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildFormField(
                  label: 'Email *',
                  controller: _emailController,
                  hintText: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapMedium),

          // Phone Number
          _buildPhoneNumberField(),

          SizedBox(height: context.gapMedium),

          // Support Email Note
          Text.rich(
            TextSpan(
              text: 'For any feedback and escalations please write to us at ',
              style: TextStyle(
                fontSize: context.responsiveFontSize(14, 13, 12),
                color: Colors.grey[600],
              ),
              children: const [
                TextSpan(
                  text: 'info@wandernova.com',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.gapMedium),

          // Query Type
          Text(
            'Query Type: Select one of below',
            style: TextStyle(
              fontSize: context.responsiveFontSize(15, 14, 13),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.gapSmall),

          Wrap(
            spacing: context.gapSmall,
            runSpacing: context.gapSmall,
            children: _queryTypes.map((query) {
              final isSelected = _selectedQueryType == query;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedQueryType = query;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapMedium,
                    vertical: context.gapSmall,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (query == 'Cancellation' ? Colors.red[50] : Colors.blue[50])
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                    border: Border.all(
                      color: isSelected
                          ? (query == 'Cancellation' ? Colors.red[200]! : Colors.blue[200]!)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    query,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(13, 12, 11),
                      color: isSelected
                          ? (query == 'Cancellation' ? Colors.red[700] : Colors.blue[700])
                          : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: context.gapMedium),

          // Domestic/International
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _travelType = 'Domestic';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.gapMedium,
                      vertical: context.gapSmall,
                    ),
                    decoration: BoxDecoration(
                      color: _travelType == 'Domestic'
                          ? Colors.blue[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                      border: Border.all(
                        color: _travelType == 'Domestic'
                            ? Colors.blue[200]!
                            : Colors.grey[300]!,
                        width: _travelType == 'Domestic' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _travelType == 'Domestic'
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: _travelType == 'Domestic'
                              ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                              : null,
                        ),
                        SizedBox(width: context.gapSmall),
                        Text(
                          'Domestic',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14, 13, 12),
                            color: _travelType == 'Domestic'
                                ? Colors.blue[700]
                                : Colors.grey[700],
                            fontWeight: _travelType == 'Domestic'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _travelType = 'International';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.gapMedium,
                      vertical: context.gapSmall,
                    ),
                    decoration: BoxDecoration(
                      color: _travelType == 'International'
                          ? Colors.blue[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                      border: Border.all(
                        color: _travelType == 'International'
                            ? Colors.blue[200]!
                            : Colors.grey[300]!,
                        width: _travelType == 'International' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _travelType == 'International'
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: _travelType == 'International'
                              ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                              : null,
                        ),
                        SizedBox(width: context.gapSmall),
                        Text(
                          'International',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14, 13, 12),
                            color: _travelType == 'International'
                                ? Colors.blue[700]
                                : Colors.grey[700],
                            fontWeight: _travelType == 'International'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapMedium),

          // Message
          Text(
            'Type your Message Here *',
            style: TextStyle(
              fontSize: context.responsiveFontSize(15, 14, 13),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.gapSmall),

          // Message Box and File Upload in Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message Text Field
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your Message Here',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: context.responsiveFontSize(14, 13, 12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.all(context.gapMedium),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  return null;
                },
              ),

              SizedBox(height: context.gapMedium),

              // File Upload Area
              Align(
                alignment: Alignment.bottomRight,
                  child: _buildFileUploadArea()
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitSupportForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: EdgeInsets.symmetric(
                  vertical: context.gapMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                ),
              ),
              child: Text(
                'SEND',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16, 15, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallSupportView() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.gapXLarge * 2,
        horizontal: context.gapLarge,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.headset_mic_outlined,
            size: context.isMobile ? 60 : 80,
            color: Colors.blue[700],
          ),
          SizedBox(height: context.gapLarge),
          ElevatedButton(
            onPressed: () {
              // Handle call support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact numbers are not configured. Please use Email Support.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(20),
                vertical: context.gapMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusSmall),
              ),
            ),
            child: Text(
              'For Assistance',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16, 15, 14),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Contact numbers are not configured.\nPlease use Email Support.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.responsiveFontSize(14, 13, 12),
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTypeTab(String label, IconData icon, bool isEmail) {
    final isSelected = _isEmailSupport == isEmail;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isEmailSupport = isEmail;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: context.gapMedium),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(context.borderRadiusSmall),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: context.isMobile ? 22 : 24,
            ),
            SizedBox(height: context.gapXXSmall),
            Text(
              label,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14, 13, 12),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsiveFontSize(15, 14, 13),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: context.gapSmall),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: context.responsiveFontSize(14, 13, 12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapSmall,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number *',
          style: TextStyle(
            fontSize: context.responsiveFontSize(15, 14, 13),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: context.gapSmall),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.gapSmall),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.borderRadiusSmall),
                  bottomLeft: Radius.circular(context.borderRadiusSmall),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 44,

                    child: Center(
                      child: Text(
                        '🇮🇳',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: context.gapXXSmall),
                  const Text('+91'),
                  Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: context.responsiveFontSize(14, 13, 12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(context.borderRadiusSmall),
                      bottomRight: Radius.circular(context.borderRadiusSmall),
                    ),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(context.borderRadiusSmall),
                      bottomRight: Radius.circular(context.borderRadiusSmall),
                    ),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(context.borderRadiusSmall),
                      bottomRight: Radius.circular(context.borderRadiusSmall),
                    ),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.gapMedium,
                    vertical: context.gapSmall,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter valid phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.gapLarge),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(
            context.borderRadiusSmall,
          ),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isPickingFile
                ? SizedBox(
              width: context.isMobile ? 28 : 32,
              height: context.isMobile ? 28 : 32,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : Icon(
              Icons.cloud_upload_outlined,
              size: context.isMobile ? 35 : 40,
              color: Colors.grey[400],
            ),

            SizedBox(height: context.gapSmall),

            Text(
              _selectedFile == null
                  ? 'Drag and drop file OR'
                  : _selectedFile!.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsiveFontSize(
                  13,
                  12,
                  11,
                ),
                color: _selectedFile == null
                    ? Colors.grey[600]
                    : Colors.green[700],
                fontWeight: _selectedFile == null
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),

            SizedBox(height: context.gapSmall),

            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapMedium,
                  vertical: context.gapXXSmall,
                ),
              ),
              child: Text(
                _selectedFile == null
                    ? 'Browse'
                    : 'Change File',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(
                    12,
                    11,
                    10,
                  ),
                  color: Colors.white,
                ),
              ),
            ),

            if (_selectedFile != null) ...[
              SizedBox(height: context.gapSmall),

              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red,
                ),
                label: Text(
                  'Remove File',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: context.responsiveFontSize(
                      12,
                      11,
                      10,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitSupportForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedQueryType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a query type'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Handle form submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your support request has been submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}