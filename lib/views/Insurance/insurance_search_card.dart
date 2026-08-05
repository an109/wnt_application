// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../../../UI_helper/responsive_layout.dart';
//
// /// Travel Insurance search card shown inside the home hero.
// /// Design language borrowed from MakeMyTrip's insurance widget:
// /// trip-type toggle, destination, dates, travellers, plan type
// /// and a bold gradient "EXPLORE PLANS" CTA.
// class InsuranceSearchCard extends StatefulWidget {
//   const InsuranceSearchCard({super.key});
//
//   @override
//   State<InsuranceSearchCard> createState() => _InsuranceSearchCardState();
// }
//
// class _InsuranceSearchCardState extends State<InsuranceSearchCard> {
//   static const Color _brandBlue = Color(0xFF003B95);
//   static const Color _brandTeal = Color(0xFF005B7F);
//
//   bool _isSingleTrip = true;
//   bool _isStudentPlan = false;
//   String _destination = 'Thailand';
//   late DateTime _startDate = DateTime.now().add(const Duration(days: 1));
//   late DateTime _endDate = _startDate.add(const Duration(days: 4));
//   int _travellers = 1;
//
//   static const List<String> _countries = [
//     'Thailand', 'Singapore', 'Dubai', 'Malaysia', 'Japan', 'Vietnam',
//     'USA', 'UK', 'Australia', 'Germany', 'France', 'Indonesia',
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(context.w(14)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.r(16)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.12),
//             blurRadius: context.w(14),
//             offset: Offset(0, context.h(6)),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildHeader(context),
//           SizedBox(height: context.h(10)),
//           _buildTripTypeRow(context),
//           SizedBox(height: context.h(8)),
//           _buildFieldsGrid(context),
//           SizedBox(height: context.h(8)),
//           _buildPlanTypeRow(context),
//           SizedBox(height: context.h(12)),
//           _buildExploreButton(context),
//         ],
//       ),
//     );
//   }
//
//   // ── Header: icon + title + promo badge (MMT "40% premium" strip) ────────
//   Widget _buildHeader(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(context.w(6)),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(colors: [_brandBlue, _brandTeal]),
//             borderRadius: BorderRadius.circular(context.r(10)),
//           ),
//           child: Icon(Icons.health_and_safety_rounded,
//               color: Colors.white, size: context.iconMedium),
//         ),
//         SizedBox(width: context.w(8)),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Travel Insurance',
//                   style: TextStyle(
//                       fontSize: context.titleSmall,
//                       fontWeight: FontWeight.w800,
//                       color: Colors.black87)),
//               Text('International Travel + Medical Cover',
//                   style: TextStyle(
//                       fontSize: context.labelSmall,
//                       color: Colors.grey.shade600)),
//             ],
//           ),
//         ),
//         Container(
//           padding: EdgeInsets.symmetric(
//               horizontal: context.w(8), vertical: context.h(3)),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//                 colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)]),
//             borderRadius: BorderRadius.circular(context.r(8)),
//           ),
//           child: Text('40% OFF',
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: context.overline,
//                   fontWeight: FontWeight.w700)),
//         ),
//       ],
//     );
//   }
//
//   // ── Single Trip / Annual Multi Trip (like MMT radios) ───────────────────
//   Widget _buildTripTypeRow(BuildContext context) {
//     return Row(
//       children: [
//         _toggleChip(context,
//             label: 'Single Trip',
//             selected: _isSingleTrip,
//             onTap: () => setState(() => _isSingleTrip = true)),
//         SizedBox(width: context.w(8)),
//         _toggleChip(context,
//             label: 'Annual Multi Trip',
//             selected: !_isSingleTrip,
//             badge: 'new',
//             onTap: () => setState(() => _isSingleTrip = false)),
//       ],
//     );
//   }
//
//   Widget _toggleChip(BuildContext context,
//       {required String label,
//         required bool selected,
//         required VoidCallback onTap,
//         String? badge}) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: EdgeInsets.symmetric(
//               vertical: context.h(8), horizontal: context.w(8)),
//           decoration: BoxDecoration(
//             color: selected ? _brandBlue.withOpacity(0.08) : Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(context.r(10)),
//             border: Border.all(
//                 color: selected ? _brandBlue : Colors.grey.shade300,
//                 width: 1.2),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                   selected
//                       ? Icons.check_circle
//                       : Icons.radio_button_unchecked,
//                   size: context.iconSmall + 2,
//                   color: selected ? _brandBlue : Colors.grey.shade400),
//               SizedBox(width: context.w(5)),
//               Flexible(
//                 child: Text(label,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                         fontSize: context.labelMedium,
//                         fontWeight: FontWeight.w700,
//                         color: selected ? _brandBlue : Colors.grey.shade700)),
//               ),
//               if (badge != null)
//                 Container(
//                   margin: EdgeInsets.only(left: context.w(4)),
//                   padding: EdgeInsets.symmetric(
//                       horizontal: context.w(5), vertical: context.h(2)),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                         colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)]),
//                     borderRadius: BorderRadius.circular(context.r(6)),
//                   ),
//                   child: Text(badge,
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: context.overline,
//                           fontWeight: FontWeight.w700,
//                           height: 1.2)),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── 4-box grid: Destination | Travellers / Start | End (MMT layout) ─────
//   Widget _buildFieldsGrid(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _fieldShell(context,
//                   label: 'TRAVELLING TO',
//                   onTap: () => _pickDestination(context),
//                   child: Row(children: [
//                     Icon(Icons.public, size: context.iconSmall, color: _brandBlue),
//                     SizedBox(width: context.w(6)),
//                     Expanded(
//                       child: Text(_destination,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                               fontSize: context.bodyLarge,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.black87)),
//                     ),
//                     Icon(Icons.arrow_drop_down_rounded,
//                         size: context.iconMedium, color: Colors.grey.shade600),
//                   ])),
//             ),
//             SizedBox(width: context.w(8)),
//             Expanded(
//               child: _fieldShell(context,
//                   label: 'TRAVELLERS',
//                   child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         _stepButton(context, Icons.remove_rounded, () {
//                           if (_travellers > 1) setState(() => _travellers--);
//                         }),
//                         Text('$_travellers',
//                             style: TextStyle(
//                                 fontSize: context.bodyLarge,
//                                 fontWeight: FontWeight.w800)),
//                         _stepButton(context, Icons.add_rounded, () {
//                           if (_travellers < 9) setState(() => _travellers++);
//                         }),
//                       ])),
//             ),
//           ],
//         ),
//         SizedBox(height: context.h(8)),
//         Row(
//           children: [
//             Expanded(
//               child: _fieldShell(context,
//                   label: 'START DATE',
//                   onTap: () => _pickDate(context, true),
//                   child: _dateValue(context, _startDate)),
//             ),
//             SizedBox(width: context.w(8)),
//             Expanded(
//               child: _fieldShell(context,
//                   label: 'END DATE',
//                   onTap: () => _pickDate(context, false),
//                   child: _dateValue(context, _endDate)),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _dateValue(BuildContext context, DateTime date) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(DateFormat('dd MMM yy').format(date),
//             style: TextStyle(
//                 fontSize: context.bodyLarge,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.black87)),
//         Text(DateFormat('EEEE').format(date),
//             style: TextStyle(
//                 fontSize: context.labelSmall, color: Colors.grey.shade600)),
//       ],
//     );
//   }
//
//   Widget _fieldShell(BuildContext context,
//       {required String label, required Widget child, VoidCallback? onTap}) {
//     final box = Container(
//       padding: EdgeInsets.symmetric(
//           horizontal: context.w(10), vertical: context.h(8)),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF6F8FB),
//         borderRadius: BorderRadius.circular(context.r(12)),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(label,
//               style: TextStyle(
//                   fontSize: context.overline,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade500,
//                   letterSpacing: context.letterSpacingWider)),
//           SizedBox(height: context.h(4)),
//           child,
//         ],
//       ),
//     );
//     return onTap == null
//         ? box
//         : GestureDetector(onTap: onTap, child: box);
//   }
//
//   Widget _stepButton(BuildContext context, IconData icon, VoidCallback onTap) {
//     return Material(
//       color: Colors.white,
//       shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300)),
//       child: InkWell(
//         customBorder: const CircleBorder(),
//         onTap: onTap,
//         child: Padding(
//           padding: EdgeInsets.all(context.w(4)),
//           child: Icon(icon, size: context.iconXSmall + 2, color: _brandBlue),
//         ),
//       ),
//     );
//   }
//
//   // ── Regular / Student plan chips ────────────────────────────────────────
//   Widget _buildPlanTypeRow(BuildContext context) {
//     return Row(
//       children: [
//         Text('PLAN',
//             style: TextStyle(
//                 fontSize: context.overline,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.grey.shade500,
//                 letterSpacing: context.letterSpacingWider)),
//         SizedBox(width: context.w(8)),
//         _toggleChip(context,
//             label: 'Regular',
//             selected: !_isStudentPlan,
//             onTap: () => setState(() => _isStudentPlan = false)),
//         SizedBox(width: context.w(8)),
//         _toggleChip(context,
//             label: 'Student',
//             selected: _isStudentPlan,
//             onTap: () => setState(() => _isStudentPlan = true)),
//       ],
//     );
//   }
//
//   // ── CTA ─────────────────────────────────────────────────────────────────
//   Widget _buildExploreButton(BuildContext context) {
//     return GestureDetector(
//       onTap: _onExplore,
//       child: Container(
//         height: context.h(46),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(colors: [_brandBlue, _brandTeal]),
//           borderRadius: BorderRadius.circular(context.r(14)),
//           boxShadow: [
//             BoxShadow(
//                 color: _brandBlue.withOpacity(0.35),
//                 blurRadius: context.w(12),
//                 offset: Offset(0, context.h(4))),
//           ],
//         ),
//         child: Center(
//           child: Text('EXPLORE PLANS',
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: context.bodyLarge,
//                   fontWeight: FontWeight.w800,
//                   letterSpacing: context.letterSpacingWider)),
//         ),
//       ),
//     );
//   }
//
//   void _onExplore() {
//     // TODO: replace with real navigation, e.g.
//     // Navigator.push(context, MaterialPageRoute(
//     //     builder: (_) => InsurancePlansScreen(
//     //           destination: _destination,
//     //           startDate: _startDate,
//     //           endDate: _endDate,
//     //           travellers: _travellers,
//     //           studentPlan: _isStudentPlan,
//     //           singleTrip: _isSingleTrip,
//     //         )));
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
//       content: Text(
//         'Fetching $_destination plans · '
//             '${DateFormat('dd MMM').format(_startDate)} – ${DateFormat('dd MMM').format(_endDate)} '
//             '· $_travellers traveller(s)',
//       ),
//     ));
//   }
//
//   Future<void> _pickDate(BuildContext context, bool isStart) async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: isStart ? _startDate : _endDate,
//       firstDate: isStart ? now : _startDate,
//       lastDate: now.add(const Duration(days: 365)),
//       builder: (ctx, child) => Theme(
//         data: Theme.of(ctx).copyWith(
//           colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _brandBlue),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked == null) return;
//     setState(() {
//       if (isStart) {
//         _startDate = picked;
//         if (_endDate.isBefore(picked)) {
//           _endDate = picked.add(const Duration(days: 4));
//         }
//       } else {
//         _endDate = picked;
//       }
//     });
//   }
//
//   Future<void> _pickDestination(BuildContext context) async {
//     final picked = await showDialog<String>(
//       context: context,
//       builder: (dialogCtx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(context.r(16))),
//         title: Text('Where are you travelling?',
//             style: TextStyle(
//                 fontSize: context.titleSmall, fontWeight: FontWeight.w800)),
//         content: SingleChildScrollView(
//           child: Wrap(
//             spacing: context.w(8),
//             runSpacing: context.h(8),
//             children: _countries
//                 .map((c) => ChoiceChip(
//               label: Text(c,
//                   style: TextStyle(fontSize: context.labelLarge)),
//               selectedColor: _brandBlue.withOpacity(0.15),
//               selected: c == _destination,
//               onSelected: (_) => Navigator.of(dialogCtx).pop(c),
//             ))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//     if (picked != null) setState(() => _destination = picked);
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/views/Insurance/insurance_quotesScreen.dart';
import '../../UI_helper/responsive_layout.dart';

/// Travel Insurance quote card — same visual design as before, but the
/// fields mirror thewandernova.com/insurance:
/// Insurance Type | From Country | Travelling Country | Start Date |
/// End Date | No of Days (auto) | No of Persons (+ DOB per traveller).
class InsuranceSearchCard extends StatefulWidget {
  const InsuranceSearchCard({super.key});

  @override
  State<InsuranceSearchCard> createState() => _InsuranceSearchCardState();
}

class _InsuranceSearchCardState extends State<InsuranceSearchCard> {
  static const Color _brandBlue = Color(0xFF003B95);
  static const Color _brandTeal = Color(0xFF005B7F);

  // ── Quote data (same shape as the web form) ───────────────────────────
  String _insuranceType = 'Individual';
  String _fromCountry = 'India';
  List<String> _travelCountries = <String>[];
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate;
  List<DateTime?> _travellerDobs = <DateTime?>[null];

  static const List<String> _insuranceTypes = [
    'Individual', 'Family', 'Corporate', 'Student',
  ];
  static const List<String> _countries = [
    'India', 'Thailand', 'Singapore', 'Dubai', 'Malaysia', 'Japan',
    'Vietnam', 'USA', 'UK', 'Australia', 'Germany', 'France', 'Indonesia',
  ];

  int? get _noOfDays {
    final s = _startDate, e = _endDate;
    if (s == null || e == null) return null;
    final days = e.difference(s).inDays + 1; // inclusive trip duration
    return days > 0 ? days : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: context.w(14),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: context.h(10)),
          // Row 1 — Insurance Type | From Country
          Row(children: [
            Expanded(
              child: _fieldShell(
                context,
                label: 'INSURANCE TYPE',
                onTap: () async {
                  final v = await _pickSingle(
                      context, 'Insurance Type', _insuranceTypes, _insuranceType);
                  if (v != null) setState(() => _insuranceType = v);
                },
                child: _valueRow(context, _insuranceType),
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: _fieldShell(
                context,
                label: 'FROM COUNTRY',
                onTap: () async {
                  final v = await _pickSingle(
                      context, 'From Country', _countries, _fromCountry);
                  if (v != null) setState(() => _fromCountry = v);
                },
                child: _valueRow(context, _fromCountry),
              ),
            ),
          ]),
          SizedBox(height: context.h(8)),
          // Row 2 — Travelling Country | No of Persons
          Row(children: [
            Expanded(
              child: _fieldShell(
                context,
                label: 'TRAVELLING COUNTRY',
                onTap: () async {
                  final v = await _CountryMultiDialog.show(context, _travelCountries);
                  if (v != null) setState(() => _travelCountries = v);
                },
                child: Row(children: [
                  Icon(Icons.public, size: context.iconSmall, color: _brandBlue),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      _travelCountries.isEmpty
                          ? 'Select Countries'
                          : (_travelCountries.length == 1
                          ? _travelCountries[0]
                          : '${_travelCountries[0]}  +${_travelCountries.length - 1} more'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w800,
                        color: _travelCountries.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: context.iconMedium, color: Colors.grey.shade600),
                ]),
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: _fieldShell(
                context,
                label: 'NO OF PERSONS',
                onTap: () async {
                  final v = await _TravellersDialog.show(context, _travellerDobs);
                  if (v != null) setState(() => _travellerDobs = v);
                },
                child: Row(children: [
                  Icon(Icons.person_outline_rounded,
                      size: context.iconSmall, color: _brandBlue),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      '${_travellerDobs.length} Traveller${_travellerDobs.length > 1 ? 's' : ''}',
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: context.bodyLarge,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: context.iconMedium, color: Colors.grey.shade600),
                ]),
              ),
            ),
          ]),
          SizedBox(height: context.h(8)),
          // Row 3 — Start Date | End Date
          Row(children: [
            Expanded(
              child: _fieldShell(
                context,
                label: 'START DATE',
                onTap: () => _pickDate(context, true),
                child: _startDate == null
                    ? _placeholder(context, 'Select Date')
                    : _dateValue(context, _startDate!),
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: _fieldShell(
                context,
                label: 'END DATE',
                onTap: () => _pickDate(context, false),
                child: _endDate == null
                    ? _placeholder(context, 'Select Date')
                    : _dateValue(context, _endDate!),
              ),
            ),
          ]),
          SizedBox(height: context.h(8)),
          // Row 4 — No of Days (auto-calculated, like the web form)
          _buildDaysStrip(context),
          SizedBox(height: context.h(12)),
          _buildCta(context),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.w(6)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_brandBlue, _brandTeal]),
            borderRadius: BorderRadius.circular(context.r(10)),
          ),
          child: Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: context.iconMedium),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Travel Insurance',
                  style: TextStyle(
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              Text('Get Instant Travel Insurance Quotes',
                  style: TextStyle(
                      fontSize: context.labelSmall, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: context.w(8), vertical: context.h(3)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)]),
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: Text('NEW',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: context.overline,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ── Field building blocks ──────────────────────────────────────────────
  Widget _fieldShell(BuildContext context,
      {required String label, required Widget child, VoidCallback? onTap}) {
    final box = Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(10), vertical: context.h(8)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: context.overline,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: context.letterSpacingWider)),
          SizedBox(height: context.h(4)),
          child,
        ],
      ),
    );
    return onTap == null ? box : GestureDetector(onTap: onTap, child: box);
  }

  Widget _valueRow(BuildContext context, String value) {
    return Row(children: [
      Expanded(
        child: Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
      ),
      Icon(Icons.arrow_drop_down_rounded,
          size: context.iconMedium, color: Colors.grey.shade600),
    ]);
  }

  Widget _placeholder(BuildContext context, String text) => Text(text,
      style: TextStyle(
          fontSize: context.bodyLarge,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400));

  Widget _dateValue(BuildContext context, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(DateFormat('d MMM yy').format(date),
            style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        Text(DateFormat('EEEE').format(date),
            style: TextStyle(
                fontSize: context.labelSmall, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildDaysStrip(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(10), vertical: context.h(8)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(Icons.date_range_rounded, size: context.iconSmall, color: _brandBlue),
        SizedBox(width: context.w(6)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NO OF DAYS',
                style: TextStyle(
                    fontSize: context.overline,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: context.letterSpacingWider)),
            Text('Auto-calculated',
                style: TextStyle(
                    fontSize: context.labelSmall, color: Colors.grey.shade600)),
          ],
        ),
        const Spacer(),
        Text(_noOfDays == null ? '—' : '${_noOfDays} Days',
            style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w800,
                color: _noOfDays == null ? Colors.grey.shade400 : _brandBlue)),
      ]),
    );
  }

  Widget _buildCta(BuildContext context) {
    return GestureDetector(
      onTap: _onGetQuotes,
      child: Container(
        height: context.h(46),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_brandBlue, _brandTeal]),
          borderRadius: BorderRadius.circular(context.r(14)),
          boxShadow: [
            BoxShadow(
                color: _brandBlue.withOpacity(0.35),
                blurRadius: context.w(12),
                offset: Offset(0, context.h(4))),
          ],
        ),
        child: Center(
          child: Text('GET QUOTES',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w800,
                  letterSpacing: context.letterSpacingWider)),
        ),
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _brandBlue),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<String?> _pickSingle(BuildContext context, String title,
      List<String> options, String current) {
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(16))),
        title: Text(title,
            style: TextStyle(
                fontSize: context.titleSmall, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: context.w(8),
            runSpacing: context.h(8),
            children: options
                .map((o) => ChoiceChip(
              label: Text(o, style: TextStyle(fontSize: context.labelLarge)),
              selectedColor: _brandBlue.withOpacity(0.15),
              selected: o == current,
              onSelected: (_) => Navigator.of(dialogCtx).pop(o),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _onGetQuotes() {
    if (_travelCountries.isEmpty) {
      _snack('Select a travelling country first');
      return;
    }
    if (_endDate == null) {
      _snack('Select an end date first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsuranceQuotesScreen(
          request: InsuranceQuoteRequest(
            insuranceType: _insuranceType,
            fromCountry: _fromCountry,
            travellingCountries: List<String>.from(_travelCountries),
            startDate: _startDate!,
            endDate: _endDate!,
            noOfDays: _noOfDays!,
            travellerDobs: List<DateTime?>.from(_travellerDobs),
          ),
        ),
      ),
    );

    // Payload ready for your quotes API / next screen — same keys as web form.
    final payload = {
      'insuranceType': _insuranceType,
      'fromCountry': _fromCountry,
      'travellingCountries': _travelCountries,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'noOfDays': _noOfDays,
      'travellers': _travellerDobs.map((d) => d?.toIso8601String()).toList(),
    };
    debugPrint('Insurance quote payload: $payload');
    // TODO: Navigator.push(context, MaterialPageRoute(
    //         builder: (_) => InsuranceQuotesScreen(payload: payload)));
    _snack('Fetching quotes for ${_travelCountries.join(', ')}…');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
      content: Text(msg),
    ));
  }
}

// ── Multi-select travelling countries (web: "Select Countries") ──────────
class _CountryMultiDialog extends StatefulWidget {
  final List<String> initial;
  const _CountryMultiDialog({required this.initial});

  static Future<List<String>?> show(BuildContext context, List<String> initial) =>
      showDialog<List<String>>(
        context: context,
        builder: (_) => _CountryMultiDialog(initial: initial),
      );

  @override
  State<_CountryMultiDialog> createState() => _CountryMultiDialogState();
}

class _CountryMultiDialogState extends State<_CountryMultiDialog> {
  late Set<String> _selected = Set<String>.from(widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(16))),
      title: Text('Travelling to…',
          style: TextStyle(fontSize: context.titleSmall, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: context.w(8),
          runSpacing: context.h(8),
          children: _InsuranceSearchCardCountries
              .map((c) => FilterChip(
            label: Text(c, style: TextStyle(fontSize: context.labelLarge)),
            selectedColor: const Color(0xFF003B95).withOpacity(0.15),
            checkmarkColor: const Color(0xFF003B95),
            selected: _selected.contains(c),
            onSelected: (v) =>
                setState(() => v ? _selected.add(c) : _selected.remove(c)),
          ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected.toList()),
          child: Text('DONE',
              style: TextStyle(
                  color: const Color(0xFF003B95), fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// Country pool shared with the dialog (kept top-level for access).
const List<String> _InsuranceSearchCardCountries = [
  'India', 'Thailand', 'Singapore', 'Dubai', 'Malaysia', 'Japan',
  'Vietnam', 'USA', 'UK', 'Australia', 'Germany', 'France', 'Indonesia',
];

// ── Travellers popup (stepper + DOB per traveller, like the web popup) ───
class _TravellersDialog extends StatefulWidget {
  final List<DateTime?> initialDobs;
  const _TravellersDialog({required this.initialDobs});

  static Future<List<DateTime?>?> show(
      BuildContext context, List<DateTime?> initialDobs) =>
      showDialog<List<DateTime?>>(
        context: context,
        builder: (_) => _TravellersDialog(initialDobs: initialDobs),
      );

  @override
  State<_TravellersDialog> createState() => _TravellersDialogState();
}

class _TravellersDialogState extends State<_TravellersDialog> {
  late List<DateTime?> _dobs = List<DateTime?>.from(widget.initialDobs);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(16))),
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text('Travellers',
                  style: TextStyle(
                      fontSize: context.titleSmall, fontWeight: FontWeight.w800)),
              const Spacer(),
              _step(Icons.remove_rounded, () {
                if (_dobs.length > 1) setState(() => _dobs.removeLast());
              }),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                child: Text('${_dobs.length}',
                    style: TextStyle(
                        fontSize: context.titleMedium, fontWeight: FontWeight.w800)),
              ),
              _step(Icons.add_rounded, () {
                if (_dobs.length < 9) setState(() => _dobs.add(null));
              }),
            ]),
            SizedBox(height: context.h(12)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: context.h(280)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (int i = 0; i < _dobs.length; i++) _dobRow(context, i),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B95),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(12))),
                ),
                onPressed: () => Navigator.of(context).pop(_dobs),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.w(4)),
          child: Icon(icon, size: context.iconXSmall + 2, color: const Color(0xFF003B95)),
        ),
      ),
    );
  }

  Widget _dobRow(BuildContext context, int i) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(children: [
        SizedBox(
          width: context.w(80),
          child: Text('Traveller ${i + 1}',
              style: TextStyle(
                  fontSize: context.labelLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dobs[i] ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1935, 1, 1),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dobs[i] = picked);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(10), vertical: context.h(9)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(10)),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _dobs[i] == null
                        ? 'dd-mm-yyyy'
                        : DateFormat('dd-MM-yyyy').format(_dobs[i]!),
                    style: TextStyle(
                        fontSize: context.labelLarge,
                        color: _dobs[i] == null
                            ? Colors.grey.shade500
                            : Colors.black87),
                  ),
                ),
                Icon(Icons.calendar_month_outlined,
                    size: context.iconSmall, color: Colors.grey.shade600),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}