import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../../core/resources/app_colours.dart';
import '../../../domain/entities/seat_option_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';
import 'ssr_price_formatter.dart';

class SeatScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final int? selectedSegmentIndex;

  /// How many seats the user is allowed to pick (= number of travellers).
  final int travellerCount;
  final Function(List<SeatOptionEntity>)? onSeatsSelected;

  const SeatScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    this.selectedSegmentIndex,
    this.travellerCount = 1,
    this.onSeatsSelected,
  });

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  final List<SeatOptionEntity> _selectedSeats = [];
  static const _stroke = Color(0xFFCCCCCC);
  // Figma "Free" swatch — matches the section's Sec/orange token.
  static const _freeColor = AppColors.OrangeColor;

  bool _isSeatSelected(SeatOptionEntity seat) =>
      _selectedSeats.any((s) => s.code == seat.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: BlocConsumer<SsrBloc, SsrState>(
        listener: (context, state) {
          if (state is SsrError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },

        builder: (context, state) {
          if (state is SsrLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SsrError) {
            return _buildErrorState(state.message);
          }

          if (state is SsrLoaded) {
            return _buildSeatContent(state.ssrData);
          }

          return const Center(child: Text("No seats available"));
        },
      ),
    );
  }

  // =========================
  // ERROR STATE
  // =========================

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),

            const SizedBox(height: 12),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                context.read<SsrBloc>().add(
                  LoadSsrData(
                    endUserIp: '122.161.72.69',
                    traceId: widget.traceId,
                    tokenId: widget.tokenId,
                    // resultIndex: 'OB1',
                    resultIndex: widget.resultIndex,
                  ),
                );
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // MAIN SEAT CONTENT
  // =========================

  Widget _buildSeatContent(SsrEntity ssrData) {
    final seats = ssrData.seatOptions;

    if (seats == null || seats.isEmpty) {
      return const Center(child: Text("No seats available"));
    }

    final Map<String, List<SeatOptionEntity>> seatsByRow = {};

    for (final seat in seats) {
      seatsByRow.putIfAbsent(seat.rowNo, () => []);
      seatsByRow[seat.rowNo]!.add(seat);
    }

    final sortedRows = seatsByRow.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final bands = _PriceBands.from(seats);

    return Column(
      children: [
        SizedBox(height: context.h(12)),

        // SELECTION HINT
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(18)),
          child: Text(
            widget.travellerCount > 1
                ? 'Select up to ${widget.travellerCount} seats for your travellers '
                      '(${_selectedSeats.length}/${widget.travellerCount} selected)'
                : 'Select a seat for your traveller',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
              color: AppColors.subhead,
            ),
          ),
        ),

        SizedBox(height: context.h(16)),

        // SEAT LABELS
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(18)),
          child: Row(
            children: [
              for (final label in const ['A', 'B', 'C'])
                Expanded(child: Center(child: _colLabel(context, label))),
              SizedBox(width: context.w(24)),
              for (final label in const ['D', 'E', 'F'])
                Expanded(child: Center(child: _colLabel(context, label))),
            ],
          ),
        ),

        SizedBox(height: context.h(12)),

        // SEAT ROWS
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: context.h(20)),
            itemCount: sortedRows.length,
            itemBuilder: (context, index) {
              final rowNumber = sortedRows[index];

              final rowSeats = List<SeatOptionEntity>.from(
                seatsByRow[rowNumber]!,
              )..sort((a, b) => a.seatNo.compareTo(b.seatNo));

              return _buildPlaneRow(context, rowNumber, rowSeats, bands);
            },
          ),
        ),

        _legend(context, bands),
      ],
    );
  }

  Widget _colLabel(BuildContext context, String label) => Text(
        label,
        style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: AppColors.subhead),
      );

  // =========================
  // SINGLE ROW
  // =========================

  Widget _buildPlaneRow(
    BuildContext context,
    String rowNumber,
    List<SeatOptionEntity> seats,
    _PriceBands bands,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(6), horizontal: context.w(16)),

      child: Row(
        children: [
          // LEFT SIDE
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                if (index >= seats.length) {
                  return SizedBox(width: context.w(39.33));
                }

                final seat = seats[index];

                return _buildSeat(context, seat, _isSeatSelected(seat), bands);
              }),
            ),
          ),

          // ROW NUMBER
          SizedBox(
            width: context.w(24),
            child: Center(
              child: Text(
                rowNumber,
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w700,
                  color: AppColors.subhead,
                ),
              ),
            ),
          ),

          // RIGHT SIDE
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final seatIndex = index + 3;

                if (seatIndex >= seats.length) {
                  return SizedBox(width: context.w(39.33));
                }

                final seat = seats[seatIndex];

                return _buildSeat(context, seat, _isSeatSelected(seat), bands);
              }),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SINGLE SEAT
  // =========================

  Widget _buildSeat(
    BuildContext context,
    SeatOptionEntity seat,
    bool isSelected,
    _PriceBands bands,
  ) {
    final isBooked = !seat.isAvailable;
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: context.w(39.33),
      height: context.h(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.AppBlue : bands.fillColor(seat),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: isBooked || isSelected
            ? null
            : Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.AppBlue.withValues(alpha: 0.3), blurRadius: 1, offset: const Offset(0, 1))]
            : null,
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : isBooked
              ? Icon(Icons.close, size: context.w(10), color: AppColors.subhead.withValues(alpha: 0.6))
              : null,
    );

    return GestureDetector(
      onTap: isBooked ? null : () => _handleSeatSelection(seat),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (isSelected)
            Positioned(
              top: -context.h(26),
              left: -context.w(20),
              child: _seatBubble(context, seat),
            ),
        ],
      ),
    );
  }

  Widget _seatBubble(BuildContext context, SeatOptionEntity seat) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: AppColors.AppBlue),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Text(
        '${seat.seatLabel} | ${SsrPriceFormatter.format(seat.price, seat.currency)}',
        style: TextStyle(color: AppColors.AppBlue, fontSize: context.fs(11), fontWeight: FontWeight.w700),
      ),
    );
  }

  // =========================
  // LEGEND (Figma: colour key derived from the real price bands above)
  // =========================
  Widget _legend(BuildContext context, _PriceBands bands) {
    Widget swatch(Color color, String label, {Border? border}) => Padding(
          padding: EdgeInsets.only(right: context.w(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(12),
                height: context.w(12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2), border: border),
              ),
              SizedBox(width: context.w(4)),
              Text(label, style: TextStyle(color: AppColors.subhead, fontSize: context.fs(8))),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            swatch(_freeColor, 'Free'),
            if (bands.hasLow) swatch(bands.lowColor, bands.lowLabel),
            if (bands.hasHigh) swatch(bands.highColor, bands.highLabel),
            swatch(Colors.grey.shade300, 'Booked', border: Border.all(color: _stroke)),
          ],
        ),
      ),
    );
  }

  // =========================
  // SEAT SELECTION
  // =========================

  void _handleSeatSelection(SeatOptionEntity seat) {
    final existingIndex = _selectedSeats.indexWhere((s) => s.code == seat.code);

    // Block selecting more seats than there are travellers.
    if (existingIndex < 0 && _selectedSeats.length >= widget.travellerCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can select up to ${widget.travellerCount} '
            'seat${widget.travellerCount > 1 ? 's' : ''} for your travellers',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        _selectedSeats.removeAt(existingIndex);
      } else {
        _selectedSeats.add(seat);
      }
    });

    widget.onSeatsSelected?.call(_selectedSeats);
  }
}

/// Two paid price tiers derived from the real seat prices in this flight's
/// SSR response (split at the median of non-free, available seats) — Figma
/// shows a "₹390 - ₹715" / "₹823 - ₹2455" style legend, but those numbers
/// have to come from the actual fare data, not be hardcoded.
class _PriceBands {
  final double? lowMin, lowMax, highMin, highMax;
  final Color lowColor;
  final Color highColor;

  _PriceBands({this.lowMin, this.lowMax, this.highMin, this.highMax})
      : lowColor = AppColors.AppBlue.withValues(alpha: 0.24),
        highColor = AppColors.AppBlue;

  bool get hasLow => lowMin != null;
  bool get hasHigh => highMin != null;

  String get lowLabel => hasLow ? '${_fmt(lowMin!)} - ${_fmt(lowMax!)}' : '';
  String get highLabel => hasHigh ? '${_fmt(highMin!)} - ${_fmt(highMax!)}' : '';

  static String _fmt(double v) => '₹${v.toStringAsFixed(0)}';

  factory _PriceBands.from(List<SeatOptionEntity> seats) {
    final paid = seats
        .where((s) => s.isAvailable && !s.isFree)
        .map((s) => s.price)
        .toList()
      ..sort();
    if (paid.isEmpty) return _PriceBands();

    final mid = (paid.length / 2).floor().clamp(1, paid.length);
    final low = paid.sublist(0, mid);
    final high = paid.sublist(mid.clamp(0, paid.length - 1));
    if (high.isEmpty) {
      return _PriceBands(lowMin: low.first, lowMax: low.last);
    }
    return _PriceBands(
      lowMin: low.first,
      lowMax: low.last,
      highMin: high.first,
      highMax: high.last,
    );
  }

  Color fillColor(SeatOptionEntity seat) {
    if (!seat.isAvailable) return Colors.grey.shade300;
    if (seat.isFree) return AppColors.OrangeColor.withValues(alpha: 0.15);
    if (hasHigh && seat.price >= highMin!) return highColor;
    return lowColor;
  }
}
