import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TravellerDetailsSection extends StatefulWidget {
  final String userEmail;
  final int adults;

  const TravellerDetailsSection({
    super.key,
    required this.userEmail,
    required this.adults,
  });

  @override
  State<TravellerDetailsSection> createState() =>
      TravellerDetailsSectionState();
}

class TravellerDetailsSectionState extends State<TravellerDetailsSection> {
  final List<TextEditingController> _firstNameControllers = [];
  final List<TextEditingController> _lastNameControllers = [];
  final List<TextEditingController> _dobControllers = [];
  final List<String> _selectedTitles = [];
  final List<String> _selectedGenders = [];
  final List<String> _selectedNationalities = [];
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);

  Map<String, String> getFirstAdultDataMap() {
    if (_firstNameControllers.isEmpty) {
      return {
        'title': '',
        'firstName': '',
        'lastName': '',
        'dob': '',
        'gender': 'Male',
        'nationality': 'India (IN)',
      };
    }
    return {
      'title': _selectedTitles.isNotEmpty ? _selectedTitles[0] : '',
      'firstName': _firstNameControllers[0].text.trim(),
      'lastName': _lastNameControllers[0].text.trim(),
      'dob': _dobControllers[0].text.trim(),
      'gender': _selectedGenders.isNotEmpty ? _selectedGenders[0] : 'Male',
      'nationality': _selectedNationalities.isNotEmpty ? _selectedNationalities[0] : 'India (IN)',
    };
  }

  /// Returns [title, firstName, lastName] of the first adult
  List<String> getFirstAdultData() {
    if (_firstNameControllers.isEmpty) return ['', '', ''];
    return [
      _selectedTitles.isNotEmpty ? _selectedTitles[0] : '', // No hardcoded default
      _firstNameControllers[0].text.trim(),
      _lastNameControllers[0].text.trim(),
    ];
  }

  /// Returns DOB controller for the first adult
  TextEditingController? getDobController() {
    if (_dobControllers.isEmpty) return null;
    return _dobControllers[0];
  }


  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.adults; i++) {
      _firstNameControllers.add(TextEditingController());
      _lastNameControllers.add(TextEditingController());
      _dobControllers.add(TextEditingController());
      _selectedTitles.add('');
      _selectedGenders.add('Male');
      _selectedNationalities.add('India (IN)');
    }
  }

  @override
  void dispose() {
    for (var controller in _firstNameControllers) {
      controller.dispose();
    }
    for (var controller in _lastNameControllers) {
      controller.dispose();
    }
    for (var controller in _dobControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 18 * 365),
      ), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(18),
              context.w(18),
              context.h(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Traveller Details',
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: context.h(12)),
                Container(
                  padding: EdgeInsets.all(context.w(12)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(context.r(16)),
                    border: Border.all(color: const Color(0xFFD8E7FF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: _blue, size: context.w(18)),
                      SizedBox(width: context.w(8)),
                      Expanded(
                        child: Text(
                          'Please make sure you enter the Name as per your Government photo id.',
                          style: TextStyle(
                            fontSize: context.fs(13),
                            color: _navy,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(
            widget.adults,
                (index) => _buildAdultForm(context, index),
          ),
        ],
      ),
    );
  }

  Widget _buildAdultForm(BuildContext context, int index) {
    return ExpansionTile(
      initiallyExpanded: index == 0,
      title: Text(
        'Room 1 — Adult ${index + 1}',
        style: TextStyle(
          fontSize: context.fs(15),
          fontWeight: FontWeight.w800,
          color: _navy,
        ),
      ),
      children: [
        Padding(
          padding: context.responsivePadding.copyWith(
            top: 0,
            bottom: context.h(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + First Name (2 fields)
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      context,
                      'Title *',
                      ['Mr', 'Mrs', 'Ms', 'Dr'],
                      _selectedTitles[index],
                          (value) {
                        setState(() {
                          _selectedTitles[index] = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: _buildTextField(
                      context,
                      'First Name/Given Name *',
                      _firstNameControllers[index],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(16)),

              // Row 2: Last Name + Gender (2 fields)
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      'Last Name/Surname *',
                      _lastNameControllers[index],
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: _buildDropdownField(
                      context,
                      'Gender *',
                      ['Male', 'Female', 'Other'],
                      _selectedGenders[index],
                          (value) {
                        setState(() {
                          _selectedGenders[index] = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(16)),

              // Row 3: Date of Birth + Nationality (2 fields)
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      context,
                      'Date of Birth *',
                      _dobControllers[index],
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: _buildDropdownField(
                      context,
                      'Nationality *',
                      ['India (IN)', 'USA (US)', 'UAE (AE)', 'UK (GB)'],
                      _selectedNationalities[index],
                          (value) {
                        setState(() {
                          _selectedNationalities[index] = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      BuildContext context,
      String label,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(12),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.h(4)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      BuildContext context,
      String label,
      List<String> items,
      String value,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(12),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(12)),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Text('Select', style: TextStyle(color: Colors.grey[400])),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: context.fs(14))),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context,
      String label,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(12),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.h(4)),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            suffixIcon: Icon(
              Icons.calendar_today,
              size: context.w(18),
              color: Colors.grey[600],
            ),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }
}