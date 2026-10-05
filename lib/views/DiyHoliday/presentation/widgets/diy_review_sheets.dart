import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_traveller.dart';
import 'diy_common.dart';

/// The bottom sheets of the Figma review flow — `SAVE LIST ADD DETAILS`,
/// `Dob add details holiday`, `Gender add details holiday`, `Select - -`,
/// `Fare Holiday`. They share one frame: a round close button floating above
/// a white sheet with a grab handle.

/// Opens [child] in the Figma sheet frame.
Future<T?> showDiyCloseSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext sheetContext) builder,
  double maxHeightFactor = 0.75,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final radius = Radius.circular(context.r(22));
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(sheetContext).size.height * maxHeightFactor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: context.w(16),
                  bottom: context.h(10),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  child: Container(
                    width: context.w(32),
                    height: context.w(32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: context.w(18),
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: radius,
                      topRight: radius,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: context.h(10)),
                      Center(
                        child: Container(
                          width: context.w(64),
                          height: context.h(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD5D8DE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Flexible(child: builder(sheetContext)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _sheetTitle(BuildContext context, String title) => Padding(
  padding: EdgeInsets.fromLTRB(
    context.w(18),
    context.h(22),
    context.w(18),
    context.h(12),
  ),
  child: Text(
    title,
    style: TextStyle(
      fontSize: context.fs(15),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  ),
);

/// `Select - -` — a plain list, one tap picks. Used for gender, transport
/// mode and GST state.
Future<String?> showDiySelectSheet(
  BuildContext context, {
  String title = 'Select - -',
  required List<String> options,
  String? selected,
}) {
  return showDiyCloseSheet<String>(
    context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle(context, title),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: context.h(16)),
            children: [
              for (final o in options)
                InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(o),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(18),
                      vertical: context.h(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.toUpperCase(),
                            style: TextStyle(
                              fontSize: context.fs(12.5),
                              fontWeight: o == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: o == selected
                                  ? DiyTokens.blue
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (o == selected)
                          Icon(
                            Icons.check_rounded,
                            size: context.w(17),
                            color: DiyTokens.blue,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// `Saved Traveller List` — the customer's address book. A tap (or the edit
/// pencil) fills the form with that person.
Future<DiyTraveller?> showDiySavedTravellers(
  BuildContext context,
  List<DiyTraveller> saved,
) {
  return showDiyCloseSheet<DiyTraveller>(
    context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle(context, 'Saved Traveller List'),
        if (saved.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              0,
              context.w(18),
              context.h(28),
            ),
            child: Text(
              'No saved travellers yet. Travellers you add are remembered '
              'for your next booking.',
              style: TextStyle(
                fontSize: context.fs(12),
                color: DiyTokens.subGrey,
              ),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                context.w(10),
                0,
                context.w(10),
                context.h(20),
              ),
              itemCount: saved.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: DiyTokens.line),
              itemBuilder: (_, i) => InkWell(
                onTap: () => Navigator.of(sheetContext).pop(saved[i]),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          saved[i].fullName,
                          style: TextStyle(
                            fontSize: context.fs(12.5),
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.edit_square,
                        size: context.w(16),
                        color: DiyTokens.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// `Select Date` — three wheels, day / month / year, and SAVE.
Future<DateTime?> showDiyDobPicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  final lastDate = DateUtils.dateOnly(last ?? now);
  final firstDate = DateUtils.dateOnly(first ?? DateTime(now.year - 100));
  var start = initial ?? DateTime(now.year - 25, 1, 1);
  if (start.isAfter(lastDate)) start = lastDate;
  if (start.isBefore(firstDate)) start = firstDate;

  return showDiyCloseSheet<DateTime>(
    context,
    builder: (sheetContext) =>
        _DobWheels(initial: start, first: firstDate, last: lastDate),
  );
}

class _DobWheels extends StatefulWidget {
  final DateTime initial;
  final DateTime first;
  final DateTime last;

  const _DobWheels({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_DobWheels> createState() => _DobWheelsState();
}

class _DobWheelsState extends State<_DobWheels> {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;

  late final List<int> _years = [
    for (var y = widget.first.year; y <= widget.last.year; y++) y,
  ];

  late final _dayCtl = FixedExtentScrollController(initialItem: _day - 1);
  late final _monthCtl = FixedExtentScrollController(initialItem: _month - 1);
  late final _yearCtl = FixedExtentScrollController(
    initialItem: _years.indexOf(_year),
  );

  @override
  void dispose() {
    _dayCtl.dispose();
    _monthCtl.dispose();
    _yearCtl.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  DateTime get _value {
    final d = DateTime(_year, _month, _day.clamp(1, _daysInMonth));
    if (d.isAfter(widget.last)) return widget.last;
    if (d.isBefore(widget.first)) return widget.first;
    return d;
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    final extent = context.h(36);
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The two rules either side of the chosen row, as in the design.
          Positioned(
            left: context.w(14),
            right: context.w(14),
            child: SizedBox(
              height: extent,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: DiyTokens.line),
                  ),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: extent,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 50,
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (_, i) => Center(
                child: Text(
                  label(i),
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: i == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == selected
                        ? DiyTokens.blue
                        : const Color(0xFF8C93A1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle(context, 'Select Date'),
        SizedBox(
          height: context.h(36) * 3,
          child: Row(
            children: [
              _wheel(
                controller: _dayCtl,
                count: _daysInMonth,
                label: (i) => '${i + 1}',
                selected: _day - 1,
                onChanged: (i) => setState(() => _day = i + 1),
              ),
              _wheel(
                controller: _monthCtl,
                count: 12,
                label: (i) => _months[i],
                selected: _month - 1,
                onChanged: (i) => setState(() => _month = i + 1),
              ),
              _wheel(
                controller: _yearCtl,
                count: _years.length,
                label: (i) => '${_years[i]}',
                selected: _years.indexOf(_year),
                onChanged: (i) => setState(() => _year = _years[i]),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(12),
            context.h(22),
            context.w(12),
            context.h(22),
          ),
          child: SizedBox(
            height: context.h(44),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_value),
              style: ElevatedButton.styleFrom(
                backgroundColor: DiyTokens.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'SAVE',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `Fare Breakup` — before tax, taxes, and the total in its own tinted footer.
Future<void> showDiyFareBreakup(
  BuildContext context, {
  required double subTotal,
  required double tax,
  required double taxPercent,
  required double total,
  required int travellers,
  required bool adultsOnly,
  String currency = 'INR',
}) {
  String money(double v) => diyMoney(v, currency: currency);
  final heads = travellers > 0 ? travellers : 1;
  final who = adultsOnly ? 'Adult(s)' : 'Traveller(s)';

  Widget row(
    String title,
    double amount,
    String caption,
    double captionAmount,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(18),
        vertical: context.h(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                money(amount),
                style: TextStyle(
                  fontSize: context.fs(13.5),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          Row(
            children: [
              Expanded(
                child: Text(
                  caption,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ),
              Text(
                money(captionAmount),
                style: TextStyle(
                  fontSize: context.fs(11),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final rate = taxPercent.toStringAsFixed(taxPercent % 1 == 0 ? 0 : 1);
  return showDiyCloseSheet<void>(
    context,
    builder: (_) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(18),
              context.w(18),
              context.h(4),
            ),
            child: Text(
              'Fare Breakup',
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          if (subTotal > 0) ...[
            row(
              'Base Fare',
              subTotal,
              '$who ($heads X ${money(subTotal / heads)})',
              subTotal,
            ),
            Divider(
              height: 1,
              indent: context.w(18),
              endIndent: context.w(18),
              color: DiyTokens.line,
            ),
            row(
              'Taxes & Surcharges',
              tax,
              taxPercent > 0 ? 'GST @ $rate%' : 'Taxes',
              tax,
            ),
          ],
          Container(
            margin: EdgeInsets.only(top: context.h(8)),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(18),
              vertical: context.h(20),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: context.fs(14.5),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  money(total),
                  style: TextStyle(
                    fontSize: context.fs(19),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
