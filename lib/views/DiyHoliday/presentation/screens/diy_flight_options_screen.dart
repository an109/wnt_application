import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/newUIWidgets/flightCard.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';

/// Flight options for one leg — **API 7: GET /trips/{trip_id}/flights/
/// {outbound|return}/** — and the swap itself, **API 8: POST** on the same
/// path with `{"offer_ref": …}`.
///
/// The POST answers with the complete trip at its new price, which is what
/// this screen pops back; no separate price call is needed.
class DiyFlightOptionsScreen extends StatefulWidget {
  /// The trip being edited. The POST answers with a partial trip, so this is
  /// passed back in as the base to merge onto.
  final DiyTrip trip;
  final bool outbound;

  const DiyFlightOptionsScreen({
    super.key,
    required this.trip,
    required this.outbound,
  });

  String get tripId => trip.tripId;
  String get currency => trip.currency;

  @override
  State<DiyFlightOptionsScreen> createState() => _DiyFlightOptionsScreenState();
}

class _DiyFlightOptionsScreenState extends State<DiyFlightOptionsScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  List<DiyFlightOption> _options = const [];
  bool _loading = true;
  String? _error;
  String? _applyingRef;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await _api.getFlightOptions(
        tripId: widget.tripId,
        outbound: widget.outbound,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _select(DiyFlightOption option) async {
    if (option.isSelected) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _applyingRef = option.offerRef);
    try {
      final trip = await _api.changeFlight(
        tripId: widget.tripId,
        outbound: widget.outbound,
        offerRef: option.offerRef,
        previous: widget.trip,
      );
      if (!mounted) return;
      Navigator.of(context).pop(trip);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _applyingRef = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: diyAppBar(
        context,
        title: widget.outbound ? 'Departure flight' : 'Return flight',
      ),
      body: _loading
          ? const DiyLoading(message: 'Loading flight options…')
          : _error != null
              ? DiyErrorView(message: _error!, onRetry: _load)
              : _options.isEmpty
                  ? const DiyErrorView(
                      message: 'No alternative flights for this leg.',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        context.w(14),
                        context.h(12),
                        context.w(14),
                        context.h(24),
                      ),
                      itemCount: _options.length,
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.only(bottom: context.h(10)),
                        child: _tile(_options[i]),
                      ),
                    ),
    );
  }

  /// The API sends the leg as a title like "DEL to COK" and gives no city
  /// names, so the airport codes are read back off it. Anything that does not
  /// match that shape falls back to an empty code rather than showing junk.
  static (String, String) _routeCodes(String title) {
    final parts = title.split(RegExp(r'\s+to\s+', caseSensitive: false));
    if (parts.length != 2) return ('', '');
    return (parts[0].trim().toUpperCase(), parts[1].trim().toUpperCase());
  }

  Widget _tile(DiyFlightOption option) {
    final applying = _applyingRef == option.offerRef;
    final (fromCode, toCode) = _routeCodes(option.title);

    return Opacity(
      // Dim the row being applied so it is clear which one is in flight.
      opacity: applying ? 0.6 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _applyingRef != null ? null : () => _select(option),
        child: FlightCard(
          isSelected: option.isSelected,
          airlineName: option.carrierName,
          flightNumber: option.flightNumber,
          // The API sends `carrier_logo` empty on every option, so the real
          // artwork comes from the shared AirlineLogo (Kiwi CDN, by IATA
          // code) — the same widget the flight search results use. It falls
          // back to a coloured initials tile on its own.
          logo: AirlineLogo(
            code: option.carrier,
            name: option.carrierName,
            size: context.w(38),
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          priceText: diyMoney(option.total, currency: widget.currency),
          // DIY quotes the whole party, not one adult — do not inherit the
          // flight module's "/adult" default here.
          perLabel: 'total',
          departureCity: diyDayDate(option.departureAt),
          departureCode: fromCode,
          departureTime: diyTime(option.departureAt),
          arrivalCity: diyDayDate(option.arrivalAt),
          arrivalCode: toCode,
          arrivalTime: diyTime(option.arrivalAt),
          duration: diyDuration(option.durationMinutes),
          stopsLabel: option.stops == 0
              ? 'Non stop'
              : '${option.stops} Stop${option.stops == 1 ? '' : 's'}',
          footer: _footer(option, applying),
        ),
      ),
    );
  }

  /// Everything below the route row: the fare pills, the difference this swap
  /// makes to the trip total, and the progress bar while it is applying.
  Widget _footer(DiyFlightOption option, bool applying) {
    final deltaColor = option.delta == 0
        ? DiyTokens.subGrey
        : option.delta < 0
            ? Colors.green.shade700
            : DiyTokens.orange;

    final pills = <Widget>[
      if (option.baggageChecked.isNotEmpty)
        _pill(context, '${option.baggageChecked} check-in'),
      if (option.refundable) _pill(context, 'Refundable'),
      if (option.seatsAvailable > 0 && option.seatsAvailable <= 5)
        _pill(
          context,
          '${option.seatsAvailable} seats left',
          color: DiyTokens.orange,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.h(12)),
        Container(height: 0.6, color: const Color(0xFFCCCCCC)),
        SizedBox(height: context.h(10)),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: context.w(6),
                runSpacing: context.h(4),
                children: pills,
              ),
            ),
            if (option.isSelected)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(9),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: DiyTokens.blue,
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Text(
                diyDelta(option.delta, currency: widget.currency),
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
          ],
        ),
        if (applying) ...[
          SizedBox(height: context.h(10)),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }

  Widget _pill(BuildContext context, String text, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: (color ?? DiyTokens.subGrey).withOpacity(0.10),
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(9.5),
          fontWeight: FontWeight.w600,
          color: color ?? DiyTokens.subGrey,
        ),
      ),
    );
  }
}
