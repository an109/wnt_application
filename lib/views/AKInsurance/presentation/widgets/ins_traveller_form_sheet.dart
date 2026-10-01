import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../state/ins_booking_details.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';
import 'ins_form_field.dart';

/// The editor behind the pencil on each "Travellers" row of the review
/// screen: name, title, gender, date of birth, passport and — for a student
/// policy — the university block the provider asks for.
class InsTravellerFormSheet extends StatefulWidget {
  final InsBookingTraveller traveller;
  final int index;
  final bool isStudent;

  /// The lead traveller is always "Self", so their relationship is fixed.
  final bool lockRelation;

  const InsTravellerFormSheet({
    super.key,
    required this.traveller,
    required this.index,
    required this.isStudent,
    required this.lockRelation,
  });

  static Future<InsBookingTraveller?> show(
    BuildContext context, {
    required InsBookingTraveller traveller,
    required int index,
    required bool isStudent,
    required bool lockRelation,
  }) {
    return showModalBottomSheet<InsBookingTraveller>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
      builder: (_) => InsTravellerFormSheet(
        traveller: traveller,
        index: index,
        isStudent: isStudent,
        lockRelation: lockRelation,
      ),
    );
  }

  @override
  State<InsTravellerFormSheet> createState() => _InsTravellerFormSheetState();
}

class _InsTravellerFormSheetState extends State<InsTravellerFormSheet> {
  late final _first = TextEditingController(text: widget.traveller.firstName);
  late final _last = TextEditingController(text: widget.traveller.lastName);
  late final _passport = TextEditingController(text: widget.traveller.passport);
  late final _university =
      TextEditingController(text: widget.traveller.university);
  late final _sponsor = TextEditingController(text: widget.traveller.sponsor);
  late final _guardian = TextEditingController(text: widget.traveller.guardian);

  late String _title = widget.traveller.title;
  late String _gender = widget.traveller.gender;
  late String _relationship = widget.traveller.relationship;
  late DateTime? _dob = widget.traveller.dob;

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _passport,
      _university,
      _sponsor,
      _guardian,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 80, now.month, now.day),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: InsTokens.blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _save() {
    if (_first.text.trim().isEmpty) {
      insSnack(context, 'Enter a first name', isError: true);
      return;
    }
    if (_last.text.trim().isEmpty) {
      insSnack(context, 'Enter a last name', isError: true);
      return;
    }
    if (_dob == null) {
      insSnack(context, 'Select a date of birth', isError: true);
      return;
    }

    Navigator.of(context).pop(
      widget.traveller.copyWith(
        title: _title,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        gender: _gender,
        dob: _dob,
        passport: _passport.text.trim(),
        relationship: _relationship,
        university: _university.text.trim(),
        sponsor: _sponsor.text.trim(),
        guardian: _guardian.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                const InsSheetHandle(),
                Positioned(
                  right: context.w(8),
                  top: context.h(2),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(context.w(8)),
                      child: Icon(Icons.close_rounded,
                          size: context.w(22), color: InsTokens.navy),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.w(18),
                  context.h(16),
                  context.w(18),
                  context.h(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Traveller ${widget.index + 1}',
                      style: TextStyle(
                        fontSize: context.fs(19),
                        fontWeight: FontWeight.w700,
                        color: InsTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(18)),
                    Row(
                      children: [
                        SizedBox(
                          width: context.w(104),
                          child: InsDropdown(
                            label: 'Title',
                            value: _title,
                            options: InsOptions.titles,
                            onChanged: (v) => setState(() {
                              _title = v;
                              // Keep gender consistent with the title the
                              // traveller picked, which is what the provider
                              // validates against.
                              _gender = v == 'Mr' ? 'Male' : 'Female';
                            }),
                          ),
                        ),
                        SizedBox(width: context.w(10)),
                        Expanded(
                          child: InsField(
                            label: 'First Name',
                            required: true,
                            controller: _first,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(14)),
                    InsField(
                      label: 'Last Name',
                      required: true,
                      controller: _last,
                    ),
                    SizedBox(height: context.h(14)),
                    Row(
                      children: [
                        Expanded(
                          child: InsPickerField(
                            label: 'Date of Birth',
                            required: true,
                            value: _dob == null
                                ? null
                                : DateFormat('dd/MM/yyyy').format(_dob!),
                            onTap: _pickDob,
                          ),
                        ),
                        SizedBox(width: context.w(10)),
                        Expanded(
                          child: InsDropdown(
                            label: 'Gender',
                            required: true,
                            value: _gender,
                            options: InsOptions.genders,
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(14)),
                    InsField(
                      label: 'Passport Number',
                      controller: _passport,
                      hint: 'Z1234567',
                    ),
                    if (!widget.lockRelation) ...[
                      SizedBox(height: context.h(14)),
                      InsDropdown(
                        label: 'Relationship',
                        value: _relationship,
                        // A FRIENDS policy carries "Member", which is not in
                        // the general enum — keep whatever the search set so
                        // the dropdown never opens on an empty value.
                        options: {
                          _relationship,
                          ...InsOptions.travellerRelations,
                        }.toList(),
                        onChanged: (v) => setState(() => _relationship = v),
                      ),
                    ],
                    if (widget.isStudent) ...[
                      SizedBox(height: context.h(20)),
                      Text(
                        'Student details',
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w700,
                          color: InsTokens.navy,
                        ),
                      ),
                      SizedBox(height: context.h(12)),
                      InsField(
                        label: 'University',
                        controller: _university,
                      ),
                      SizedBox(height: context.h(14)),
                      InsField(label: 'Sponsor', controller: _sponsor),
                      SizedBox(height: context.h(14)),
                      InsField(label: 'Guardian', controller: _guardian),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(18),
                context.h(12),
                context.w(18),
                context.h(14),
              ),
              child: InsPrimaryButton(label: 'SAVE', onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}
