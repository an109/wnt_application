import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/Dashboard/Section/data/support_api_service.dart';

/// Palette lifted from the Customer Support design.
const _kBlue = AppColors.AppBlue; // #00A1E4
const _kOrange = AppColors.OrangeColor; // #FF6600
const _kInk = AppColors.black;
const _kSubtle = Color(0xFF6E6E73);
const _kBorder = Color(0xFFE6E6E6);
const _kLabel = AppColors.subhead;
const _kHint = Color(0xFF9A9A9F);
const _kFieldIcon = Color(0xFFC3C3C7);
const _kToggleTrack = Color(0xFFF4F4F5);
const _kToggleIdle = Color(0xFFBFBFC4);
const _kScopeBg = Color(0xFFF0FBFF);
const _kUploadCircle = Color(0xFFE6F5FD);
const _kDash = Color(0xFFCDCDD2);
const _kPeach = Color(0xFFFFEDE0);
const _kGreenBg = Color(0xFFE7F8EB);
const _kGreen = Color(0xFF34C759);
const _kCardStroke = Color(0xFFEDEDF0);

class _Dial {
  final String flag;
  final String code;
  final String country;

  const _Dial(this.flag, this.code, this.country);
}

class CustomerSupportSection extends StatefulWidget {
  const CustomerSupportSection({super.key});

  @override
  State<CustomerSupportSection> createState() => _CustomerSupportSectionState();
}

class _CustomerSupportSectionState extends State<CustomerSupportSection> {
  static const String _supportNumber = '1800-102-3555';

  static const List<_Dial> _dials = [
    _Dial('🇮🇳', '+91', 'India'),
    _Dial('🇦🇪', '+971', 'UAE'),
    _Dial('🇺🇸', '+1', 'United States'),
    _Dial('🇬🇧', '+44', 'United Kingdom'),
    _Dial('🇸🇬', '+65', 'Singapore'),
    _Dial('🇦🇺', '+61', 'Australia'),
    _Dial('🇸🇦', '+966', 'Saudi Arabia'),
    _Dial('🇶🇦', '+974', 'Qatar'),
  ];

  bool _isEmailSupport = true;
  final _formKey = GlobalKey<FormState>();
  String _travelType = 'Domestic';
  _Dial _dial = _dials.first;

  final _bookingRefController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _queryController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isPickingFile = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bookingRefController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSegmentedToggle(),
        SizedBox(height: context.w(32)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
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
              ? KeyedSubtree(
                  key: const ValueKey('email'),
                  child: _buildEmailSupportForm(),
                )
              : KeyedSubtree(
                  key: const ValueKey('call'),
                  child: _buildCallSupportView(),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- toggle

  Widget _buildSegmentedToggle() {
    final height = context.w(48);
    final radius = height / 2;

    return Container(
      height: height,
      padding: EdgeInsets.all(context.w(8)),
      decoration: BoxDecoration(
        color: _kToggleTrack,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              label: 'Email',
              icon: Icons.email,
              isSelected: _isEmailSupport,
              radius: radius - context.w(4),
              onTap: () => setState(() => _isEmailSupport = true),
            ),
          ),
          Expanded(
            child: _buildSegment(
              label: 'Call',
              icon: Icons.call,
              isSelected: !_isEmailSupport,
              radius: radius - context.w(4),
              onTap: () => setState(() => _isEmailSupport = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required double radius,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: context.w(18),
                color: isSelected ? _kBlue : _kToggleIdle,
              ),
            ),
            SizedBox(width: context.w(8)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
                color: isSelected ? _kBlue : _kToggleIdle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ email form

  Widget _buildEmailSupportForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOutlinedField(
            label: 'AT - BOOKING REFERENCE',
            controller: _bookingRefController,
            hintText: 'AT 98765',
            icon: Icons.confirmation_number_sharp,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter booking reference';
              }
              return null;
            },
          ),
          SizedBox(height: context.w(20)),
          _buildOutlinedField(
            label: 'EMAIL ADDRESS',
            controller: _emailController,
            hintText: 'your@email.com',
            icon: Icons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@')) {
                return 'Please enter valid email';
              }
              return null;
            },
          ),
          SizedBox(height: context.w(20)),
          _buildPhoneNumberField(),
          SizedBox(height: context.w(28)),
          _buildTripScope(),
          SizedBox(height: context.w(20)),
          _buildOutlinedField(
            label: 'QUERY TYPE',
            controller: _queryController,
            hintText: 'Enter your query type.....',
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe your query';
              }
              return null;
            },
          ),
          SizedBox(height: context.w(22)),
          _buildAttachmentBox(),
          SizedBox(height: context.w(30)),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildOutlinedField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isMultiline = maxLines > 1;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      cursorColor: _kBlue,
      textAlignVertical:
      isMultiline ? TextAlignVertical.top : TextAlignVertical.center,
      style: TextStyle(
        fontSize: context.fs(11),
        fontWeight: FontWeight.w500,
        color: _kInk,
        // height: 1.3,
      ),
      decoration: _fieldDecoration(
        label: label,
        hintText: hintText,
        icon: icon,
        isMultiline: isMultiline,
      ),
      validator: validator,
    );
  }

  InputDecoration _fieldDecoration({
    String? label,
    required String hintText,
    IconData? icon,
    bool isMultiline = false,
  }) {
    final labelStyle = TextStyle(
      fontSize: context.fs(10),
      fontWeight: FontWeight.w600,
      // letterSpacing: 0.6,
      color: _kLabel,
    );

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.w(8)),
      borderSide: BorderSide(color: color, width: 0.5),
    );

    // Reserve consistent top padding for the floating label.
    final topPad = isMultiline ? context.w(20) : context.w(14);

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: labelStyle,
      floatingLabelStyle: labelStyle,
      hintStyle: TextStyle(
        fontSize: context.fs(11),
        fontWeight: FontWeight.w500,
        color: _kHint,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: context.w(18), color: _kFieldIcon),
      prefixIconConstraints: BoxConstraints(
        minWidth: context.w(44),
        minHeight: 0,
      ),
      contentPadding: EdgeInsets.only(
        left: icon == null ? context.w(16) : context.w(4),
        right: context.w(16),
        top: topPad,
        bottom: context.w(14),
      ),
      border: border(_kBorder, 1),
      enabledBorder: border(_kBorder, 1),
      focusedBorder: border(_kBlue, 1.4),
      errorBorder: border(AppColors.accent, 1),
      focusedErrorBorder: border(AppColors.accent, 1.4),
      errorMaxLines: 2,
    );
  }

  Widget _buildPhoneNumberField() {
    // Match the TextFormField's intrinsic height so the dial box lines up.
    final fieldHeight = context.w(44);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showDialPicker,
          child: Container(
            height: fieldHeight,
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.w(8)),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_dial.flag, style: TextStyle(fontSize: context.fs(14))),
                SizedBox(width: context.w(6)),
                Text(
                  _dial.code,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w500,
                    color: _kInk,
                  ),
                ),
                SizedBox(width: context.w(2)),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: context.w(20),
                  color: _kFieldIcon,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: SizedBox(
            // Force both sides to the same height.
            height: fieldHeight,
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              cursorColor: _kBlue,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: _kInk,
              ),
              decoration: _fieldDecoration(hintText: '9876543212'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                if (value.trim().length < 10) {
                  return 'Please enter valid phone number';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDialPicker() async {
    FocusScope.of(context).unfocus();

    final picked = await showModalBottomSheet<_Dial>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.w(20)),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _dials.map((dial) {
              return ListTile(
                onTap: () => Navigator.of(sheetContext).pop(dial),
                leading: Text(
                  dial.flag,
                  style: TextStyle(fontSize: context.fs(20)),
                ),
                title: Text(
                  dial.country,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                    color: _kInk,
                  ),
                ),
                trailing: Text(
                  dial.code,
                  style: TextStyle(
                    fontSize: context.fs(14.5),
                    fontWeight: FontWeight.w600,
                    color: _kSubtle,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _dial = picked);
    }
  }

  Widget _buildTripScope() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(15),
        vertical: context.w(11),
      ),
      decoration: BoxDecoration(
        color: _kScopeBg,
        borderRadius: BorderRadius.circular(context.w(8)),
      ),
      child: Row(
        children: [
          Text(
            'Trip Scope:',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
              color: _kInk,
            ),
          ),
          const Spacer(),
          _buildScopeRadio('Domestic'),
          const Spacer(),
          _buildScopeRadio('International'),
        ],
      ),
    );
  }

  Widget _buildScopeRadio(String value) {
    final isSelected = _travelType == value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _travelType = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: context.w(17),
            height: context.w(17),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _kBlue : Colors.transparent,
              border: isSelected
                  ? null
                  : Border.all(color: _kHint, width: 1.6),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: context.w(7),
                      height: context.w(7),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: context.w(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w500,
              color: isSelected ? _kInk : _kSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBox() {
    final hasFile = _selectedFile != null;

    final labelStyle = TextStyle(
      fontSize: context.fs(8),
      fontWeight: FontWeight.w600,
      // letterSpacing: 0.6,
      color: _kLabel,
    );

    // Measure the notch label so the dashed stroke can be interrupted behind
    // it, the way the outlined fields notch their own border.
    final labelPainter = TextPainter(
      text: TextSpan(text: 'ATTACHMENT', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelLeft = context.w(14);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _DashedBorderPainter(
            color: _kDash,
            radius: context.w(12),
            dashWidth: context.w(3),
            dashGap: context.w(6),
            strokeWidth: 1.2,
            gapStart: labelLeft - context.w(5),
            gapWidth: labelPainter.width + context.w(10),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.w(16),
            ),
            child: Column(
              children: [
                Container(
                  width: context.w(40),
                  height: context.w(40),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kUploadCircle,
                  ),
                  child: _isPickingFile
                      ? Padding(
                          padding: EdgeInsets.all(context.w(14)),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kBlue,
                          ),
                        )
                      : Icon(
                          Icons.cloud_upload_outlined,
                          size: context.w(20),
                          color: _kBlue,
                        ),
                ),
                SizedBox(height: context.w(14)),
                Text(
                  hasFile
                      ? _selectedFile!.name
                      : 'Attach documents / screenshots',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
                SizedBox(height: context.w(2)),
                Text(
                  'PDF, JPG, PNG up to 10MB',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w500,
                    color: _kSubtle,
                  ),
                ),
                SizedBox(height: context.w(13)),
                _buildUploadButton(hasFile),
                if (hasFile) ...[
                  SizedBox(height: context.w(4)),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedFile = null),
                    icon: Icon(
                      Icons.close_rounded,
                      size: context.w(14),
                      color: AppColors.accent,
                    ),
                    label: Text(
                      'Remove File',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: labelLeft,
          top: -labelPainter.height / 2,
          child: Text('ATTACHMENT', style: labelStyle),
        ),
      ],
    );
  }

  Widget _buildUploadButton(bool hasFile) {
    return GestureDetector(
      onTap: _isPickingFile ? null : _pickFile,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.w(6),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.w(8)),
          border: Border.all(color: _kOrange, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: context.w(12), color: _kOrange),
            SizedBox(width: context.w(8)),
            Text(
              hasFile ? 'Change File' : 'Upload File',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _kOrange,
              ),
            ),
            SizedBox(width: context.w(2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: context.w(44),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitSupportForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kOrange,
          disabledBackgroundColor: _kOrange.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.w(12)),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                height: context.w(20),
                width: context.w(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -math.pi / 12,
                    child: Icon(
                      Icons.send,
                      size: context.w(16),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Text(
                    'SEND',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w600,
                      // letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ------------------------------------------------------------- call view

  Widget _buildCallSupportView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhoneStatusCard(),
        SizedBox(height: context.w(26)),
        _buildContactCard(),
      ],
    );
  }

  Widget _buildPhoneStatusCard() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.w(11),
            height: context.w(11),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, _kBlue],
                stops: [0.15, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withOpacity(0.45),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Phone Lines Active & Ready',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                ),
                SizedBox(height: context.w(2)),
                Text(
                  'Avg. wait time: ~3 mins',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w400,
                    color: _kSubtle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(10)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.w(4),
            ),
            decoration: BoxDecoration(
              color: _kPeach,
              borderRadius: BorderRadius.circular(context.w(20)),
            ),
            child: Text(
              '24×7 Active',
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: _kOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(12)),
        border: Border.all(color: _kCardStroke, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.w(44),
                height: context.w(44),
                decoration: BoxDecoration(
                  color: _kPeach,
                  borderRadius: BorderRadius.circular(context.w(8)),
                ),
                child: Icon(
                  Icons.headset_mic_outlined,
                  size: context.w(20),
                  color: _kOrange,
                ),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.w(2),
                      ),
                      decoration: BoxDecoration(
                        color: _kGreenBg,
                        borderRadius: BorderRadius.circular(context.w(24)),
                      ),
                      child: Text(
                        'Toll-Free (All India)',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w700,
                          color: _kGreen,
                        ),
                      ),
                    ),
                    SizedBox(height: context.w(10)),
                    Text(
                      _supportNumber,
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                    SizedBox(height: context.w(8)),
                    Text(
                      'Free from all domestic networks',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w400,
                        color: _kSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.w(19)),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: context.w(44),
                  child: ElevatedButton(
                    onPressed: _callSupport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.w(12)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone,
                          size: context.w(17),
                          color: Colors.white,
                        ),
                        SizedBox(width: context.w(10)),
                        Text(
                          'CALL NOW',
                          style: TextStyle(
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w600,
                            // letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.w(12)),
              GestureDetector(
                onTap: _copySupportNumber,
                child: Container(
                  width: context.w(57),
                  height: context.w(44),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.w(8)),
                    border: Border.all(color: _kBlue, width: 0.5),
                  ),
                  child: Icon(
                    Icons.content_copy_rounded,
                    size: context.w(22),
                    color: _kBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _callSupport() async {
    final uri = Uri(
      scheme: 'tel',
      path: _supportNumber.replaceAll(RegExp(r'[^0-9+]'), ''),
    );

    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showSnack('Could not open the dialer', AppColors.accent);
    }
  }

  Future<void> _copySupportNumber() async {
    await Clipboard.setData(const ClipboardData(text: _supportNumber));
    if (!mounted) return;
    _showSnack('$_supportNumber copied', _kGreen);
  }

  // ------------------------------------------------------------- behaviour

  Future<void> _pickFile() async {
    try {
      setState(() => _isPickingFile = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = result.files.first);
        if (!mounted) return;
        _showSnack('Selected: ${_selectedFile!.name}', _kGreen);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error picking file: $e', AppColors.accent);
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _showSnack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  Future<void> _submitSupportForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final query = _queryController.text.trim();

    try {
      final response = await sl<SupportApiService>().submitSupportQuery(
        bookingReference: _bookingRefController.text.trim(),
        email: _emailController.text.trim(),
        phoneCode: _dial.code,
        phone: _phoneController.text.trim(),
        queryType: query,
        flightType: _travelType,
        message: query,
        attachment: _selectedFile,
      );

      final data = response.data;
      final queryId = data is Map ? data['query_id'] : null;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Support query submitted successfully';

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _resetSupportForm();
      _showSupportSuccessDialog(message: message, queryId: queryId);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final responseData = e.response?.data;
      final errorMessage = responseData is Map
          ? (responseData['message'] ??
              responseData['error'] ??
              'Failed to submit support query')
          : 'Failed to submit support query';
      _showSnack(errorMessage.toString(), AppColors.accent);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Failed to submit support query', AppColors.accent);
    }
  }

  void _resetSupportForm() {
    _bookingRefController.clear();
    _emailController.clear();
    _phoneController.clear();
    _queryController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _travelType = 'Domestic';
      _selectedFile = null;
    });
  }

  void _showSupportSuccessDialog({required String message, dynamic queryId}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.w(16)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isMobile ? double.infinity : 420,
            ),
            child: Padding(
              padding: EdgeInsets.all(context.w(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(12)),
                    decoration: const BoxDecoration(
                      color: _kGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: _kGreen,
                      size: context.w(40),
                    ),
                  ),
                  SizedBox(height: context.w(14)),
                  Text(
                    'Query Submitted',
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                  SizedBox(height: context.w(8)),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      color: _kSubtle,
                    ),
                  ),
                  if (queryId != null) ...[
                    SizedBox(height: context.w(6)),
                    Text(
                      'Reference ID: $queryId',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w600,
                        color: _kOrange,
                      ),
                    ),
                  ],
                  SizedBox(height: context.w(20)),
                  SizedBox(
                    width: double.infinity,
                    height: context.w(50),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kOrange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.w(10)),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
}

/// Dashed rounded rectangle used by the attachment drop zone.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  /// Horizontal span on the top edge left blank for the floating label.
  final double gapStart;
  final double gapWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
    this.gapStart = 0,
    this.gapWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final source = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    final notch = gapWidth <= 0
        ? null
        : Rect.fromLTWH(gapStart, -strokeWidth * 2, gapWidth, strokeWidth * 4);

    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        final mid = metric.getTangentForOffset((distance + next) / 2)?.position;
        if (notch == null || mid == null || !notch.contains(mid)) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next + dashGap;
      }
    }

    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gapStart != gapStart ||
        oldDelegate.gapWidth != gapWidth;
  }
}
