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
  State<TravellerDetailsSection> createState() => _TravellerDetailsSectionState();
}

class _TravellerDetailsSectionState extends State<TravellerDetailsSection> {
  final List<TextEditingController> _firstNameControllers = [];
  final List<TextEditingController> _lastNameControllers = [];
  final List<TextEditingController> _dobControllers = [];
  final List<String> _selectedTitles = [];
  final List<String> _selectedGenders = [];
  final List<String> _selectedNationalities = [];

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

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 18 * 365)), // 18 years ago
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
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Traveller Details',
                  style: TextStyle(
                    fontSize: context.headlineSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: context.sp(16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please make sure you enter the Name as per your Government photo id.',
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(widget.adults, (index) => _buildAdultForm(context, index)),
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
          fontSize: context.titleMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: context.responsivePadding.copyWith(top: 0, bottom: 16),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      context,
                      'First Name/Given Name *',
                      _firstNameControllers[index],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 16),

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
                  const SizedBox(width: 12),
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

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.sp(12),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
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
            fontSize: context.sp(12),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(
                'Select',
                style: TextStyle(color: Colors.grey[400]),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(fontSize: context.sp(14)),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.sp(12),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            suffixIcon: Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }
}