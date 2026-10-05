import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// What the customer picked on the sheet.
///
/// [trip] is the live-priced trip when they took the flight option after its
/// price had come back — the caller opens it as is, with no second search.
class DiyFlightChoice {
  final bool withFlight;
  final DiyTrip? trip;

  const DiyFlightChoice({required this.withFlight, this.trip});
}

/// "Please select an option" — opened by a package saved with flights, so the
/// customer picks before it is priced.
///
/// The flight option starts pricing the moment the sheet opens: fares are
/// searched live from the customer's own city on their date (**POST
/// /packages/{share_id}/price/**), with progress in the row, and the final
/// per-adult cost replaces it when it lands. Without flight is the land price
/// off the search row, fixed.
///
/// Returns the choice, or null if dismissed.
Future<DiyFlightChoice?> showDiyFlightChoiceSheet(
  BuildContext context, {
  required DiyPackageSummary package,
  required DiySearchQuery query,
}) {
  return showModalBottomSheet<DiyFlightChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DiyFlightChoiceSheet(package: package, query: query),
  );
}

class _DiyFlightChoiceSheet extends StatefulWidget {
  final DiyPackageSummary package;
  final DiySearchQuery query;

  const _DiyFlightChoiceSheet({required this.package, required this.query});

  @override
  State<_DiyFlightChoiceSheet> createState() => _DiyFlightChoiceSheetState();
}

class _DiyFlightChoiceSheetState extends State<_DiyFlightChoiceSheet> {
  DiyTrip? _trip;
  String? _error;
  bool _pricing = false;

  DiyPackageSummary get _package => widget.package;

  @override
  void initState() {
    super.initState();
    _priceWithFlight();
  }

  Future<void> _priceWithFlight() async {
    final date = widget.query.departureDate;
    if (date == null) {
      setState(() => _error = 'Pick a starting date to see flight prices');
      return;
    }
    setState(() {
      _pricing = true;
      _error = null;
    });
    try {
      final trip = await sl<DiyHolidayApi>().priceForDates(
        shareId: _package.shareId,
        departureDate: date,
        adults: widget.query.adults,
        children: widget.query.children,
        rooms: widget.query.roomsPayload,
        origin: widget.query.origin.slug,
        withFlight: true,
      );
      if (!mounted) return;
      setState(() => _trip = trip);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _pricing = false);
    }
  }

  /// Priced and complete — a total the customer can be shown.
  bool get _priced => _trip != null && _trip!.grandTotal > 0;

  void _pickWithFlight() {
    if (_pricing) return;
    if (_error != null && _trip == null) {
      _priceWithFlight();
      return;
    }
    Navigator.of(context).pop(DiyFlightChoice(withFlight: true, trip: _trip));
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(context.r(22));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close — floats outside the sheet, top-right, as in the design.
          Padding(
            padding: EdgeInsets.only(
              right: context.w(18),
              bottom: context.h(10),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: context.w(34),
                height: context.w(34),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: context.w(19),
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(10),
              context.w(20),
              context.h(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: context.w(48),
                    height: context.h(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DDE4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: context.h(18)),
                Text(
                  _package.title,
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w800,
                    color: DiyTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(12)),
                Text(
                  'Please select an option',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: DiyTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(16)),
                _withFlightOption(),
                SizedBox(height: context.h(12)),
                _withoutFlightOption(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _withFlightOption() {
    final Widget price;
    if (_pricing) {
      price = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: context.w(20),
            height: context.w(20),
            child: const CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Searching flights…',
            style: TextStyle(
              fontSize: context.fs(10.5),
              color: DiyTokens.labelGrey,
            ),
          ),
        ],
      );
    } else if (_priced) {
      final trip = _trip!;
      final adults = trip.adults > 0 ? trip.adults : 1;
      price = _amounts(
        perPerson: trip.grandTotal / adults,
        total: trip.grandTotal,
        currency: trip.currency,
      );
    } else if (_trip != null) {
      // Built, but a supplier left part of it unpriced. The trip screen says
      // what is missing; here it is only "on request", never a short total.
      price = _note('On request', 'Tap to see details');
    } else {
      price = _note('Retry', 'Couldn\'t get fares');
    }

    return _optionCard(
      withFlight: true,
      subtitle: 'Flying from ${widget.query.origin.name}',
      price: price,
      onTap: _pricing ? null : _pickWithFlight,
      footer: _pricing
          ? 'Checking live fares for ${_dateLabel()}. This takes a few seconds.'
          : (_error != null && _trip == null)
              ? _error
              : null,
    );
  }

  Widget _withoutFlightOption() {
    final total = _package.priceWithoutFlight;
    // A hand-priced package has no land figure; it cannot be sold without
    // its flights.
    final available = total > 0;
    final adults = _package.adults > 0 ? _package.adults : 1;

    return _optionCard(
      withFlight: false,
      subtitle: 'Hotels, transfers & sightseeing',
      price: available
          ? _amounts(
              perPerson: total / adults,
              total: total,
              currency: _package.currency,
            )
          : _note('Not available', ''),
      onTap: available
          ? () => Navigator.of(context)
              .pop(const DiyFlightChoice(withFlight: false))
          : null,
    );
  }

  String _dateLabel() {
    final d = widget.query.departureDate;
    return d == null ? 'your date' : diyDayDate(d.toIso8601String());
  }

  Widget _amounts({
    required double perPerson,
    required double total,
    required String currency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: diyMoney(perPerson, currency: currency),
            style: TextStyle(
              fontSize: context.fs(19),
              fontWeight: FontWeight.w800,
              color: DiyTokens.blue,
            ),
            children: [
              TextSpan(
                text: '/person',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w500,
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          'Total ${diyMoney(total, currency: currency)}',
          style: TextStyle(
            fontSize: context.fs(10.5),
            color: DiyTokens.labelGrey,
          ),
        ),
      ],
    );
  }

  Widget _note(String title, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.fs(15),
            fontWeight: FontWeight.w800,
            color: DiyTokens.blue,
          ),
        ),
        if (caption.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            caption,
            style: TextStyle(
              fontSize: context.fs(10.5),
              color: DiyTokens.labelGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionCard({
    required bool withFlight,
    required String subtitle,
    required Widget price,
    required VoidCallback? onTap,
    String? footer,
  }) {
    return Material(
      color: const Color(0xFFFAFBFC),
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: DiyTokens.subGrey,
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        Row(
                          children: [
                            _planeIcon(withFlight: withFlight),
                            SizedBox(width: context.w(10)),
                            Flexible(
                              child: Text(
                                withFlight ? 'With Flight' : 'Without Flight',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.fs(17),
                                  fontWeight: FontWeight.w800,
                                  color: DiyTokens.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  price,
                ],
              ),
              if (footer != null && footer.isNotEmpty) ...[
                SizedBox(height: context.h(10)),
                Text(
                  footer,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// A plane, struck through with a red slash for the land-only option.
  Widget _planeIcon({required bool withFlight}) {
    final plane = Icon(
      Icons.flight_takeoff_rounded,
      size: context.w(22),
      color: DiyTokens.blue,
    );
    if (withFlight) return plane;

    return SizedBox(
      width: context.w(24),
      height: context.w(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          plane,
          Transform.rotate(
            angle: -0.7,
            child: Container(
              width: context.w(26),
              height: 1.6,
              color: const Color(0xFFE23744),
            ),
          ),
        ],
      ),
    );
  }
}
