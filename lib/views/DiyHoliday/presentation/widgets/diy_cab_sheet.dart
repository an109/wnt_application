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
  // Same palette as the transport search result card, so a transfer reads the
  // same whether the customer reaches it from Transport or from a holiday.
  static const Color _cardBorder = Color(0xffE3E5E8);
  static const Color _panelBg = Color(0xffF0F4F9);
  static const Color _bulletText = Color(0xff4F4F4F);
  static const LinearGradient _labelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xff7AD3F7), DiyTokens.blue],
  );

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

  /// Laid out like the transport search result card: a tinted image panel on
  /// the left with the class name on a gradient strip along its bottom, and
  /// the description, capacity bullets and state on the right.
  Widget _tile(DiyCabOption option) {
    final applying = _applyingCode == option.code;
    final radius = BorderRadius.circular(context.r(10));

    return Opacity(
      opacity: _applyingCode != null && !applying ? 0.55 : 1,
      child: GestureDetector(
        onTap: _applyingCode != null ? null : () => _select(option),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(
              color: option.isSelected ? DiyTokens.blue : _cardBorder,
              width: option.isSelected ? 1 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.h(88)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _imagePanel(option),
                    Expanded(child: _details(option, applying)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePanel(DiyCabOption option) {
    final labelH = context.h(18);

    return Container(
      width: context.w(98),
      color: _panelBg,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: labelH,
            child: Padding(
              padding: EdgeInsets.all(context.w(6)),
              // The endpoint sends `image` empty for every class, so the
              // vehicle is drawn as a class-appropriate icon rather than one
              // generic taxi glyph for all four.
              child: option.image.isNotEmpty
                  ? DiyImage(url: option.image, fit: BoxFit.contain)
                  : Center(
                      child: Icon(
                        _iconFor(option),
                        size: context.w(34),
                        color: option.isSelected
                            ? DiyTokens.blue
                            : DiyTokens.subGrey,
                      ),
                    ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: labelH,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: _labelGradient),
              child: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bigger body for bigger vehicles — a Tempo Traveller reading as a sedan
  /// would misrepresent what the customer is booking.
  IconData _iconFor(DiyCabOption option) {
    final code = option.code.toUpperCase();
    if (code.contains('TEMPO') || code.contains('BUS')) {
      return Icons.airport_shuttle_rounded;
    }
    if (code.contains('SUV') || code.contains('MUV')) {
      return Icons.directions_car_filled_rounded;
    }
    return Icons.directions_car_rounded;
  }

  Widget _details(DiyCabOption option, bool applying) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(10),
        context.h(8),
        context.w(10),
        context.h(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  option.label.isNotEmpty ? option.label : option.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w600,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
              if (applying)
                SizedBox(
                  width: context.w(16),
                  height: context.w(16),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else if (option.isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: DiyTokens.blue,
                  size: context.w(18),
                ),
            ],
          ),
          SizedBox(height: context.h(5)),
          Wrap(
            spacing: context.w(8),
            runSpacing: context.h(2),
            children: [
              _bullet('${option.seats} seats'),
              _bullet('${option.luggage} bags'),
              if (option.isSelected) _bullet('In your trip'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.w(4),
          height: context.w(4),
          decoration: const BoxDecoration(
            color: _bulletText,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.w(4)),
        Text(
          text,
          style: TextStyle(
            fontSize: context.fs(9.5),
            color: _bulletText,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
