import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class ItinerarySection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final String destination;
  final dynamic visaType;
  final Map<String, dynamic>? preFilledData;
  final VoidCallback onContinue;
  final Function(Map<String, dynamic>) onSave;

  const ItinerarySection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.destination,
    required this.visaType,
    this.preFilledData,
    required this.onContinue,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ItinerarySection> createState() => _ItinerarySectionState();
}

class _ItinerarySectionState extends State<ItinerarySection> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVisaType;
  DateTime? _onwardDate;
  DateTime? _returnDate;
  String _travellers = '1';
  bool _isExpanded = true;

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;
    _selectedVisaType = widget.visaType?.title;

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
      _onwardDate = widget.preFilledData!['onwardDate'];
      _returnDate = widget.preFilledData!['returnDate'];
      _travellers = widget.preFilledData!['travellers']?.toString() ?? '1';
    }
  }

  @override
  void didUpdateWidget(covariant ItinerarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto expand when this step becomes active, collapse when it isn't.
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
                  Expanded(child: Text('Itinerary', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600))),
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
            _buildVisaTypeDropdown(),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                Expanded(child: _buildDateField(label: 'Onward Date *', date: _onwardDate, onTap: () => _selectDate(true))),
                SizedBox(width: context.w(8)),
                Expanded(child: _buildDateField(label: 'Return Date *', date: _returnDate, onTap: () => _selectDate(false))),
              ],
            ),
            SizedBox(height: context.h(12)),
            _buildTravellersDropdown(),
            SizedBox(height: context.h(16)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(6))),
                  padding: EdgeInsets.symmetric(vertical: context.h(10)),
                ),
                child: Text('CONTINUE', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisaTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visa type *', style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(6)), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedVisaType,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: context.iconSmall),
              items: widget.visaType != null
                  ? [DropdownMenuItem<String>(value: widget.visaType.title, child: Text(widget.visaType.title, style: TextStyle(fontSize: context.fs(11))))]
                  : [],
              onChanged: null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({required String label, required DateTime? date, required VoidCallback onTap}) {
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

  Widget _buildTravellersDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Travellers', style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(6)), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _travellers,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: context.iconSmall),
              items: List.generate(10, (i) => '${i + 1}')
                  .map((num) => DropdownMenuItem<String>(value: num, child: Text(num == '1' ? '1 Traveller' : '$num Travellers', style: TextStyle(fontSize: context.fs(11)))))
                  .toList(),
              onChanged: null,
              // onChanged: (value) => setState(() => _travellers = value!),
            ),
          ),
        ),
      ],
    );
  }

  // Future<void> _selectDate(bool isOnward) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime.now(),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       if (isOnward) _onwardDate = picked;
  //       else _returnDate = picked;
  //     });
  //   }
  // }
  Future<void> _selectDate(bool isOnward) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isOnward
          ? (_onwardDate ?? DateTime.now())  // Use current onward date if exists
          : (_returnDate ?? DateTime.now()), // Use current return date if exists
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isOnward) {
          _onwardDate = picked;
          // Auto-set return date to one month after onward date
          final DateTime newReturnDate = DateTime(picked.year, picked.month + 1, picked.day);
          // Handle year overflow if month is December
          if (newReturnDate.month > 12) {
            _returnDate = DateTime(picked.year + 1, newReturnDate.month - 12, picked.day);
          } else {
            _returnDate = newReturnDate;
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'visaType': _selectedVisaType,
        'onwardDate': _onwardDate,
        'returnDate': _returnDate,
        'travellers': int.tryParse(_travellers) ?? 1,
      });
      widget.onContinue();
    }
  }
}