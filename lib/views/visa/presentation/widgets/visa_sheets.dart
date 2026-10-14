import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/visa_countries.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import 'visa_calendar.dart';

/// Holiday date range picker (Figma "Holiday T…"). Pops a [DateTimeRange].
class VisaHolidaySheet extends StatefulWidget {
  final DateTimeRange? initial;
  const VisaHolidaySheet({super.key, this.initial});

  @override
  State<VisaHolidaySheet> createState() => _VisaHolidaySheetState();
}

class _VisaHolidaySheetState extends State<VisaHolidaySheet> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.start;
    _end = widget.initial?.end;
    _month = _start ?? DateTime.now();
  }

  void _tap(DateTime d) {
    setState(() {
      if (_start == null || _end != null || d.isBefore(_start!)) {
        _start = d;
        _end = null;
      } else {
        _end = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VisaMonthSwitcher(
            month: _month,
            firstMonth: DateTime.now(),
            onChanged: (m) => setState(() => _month = m),
          ),
          const SizedBox(height: 8),
          VisaMonthGrid(
            month: _month,
            start: _start,
            end: _end,
            firstDate: DateTime.now(),
            onTap: _tap,
          ),
          const Divider(height: 24, color: VisaColors.divider),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: VisaColors.green),
                        const SizedBox(width: 4),
                        Text('Guaranteed visas before', style: visaText(10, color: VisaColors.text)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _start == null ? 'Pick your travel dates' : visaOrdinalDate(_start!),
                      style: visaText(13, weight: FontWeight.w700, color: VisaColors.title),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 112,
                height: 38,
                child: ElevatedButton(
                  onPressed: _start == null
                      ? null
                      : () => Navigator.pop(
                            context,
                            DateTimeRange(start: _start!, end: _end ?? _start!),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VisaColors.cta,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('SELECT', style: visaText(12, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single date picker (Figma "Date visa"). Pops a [DateTime].
class VisaDatePickerSheet extends StatefulWidget {
  final DateTime? initial;
  final DateTime firstDate;
  final DateTime lastDate;

  const VisaDatePickerSheet({
    super.key,
    this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<VisaDatePickerSheet> createState() => _VisaDatePickerSheetState();
}

class _VisaDatePickerSheetState extends State<VisaDatePickerSheet> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    var initial = widget.initial ?? now;
    if (initial.isBefore(widget.firstDate)) initial = widget.firstDate;
    if (initial.isAfter(widget.lastDate)) initial = widget.lastDate;
    _selected = initial;
    _month = DateTime(initial.year, initial.month);
  }

  Future<void> _pickYear() async {
    final years = [for (var y = widget.lastDate.year; y >= widget.firstDate.year; y--) y];
    final year = await showVisaSheet<int>(
      context,
      VisaOptionList<int>(
        options: years,
        labelOf: (y) => '$y',
        selected: _month.year,
      ),
    );
    if (year != null) setState(() => _month = DateTime(year, _month.month));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select date', style: visaText(11, color: VisaColors.text)),
          const SizedBox(height: 10),
          Text(
            DateFormat('EEE, MMM d').format(_selected),
            style: visaText(24, weight: FontWeight.w500, color: VisaColors.title),
          ),
          const Divider(height: 24, color: VisaColors.divider),
          Row(
            children: [
              InkWell(
                onTap: _pickYear,
                child: Row(
                  children: [
                    Text(DateFormat('MMMM yyyy').format(_month),
                        style: visaText(12, weight: FontWeight.w600, color: VisaColors.text)),
                    const Icon(Icons.arrow_drop_down, color: VisaColors.text),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VisaMonthGrid(
            month: _month,
            start: _selected,
            mondayFirst: false,
            circleSelection: true,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onTap: (d) {
              setState(() => _selected = d);
              Navigator.pop(context, d);
            },
          ),
        ],
      ),
    );
  }
}

/// Plain option list (Figma "Gender visa"). Pops the tapped option.
class VisaOptionList<T> extends StatelessWidget {
  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final Widget Function(T)? leadingOf;

  const VisaOptionList({
    super.key,
    required this.options,
    required this.labelOf,
    this.selected,
    this.leadingOf,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      itemCount: options.length,
      itemBuilder: (_, i) {
        final o = options[i];
        final isSelected = o == selected;
        return InkWell(
          onTap: () => Navigator.pop(context, o),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                if (leadingOf != null) ...[leadingOf!(o), const SizedBox(width: 10)],
                Expanded(
                  child: Text(
                    labelOf(o),
                    style: visaText(12,
                        weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? VisaColors.primary : VisaColors.title),
                  ),
                ),
                if (isSelected) const Icon(Icons.check, size: 18, color: VisaColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Searchable list (Figma "Location in -" and "Passport from"). When
/// [allowCustom] is set, a typed value that is not in the list can be used.
class VisaSearchList extends StatefulWidget {
  final List<String> options;
  final String? selected;
  final bool allowCustom;
  final Widget Function(String)? leadingOf;

  const VisaSearchList({
    super.key,
    required this.options,
    this.selected,
    this.allowCustom = false,
    this.leadingOf,
  });

  @override
  State<VisaSearchList> createState() => _VisaSearchListState();
}

class _VisaSearchListState extends State<VisaSearchList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.options
        : widget.options.where((o) => o.toLowerCase().contains(q)).toList();
    final showCustom = widget.allowCustom &&
        q.isNotEmpty &&
        !widget.options.any((o) => o.toLowerCase() == q);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: widget.options.isEmpty,
              onChanged: (v) => setState(() => _query = v),
              style: visaText(12, color: VisaColors.title),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                hintStyle: visaText(11, color: VisaColors.text),
                prefixIcon: const Icon(Icons.search, size: 18, color: VisaColors.text),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: VisaColors.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: VisaColors.primary),
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (showCustom)
                  _row(_query.trim(), prefix: 'Use "', suffix: '"'),
                for (final o in items) _row(o),
                if (items.isEmpty && !showCustom)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.allowCustom ? 'Type to add your answer' : 'No results',
                      textAlign: TextAlign.center,
                      style: visaText(12, color: VisaColors.text),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String value, {String prefix = '', String suffix = ''}) {
    final selected = value == widget.selected;
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            if (widget.leadingOf != null) ...[widget.leadingOf!(value), const SizedBox(width: 10)],
            Expanded(
              child: Text('$prefix$value$suffix',
                  style: visaText(12, color: selected ? VisaColors.primary : VisaColors.title)),
            ),
            if (selected) const Icon(Icons.check, size: 18, color: VisaColors.primary),
          ],
        ),
      ),
    );
  }
}

/// "Passport from" picker: country list with flags.
Future<String?> pickVisaCountry(BuildContext context, {String? selected}) {
  final byName = {for (final c in visaCountries) c.name: c};
  return showVisaSheet<String>(
    context,
    VisaSearchList(
      options: visaCountries.map((c) => c.name).toList(),
      selected: selected,
      leadingOf: (name) => Text(byName[name]?.emoji ?? '🏳️', style: const TextStyle(fontSize: 16)),
    ),
  );
}
