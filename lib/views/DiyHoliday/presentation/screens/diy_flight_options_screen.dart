import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

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

  Widget _tile(DiyFlightOption option) {
    final applying = _applyingRef == option.offerRef;
    final deltaColor = option.delta == 0
        ? DiyTokens.subGrey
        : option.delta < 0
            ? Colors.green.shade700
            : DiyTokens.orange;

    return DiyCard(
      borderColor: option.isSelected ? DiyTokens.blue : null,
      onTap: applying ? null : () => _select(option),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                alignment: Alignment.center,
                child: option.carrierLogo.isNotEmpty
                    ? DiyImage(
                        url: option.carrierLogo,
                        width: context.w(22),
                        height: context.w(22),
                        fit: BoxFit.contain,
                      )
                    : Text(
                        option.carrier,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w800,
                          color: DiyTokens.navy,
                        ),
                      ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.carrierName,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.navy,
                      ),
                    ),
                    Text(
                      option.flightNumber,
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (option.isSelected)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(3),
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
                ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              _timeColumn(diyTime(option.departureAt), 'Departs'),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      diyDuration(option.durationMinutes),
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.h(3)),
                      child: const Divider(height: 1, color: DiyTokens.line),
                    ),
                    Text(
                      option.stops == 0
                          ? 'Non-stop'
                          : '${option.stops} stop${option.stops == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _timeColumn(diyTime(option.arrivalAt), 'Arrives'),
            ],
          ),
          SizedBox(height: context.h(10)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: context.w(6),
                  runSpacing: context.h(4),
                  children: [
                    if (option.baggageChecked.isNotEmpty)
                      _pill(context, '${option.baggageChecked} check-in'),
                    if (option.refundable) _pill(context, 'Refundable'),
                    if (option.seatsAvailable > 0 && option.seatsAvailable <= 5)
                      _pill(
                        context,
                        '${option.seatsAvailable} seats left',
                        color: DiyTokens.orange,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    diyMoney(option.total, currency: widget.currency),
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w800,
                      color: DiyTokens.navy,
                    ),
                  ),
                  Text(
                    diyDelta(option.delta, currency: widget.currency),
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w600,
                      color: deltaColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (applying) ...[
            SizedBox(height: context.h(10)),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  Widget _timeColumn(String time, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
        Text(
          caption,
          style: TextStyle(
            fontSize: context.fs(10),
            color: DiyTokens.labelGrey,
          ),
        ),
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
