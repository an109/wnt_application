import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// Cab class picker — **GET /trips/{trip_id}/cab/** for the options and
/// **POST /trips/{trip_id}/cab/** `{"code": …}` to change it.
///
/// There is no transfer endpoint: transfers are derived from the route and
/// the cab, so changing the class here rewrites the trip's transfer rows too.
/// A class that cannot seat the party comes back as 422 with the seat counts,
/// which is surfaced verbatim.
Future<DiyTrip?> showDiyCabSheet(
  BuildContext context, {
  required DiyTrip trip,
}) {
  return showModalBottomSheet<DiyTrip>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(18))),
    ),
    builder: (_) => _DiyCabSheet(trip: trip),
  );
}

class _DiyCabSheet extends StatefulWidget {
  final DiyTrip trip;

  const _DiyCabSheet({required this.trip});

  String get tripId => trip.tripId;

  @override
  State<_DiyCabSheet> createState() => _DiyCabSheetState();
}

class _DiyCabSheetState extends State<_DiyCabSheet> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  DiyCabOptions _options = DiyCabOptions.empty;
  bool _loading = true;
  String? _error;
  String? _applyingCode;

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
      final options = await _api.getCabOptions(widget.tripId);
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

  Future<void> _select(DiyCabOption option) async {
    if (option.isSelected) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _applyingCode = option.code);
    try {
      final trip = await _api.changeCab(
        tripId: widget.tripId,
        code: option.code,
        previous: widget.trip,
      );
      if (!mounted) return;
      Navigator.of(context).pop(trip);
    } on DiyApiException catch (e) {
      if (!mounted) return;
      // 422 = the class cannot seat the party; the detail carries the numbers.
      final extra = e.isUnprocessable && e.detail != null
          ? ' (${e.detail!.entries.map((kv) => '${kv.key}: ${kv.value}').join(', ')})'
          : '';
      diySnack(context, '${e.message}$extra', isError: true);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _applyingCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(16),
          context.w(20),
          context.h(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E6EC),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: context.h(14)),
            Text(
              'Cab class',
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
            SizedBox(height: context.h(3)),
            Text(
              'Airport pickups and intercity transfers follow the cab you pick.',
              style: TextStyle(
                fontSize: context.fs(11.5),
                color: DiyTokens.subGrey,
              ),
            ),
            SizedBox(height: context.h(14)),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: DiyLoading(message: 'Loading cab classes…'),
              )
            else if (_error != null)
              DiyErrorView(message: _error!, onRetry: _load)
            else
              for (final option in _options.options)
                Padding(
                  padding: EdgeInsets.only(bottom: context.h(10)),
                  child: _tile(option),
                ),
          ],
        ),
      ),
    );
  }

  Widget _tile(DiyCabOption option) {
    final applying = _applyingCode == option.code;
    return DiyCard(
      borderColor: option.isSelected ? DiyTokens.blue : null,
      onTap: applying ? null : () => _select(option),
      child: Row(
        children: [
          Icon(
            Icons.local_taxi_rounded,
            size: context.w(22),
            color: option.isSelected ? DiyTokens.blue : DiyTokens.subGrey,
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  '${option.seats} seats · ${option.luggage} bags',
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    color: DiyTokens.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          if (applying)
            SizedBox(
              width: context.w(18),
              height: context.w(18),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else if (option.isSelected)
            Icon(
              Icons.check_circle_rounded,
              color: DiyTokens.blue,
              size: context.w(20),
            ),
        ],
      ),
    );
  }
}
