import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';

/// What the box hands back: the traveller rows, plus the tenure when the
/// policy type is STUDENT (the box owns that stepper in the mock).
class InsTravellerResult {
  final List<InsTraveller> travellers;
  final int? tenureMonths;

  const InsTravellerResult(this.travellers, this.tenureMonths);
}

/// "Add Traveller with Date of Birth" — Figma `Add Insurance travellers`,
/// `… Student` and `… Friends, Family`.
///
/// Shown as a centred alert box whose dismiss cross hangs outside its
/// top-right corner. One box covers all three variants: the blue pill and
/// the stepper's ceiling come from [InsPolicyType.maxTravellers], and the
/// Tenure stepper only appears for a student policy.
class InsTravellerSheet extends StatefulWidget {
  final InsSearchQuery query;

  const InsTravellerSheet({super.key, required this.query});

  /// Opens the picker as a centred alert box; returns null when it is
  /// dismissed without DONE.
  static Future<InsTravellerResult?> showGeneral(
    BuildContext context, {
    required InsSearchQuery query,
  }) {
    return showGeneralDialog<InsTravellerResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Traveller with Date of Birth',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => InsTravellerSheet(query: query),
      transitionBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<InsTravellerSheet> createState() => _InsTravellerSheetState();
}

class _InsTravellerSheetState extends State<InsTravellerSheet> {
  late List<InsTraveller> _travellers =
      List<InsTraveller>.from(widget.query.travellers);
  late int _tenure = widget.query.tenureMonths ?? 3;

  InsPolicyType get _type => widget.query.policyType;
  int get _max => _type.maxTravellers;

  static const _generalRelations = [
    'SPOUSE',
    'CHILD',
    'PARENT',
    'SIBLING',
    'FRIEND',
  ];

  /// FRIENDS policies send MEMBER for everyone but the lead, so the picker
  /// offers nothing else there.
  List<String> get _relationOptions =>
      _type.isFriends ? const ['MEMBER'] : _generalRelations;

  void _setCount(int next) {
    if (next < 1 || next > _max) return;
    setState(() {
      if (next > _travellers.length) {
        _travellers = [
          ..._travellers,
          for (int i = _travellers.length; i < next; i++)
            InsTraveller(relation: _relationOptions.first),
        ];
      } else {
        _travellers = _travellers.sublist(0, next);
      }
    });
  }

  Future<void> _pickDob(int i) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _travellers[i].dob ?? DateTime(now.year - 25, now.month, now.day),
      // The provider prices from 6 months to 70 years, so the picker spans
      // just over that rather than offering dates it would reject.
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
    if (picked != null) {
      setState(() => _travellers[i] = _travellers[i].copyWith(dob: picked));
    }
  }

  void _done() {
    final missing = _travellers.indexWhere((t) => t.dob == null);
    if (missing >= 0) {
      insSnack(
        context,
        'Enter the date of birth for Traveller ${missing + 1}',
        isError: true,
      );
      return;
    }
    Navigator.of(context).pop(
      InsTravellerResult(_travellers, _type.isStudent ? _tenure : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            // Nothing in the box takes typed input today, but keeping the
            // keyboard inset here means the box shrinks rather than clips
            // its DONE button if a text field is ever added.
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(10),
              context.w(18),
              MediaQuery.of(context).viewInsets.bottom + context.h(10),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.w(400)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // The cross lives on the barrier, just above the box's
                  // top-right corner, rather than inside the box.
                  _closeButton(context),
                  SizedBox(height: context.h(10)),
                  Flexible(child: _box(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The dismiss cross that sits outside the alert box.
  Widget _closeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.r(32),
        height: context.r(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: context.r(8),
              offset: Offset(0, context.h(2)),
            ),
          ],
        ),
        child: Icon(Icons.close_rounded,
            size: context.r(19), color: InsTokens.navy),
      ),
    );
  }

  Widget _box(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.w(18),
                context.h(20),
                context.w(18),
                context.h(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(context),
                  SizedBox(height: context.h(26)),
                  _countRow(context),
                  SizedBox(height: context.h(18)),
                  for (int i = 0; i < _travellers.length; i++)
                    _travellerRow(context, i),
                  if (_type.isStudent) ...[
                    SizedBox(height: context.h(8)),
                    _tenureRow(context),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(4),
              context.w(18),
              context.h(16),
            ),
            child: InsPrimaryButton(label: 'DONE', onPressed: _done),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Add Traveller with Date of Birth',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
              color: InsTokens.navy,
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(2),
          ),
          // color: AppColors.AppBlue.withAlpha(2),
          decoration: BoxDecoration(
            border: Border.all(color: InsTokens.blue, width: 0.2),
            borderRadius: BorderRadius.circular(context.r(0)),
            color: AppColors.AppBlue.withAlpha(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_rounded,
                  size: context.w(12), color: InsTokens.blue),
              SizedBox(width: context.w(6)),
              Text(
                _type.travellerLimitLabel,
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: InsTokens.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _countRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Travellers',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: InsTokens.navy,
            ),
          ),
        ),
        InsStepper(
          value: _travellers.length,
          max: _max,
          onChanged: _setCount,
        ),
      ],
    );
  }

  Widget _travellerRow(BuildContext context, int i) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(14)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'DOB of Traveller ${i + 1}',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w400,
                    color: InsTokens.navy,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: GestureDetector(
                  onTap: () => _pickDob(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(14),
                      vertical: context.h(13),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.r(10)),
                      border: Border.all(color: InsTokens.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _travellers[i].dob == null
                                ? 'dd/mm/yyyy'
                                : DateFormat('dd/MM/yyyy')
                                    .format(_travellers[i].dob!),
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w500,
                              color: _travellers[i].dob == null
                                  ? InsTokens.labelGrey
                                  : InsTokens.navy,
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/NewIcons/calender.png',
                          width: context.w(14),
                          height: context.w(14),
                          color: InsTokens.subGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Relation is only meaningful for co-travellers, and only when the
          // policy type offers a choice — a FRIENDS policy is MEMBER-only,
          // so showing a one-item dropdown would just be noise.
          if (i > 0 && _relationOptions.length > 1) ...[
            SizedBox(height: context.h(10)),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Relation',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: InsTokens.navy,
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.r(10)),
                      border: Border.all(color: InsTokens.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _relationOptions
                                .contains(_travellers[i].relation)
                            ? _travellers[i].relation
                            : _relationOptions.first,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: InsTokens.navy,
                        ),
                        items: [
                          for (final r in _relationOptions)
                            DropdownMenuItem(value: r, child: Text(r)),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _travellers[i] =
                              _travellers[i].copyWith(relation: v));
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tenureRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tenure (Months)',
            style: TextStyle(
              fontSize: context.fs(19),
              fontWeight: FontWeight.w700,
              color: InsTokens.navy,
            ),
          ),
        ),
        InsStepper(
          value: _tenure,
          min: 1,
          max: 24,
          onChanged: (v) => setState(() => _tenure = v),
        ),
      ],
    );
  }
}
