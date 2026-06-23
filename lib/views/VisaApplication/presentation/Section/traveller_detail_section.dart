import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TravellerDetailsSection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final Map<String, dynamic>? preFilledData;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onSave;
  final bool isLoading;

  const TravellerDetailsSection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    this.preFilledData,
    required this.onContinue,
    required this.onBack,
    required this.onSave,
    this.isLoading = false, // Default to false
  }) : super(key: key);

  @override
  State<TravellerDetailsSection> createState() => _TravellerDetailsSectionState();
}

class _TravellerDetailsSectionState extends State<TravellerDetailsSection> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isExpanded = true;

  // Form Fields
  String _title = 'Mr';
  String _firstName = '';
  String _lastName = '';
  DateTime? _dob;
  String _nationality = 'Indian';
  String _passportNo = '';
  String _phone = '';
  String _email = '';

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    if (widget.preFilledData != null) {
      _title = widget.preFilledData!['title'] ?? 'Mr';
      _firstName = widget.preFilledData!['firstName'] ?? '';
      _lastName = widget.preFilledData!['lastName'] ?? '';
      _dob = widget.preFilledData!['dob'];
      _nationality = widget.preFilledData!['nationality'] ?? 'Indian';
      _passportNo = widget.preFilledData!['passportNo'] ?? '';
      _phone = widget.preFilledData!['phone'] ?? '';
      _email = widget.preFilledData!['email'] ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant TravellerDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _isExpanded = widget.isActive;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (widget.isCompleted || widget.isActive) _toggleExpand();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: widget.isActive ? const Color(0xffE3F2FD) : widget.isCompleted ? Colors.green.shade50 : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: context.w(24),
                    height: context.w(24),
                    decoration: BoxDecoration(
                      color: widget.isCompleted ? Colors.green : widget.isActive ? const Color(0xff0D47A1) : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.isCompleted
                          ? Icon(Icons.check, size: context.iconXSmall, color: Colors.white)
                          : Text('${widget.stepNumber}', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  Expanded(child: Text('Traveller Details', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600))),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(Icons.keyboard_arrow_down, size: context.iconMedium, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightAnimation,
            axisAlignment: -1.0,
            child: ClipRect(
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: EdgeInsets.all(context.w(12)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(flex: 1, child: _buildDropdownField('Title', ['Mr', 'Mrs', 'Ms', 'Dr'], _title, (val) => setState(() => _title = val!))),
                SizedBox(width: context.w(8)),
                Expanded(flex: 2, child: _buildTextField('First Name *', _firstName, (val) => _firstName = val!, validator: (val) => val!.isEmpty ? 'Required' : null)),
              ],
            ),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField('Last Name *', _lastName, (val) => _lastName = val!, validator: (val) => val!.isEmpty ? 'Required' : null)),
                SizedBox(width: context.w(8)),
                Expanded(flex: 2, child: _buildDateField('Date of Birth *', _dob, () => _selectDate())),
              ],
            ),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                Expanded(child: _buildTextField('Nationality', _nationality, (val) => _nationality = val!)),
                SizedBox(width: context.w(8)),
                Expanded(child: _buildTextField('Passport No *', _passportNo, (val) => _passportNo = val!, validator: (val) => val!.isEmpty ? 'Required' : null)),
              ],
            ),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                Expanded(child: _buildTextField('Phone *', _phone, (val) => _phone = val!, validator: (val) => val!.isEmpty ? 'Required' : null)),
                SizedBox(width: context.w(8)),
                Expanded(child: _buildTextField('Email *', _email, (val) => _email = val!, validator: (val) => val!.isEmpty ? 'Required' : null)),
              ],
            ),
            SizedBox(height: context.h(16)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading ? null : widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xff0D47A1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(6))),
                      padding: EdgeInsets.symmetric(vertical: context.h(10)),
                    ),
                    child: Text('BACK', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600, color: const Color(0xff0D47A1))),
                  ),
                ),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D47A1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(6))),
                      padding: EdgeInsets.symmetric(vertical: context.h(10)),
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                      width: context.w(16),
                      height: context.w(16),
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                        : Text('CONTINUE', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged, {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.r(6)), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.r(6)), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
          style: TextStyle(fontSize: context.fs(11)),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(6)), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: context.iconSmall),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(fontSize: context.fs(11))))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(6)), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: context.iconSmall, color: Colors.grey.shade600),
                SizedBox(width: context.w(6)),
                Expanded(child: Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'dd/mm/yyyy', style: TextStyle(fontSize: context.fs(11), color: date != null ? Colors.black87 : Colors.grey.shade500))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'title': _title,
        'firstName': _firstName,
        'lastName': _lastName,
        'dob': _dob,
        'nationality': _nationality,
        'passportNo': _passportNo,
        'phone': _phone,
        'email': _email,
      });
      widget.onContinue();
    }
  }
}