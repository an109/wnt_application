import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';

class FilterChips extends StatefulWidget {
  final Function(String) onFilterSelected;

  const FilterChips({super.key, required this.onFilterSelected});

  @override
  State<FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<FilterChips> {
  String? _selectedFilter;

  final List<Map<String, dynamic>> _filters = [
    {'name': 'All Filters', 'icon': Icons.tune},
      {'name': 'Duration', 'icon': Icons.timer_outlined},
        {'name': 'Flights', 'icon': Icons.flight_outlined},
          {'name': 'Budget', 'icon': Icons.attach_money},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.hp(5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['name'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = isSelected ? null : filter['name'];
              });
              widget.onFilterSelected(filter['name']);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(3),
                // vertical: context.hp(1),
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.lightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'],
                    size: context.iconXSmall,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  SizedBox(width: context.gapXXSmall),
                  Text(
                    filter['name'],
                    style: TextStyle(
                      fontSize: context.labelMedium,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (filter['name'] != 'All Filters') ...[
                    SizedBox(width: context.gapXXSmall),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: context.iconXSmall,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}