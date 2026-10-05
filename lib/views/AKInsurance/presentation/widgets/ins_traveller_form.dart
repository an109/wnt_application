import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../state/ins_booking_details.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';
import 'ins_form_field.dart';

/// The traveller editor on the review screen — Figma `insurance Individual
/// review`.
///
/// Drops open in place inside the "Travellers" card rather than taking over
/// the screen in a sheet, so the party stays visible while one of them is
/// being filled in: gender, name, date of birth, relationship, passport and
/// nationality, then a Save link. A student policy adds the university block
/// the provider asks for underneath.
///
/// Owns its own controllers so the row's text survives the parent's rebuilds
/// and is disposed when the form collapses.
class InsTravellerForm extends StatefulWidget {
  final InsBookingTraveller traveller;
  final int index;
  final bool isStudent;

  /// The lead traveller is always "Self", so their relationship is fixed.
  final bool lockRelation;

  final ValueChanged<InsBookingTraveller> onSaved;

  const InsTravellerForm({
    super.key,
    required this.traveller,
    required this.index,
    required this.isStudent,
    required this.lockRelation,
    required this.onSaved,
  });

  @override
  State<InsTravellerForm> createState() => _InsTravellerFormState();
}

class _InsTravellerFormState extends State<InsTravellerForm> {
  late final _first = TextEditingController(text: widget.traveller.firstName);
  late final _last = TextEditingController(text: widget.traveller.lastName);
  late final _passport = TextEditingController(text: widget.traveller.passport);
  late final _university =
      TextEditingController(text: widget.traveller.university);
  late final _sponsor = TextEditingController(text: widget.traveller.sponsor);
  late final _guardian = TextEditingController(text: widget.traveller.guardian);

  late String _gender = widget.traveller.gender;
  late String _relationship = widget.traveller.relationship;
  late DateTime? _dob = widget.traveller.dob;

  /// Male / Female are what the provider's schema takes; "Other" is offered
  /// because the form does, and rides along as Male in [genderCode] — the
  /// provider has no third value to send it as.
  static const _genders = ['Male', 'Female', 'Other'];

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

  List<String> get _relationOptions => widget.lockRelation
      ? const ['Self']
      // A FRIENDS policy carries "Member", which is not in the general enum —
      // keep whatever the search set so the dropdown never opens on an empty
      // value.
      : {_relationship, ...InsOptions.travellerRelations}.toList();

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

    widget.onSaved(
      widget.traveller.copyWith(
        // Title is not asked for here; keep it in step with the gender so the
        // provider never sees a Mr/Female pair.
        title: _gender == 'Female' ? 'Ms' : 'Mr',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRAVELLERS ${widget.index + 1}',
          style: TextStyle(
            fontSize: context.fs(10),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: InsTokens.subGrey,
          ),
        ),
        SizedBox(height: context.h(14)),
        _genderRow(context),
        SizedBox(height: context.h(14)),
        Row(
          children: [
            Expanded(
              child: InsField(
                label: 'First Name',
                required: true,
                controller: _first,
                prefix: _prefixIcon(context, Icons.person),
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: InsField(
                label: 'Last Name',
                required: true,
                controller: _last,
                prefix: _prefixIcon(context, Icons.person),
              ),
            ),
          ],
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
                hint: 'dd/mm/yyyy',
                onTap: _pickDob,
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: InsDropdown(
                label: 'Relationship',
                required: true,
                value: _relationship,
                options: _relationOptions,
                onChanged: (v) => setState(() => _relationship = v),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(14)),
        // Nationality is the Customer's, not the traveller's — the provider's
        // traveller block has no field for it, so it is asked once on the
        // Proposer card instead of once per row.
        InsField(
          label: 'Passport Number',
          required: true,
          controller: _passport,
          hint: 'Z1234567',
          prefix: _prefixIcon(context, Icons.badge_outlined),
        ),
        if (widget.isStudent) ...[
          SizedBox(height: context.h(18)),
          Text(
            'Student details',
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w600,
              color: InsTokens.navy,
            ),
          ),
          SizedBox(height: context.h(12)),
          InsField(label: 'University', controller: _university),
          SizedBox(height: context.h(14)),
          InsField(label: 'Sponsor', controller: _sponsor),
          SizedBox(height: context.h(14)),
          InsField(label: 'Guardian', controller: _guardian),
        ],
        SizedBox(height: context.h(14)),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _save,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(4),
                vertical: context.h(2),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w500,
                  color: InsTokens.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: InsTokens.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: context.fs(11),
            color: InsTokens.subGrey,
          ),
        ),
        SizedBox(height: context.h(8)),
        Row(
          children: [
            for (final g in _genders) ...[
              GestureDetector(
                onTap: () => setState(() => _gender = g),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InsRadio(
                      selected: _gender == g,
                      onTap: () => setState(() => _gender = g),
                    ),
                    SizedBox(width: context.w(6)),
                    Text(
                      g,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: _gender == g
                            ? InsTokens.navy
                            : InsTokens.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (g != _genders.last) SizedBox(width: context.w(18)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _prefixIcon(BuildContext context, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: context.w(12), right: context.w(6)),
      child: Icon(icon, size: context.w(17), color: InsTokens.subGrey),
    );
  }
}
