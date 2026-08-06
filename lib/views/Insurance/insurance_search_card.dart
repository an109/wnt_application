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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'insurance_quotesScreen.dart';
import '../../UI_helper/responsive_layout.dart';
import '../../injection_container.dart' as di;
import '../AKInsurance/domain/entity/AKInsurance_entity.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_bloc.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_event.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_state.dart';
import '../countries/domain/entities/country_entity.dart';
import '../countries/presentation/bloc/country_bloc.dart';
import '../countries/presentation/bloc/country_event.dart';
import '../countries/presentation/bloc/country_state.dart';

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

  // Fallback options shown while the live ProviderChecklist/cached-countries
  // calls are in flight or if they fail — keeps the form usable either way.
  static const List<String> _fallbackInsuranceTypes = [
    'Individual', 'Family', 'Corporate', 'Student',
  ];
  static const List<String> _fallbackCountries = [
    'India', 'Thailand', 'Singapore', 'Dubai', 'Malaysia', 'Japan',
    'Vietnam', 'USA', 'UK', 'Australia', 'Germany', 'France', 'Indonesia',
  ];

  late final AkInsuranceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<AkInsuranceBloc>();
    _bloc.add(const LoadAkInsuranceProviderChecklistEvent());

    final countryState = context.read<CountryBloc>().state;
    if (countryState is! CountryLoaded) {
      context.read<CountryBloc>().add(const LoadCountriesEvent());
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  int? get _noOfDays {
    final s = _startDate, e = _endDate;
    if (s == null || e == null) return null;
    final days = e.difference(s).inDays + 1; // inclusive trip duration
    return days > 0 ? days : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountryBloc, CountryState>(
      builder: (context, countryState) {
        final countries = countryState is CountryLoaded
            ? countryState.countries
            : const <CountryEntity>[];
        final countryNames = countries.isNotEmpty
            ? countries.map((c) => c.name).toList()
            : _fallbackCountries;

        return BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
          bloc: _bloc,
          builder: (context, akState) {
            final policyTypes = akState.checklist?.policyTypes.isNotEmpty == true
                ? akState.checklist!.policyTypes
                : _fallbackInsuranceTypes;
            return _buildCard(context, countryNames, policyTypes);
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    List<String> countryNames,
    List<String> policyTypes,
  ) {
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
              child: _dropdownField(
                context,
                label: 'INSURANCE TYPE',
                value: _insuranceType,
                options: policyTypes,
                onChanged: (v) => setState(() => _insuranceType = v),
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: _dropdownField(
                context,
                label: 'FROM COUNTRY',
                value: _fromCountry,
                options: countryNames,
                onChanged: (v) => setState(() => _fromCountry = v),
              ),
            ),
          ]),
          SizedBox(height: context.h(8)),
          // Row 2 — Travelling Country | No of Persons
          Row(children: [
            Expanded(
              child: _CountryDropdownField(
                label: 'TRAVELLING COUNTRY',
                options: countryNames,
                selected: _travelCountries,
                onChanged: (v) => setState(() => _travelCountries = v),
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

  // Inline native dropdown — tapping the field opens Flutter's own dropdown
  // menu right there, populated from live API data (ProviderChecklist /
  // cached-countries), instead of a separate picker dialog.
  Widget _dropdownField(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(4)),
            child: Text(label,
                style: TextStyle(
                    fontSize: context.overline,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: context.letterSpacingWider)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: options.contains(value) ? value : null,
              isDense: true,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded,
                  size: context.iconMedium, color: Colors.grey.shade600),
              style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              items: options
                  .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
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

  void _onGetQuotes() {
    if (_travelCountries.isEmpty) {
      _snack('Select a travelling country first');
      return;
    }
    if (_endDate == null) {
      _snack('Select an end date first');
      return;
    }
    if (_travellerDobs.any((d) => d == null)) {
      _snack('Enter date of birth for all travellers');
      return;
    }

    final countryState = context.read<CountryBloc>().state;
    final countries = countryState is CountryLoaded
        ? countryState.countries
        : const <CountryEntity>[];
    final countryCodes = _travelCountries.map((name) {
      final matches = countries.where((c) => c.name == name);
      return matches.isNotEmpty ? matches.first.code : '';
    }).toList();
    final isoFmt = DateFormat('yyyy-MM-dd');

    _bloc.add(LoadAkInsuranceQuotesEvent(
      AkInsuranceQuotesRequestEntity(
        policyType: _insuranceType.toUpperCase(),
        countryCodes: countryCodes,
        countryNames: List<String>.from(_travelCountries),
        startDate: isoFmt.format(_startDate!),
        endDate: isoFmt.format(_endDate!),
        travellers: [
          for (int i = 0; i < _travellerDobs.length; i++)
            AkInsuranceTravellerEntity(
              id: i,
              birthdate: isoFmt.format(_travellerDobs[i]!),
              relation: i == 0 ? 'SELF' : 'OTHER',
            ),
        ],
      ),
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: _bloc,
          child: InsuranceQuotesScreen(
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
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
      content: Text(msg),
    ));
  }
}

// ── Travelling countries — anchored multi-select dropdown (search + checks),
// opens right under the field instead of a centered dialog. ────────────────
class _CountryDropdownField extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _CountryDropdownField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_CountryDropdownField> createState() => _CountryDropdownFieldState();
}

class _CountryDropdownFieldState extends State<_CountryDropdownField> {
  static const Color _brandBlue = Color(0xFF003B95);

  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _search = TextEditingController();

  late Set<String> _draft;

  @override
  void initState() {
    super.initState();
    _draft = Set<String>.from(widget.selected);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open() {
    _draft = Set<String>.from(widget.selected);
    _search.clear();
    _overlayController.show();
  }

  void _apply() {
    widget.onChanged(_draft.toList());
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.selected.isEmpty
        ? 'Select Countries'
        : (widget.selected.length == 1
            ? widget.selected[0]
            : '${widget.selected[0]}  +${widget.selected.length - 1} more');

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (overlayCtx) {
          final fieldWidth =
              (_fieldKey.currentContext?.findRenderObject() as RenderBox?)
                      ?.size
                      .width ??
                  context.w(150);

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _overlayController.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: Offset(0, context.h(4)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    child: StatefulBuilder(
                      builder: (ctx, setOverlayState) {
                        final query = _search.text.trim().toLowerCase();
                        final filtered = query.isEmpty
                            ? widget.options
                            : widget.options
                                .where((c) => c.toLowerCase().contains(query))
                                .toList();
                        return Container(
                          width: fieldWidth,
                          constraints: BoxConstraints(maxHeight: context.h(320)),
                          padding: EdgeInsets.all(context.w(10)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.r(12)),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _search,
                                onChanged: (_) => setOverlayState(() {}),
                                style: TextStyle(fontSize: context.labelLarge),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search country',
                                  hintStyle: TextStyle(fontSize: context.labelLarge),
                                  prefixIcon:
                                      Icon(Icons.search, size: context.iconSmall),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: context.w(10), vertical: context.h(8)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(context.r(10)),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(6)),
                              Flexible(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: filtered
                                      .map((c) => CheckboxListTile(
                                            dense: true,
                                            visualDensity: VisualDensity.compact,
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity: ListTileControlAffinity.leading,
                                            activeColor: _brandBlue,
                                            value: _draft.contains(c),
                                            title: Text(c,
                                                style:
                                                    TextStyle(fontSize: context.labelLarge)),
                                            onChanged: (v) => setOverlayState(() {
                                              v == true ? _draft.add(c) : _draft.remove(c);
                                            }),
                                          ))
                                      .toList(),
                                ),
                              ),
                              SizedBox(height: context.h(6)),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandBlue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(context.r(10))),
                                  ),
                                  onPressed: _apply,
                                  child: const Text('DONE',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: GestureDetector(
          key: _fieldKey,
          onTap: _open,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label,
                    style: TextStyle(
                        fontSize: context.overline,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: context.letterSpacingWider)),
                SizedBox(height: context.h(4)),
                Row(children: [
                  Icon(Icons.public, size: context.iconSmall, color: _brandBlue),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w800,
                        color: widget.selected.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: context.iconMedium, color: Colors.grey.shade600),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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