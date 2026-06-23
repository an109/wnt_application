import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../UI_helper/responsive_layout.dart';
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
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  // Highlight colours for available (selectable) seats.
  static const _availableBorder = Color(0xFF2E9E5B);
  static const _availableFill = Color(0xFFE7F6EC);

  bool _isSeatSelected(SeatOptionEntity seat) =>
      _selectedSeats.any((s) => s.code == seat.code);

  double get _totalSeatPrice =>
      _selectedSeats.fold(0.0, (sum, s) => sum + s.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),

      body: BlocConsumer<SsrBloc, SsrState>(
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

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: context.h(12)),

          // SELECTION HINT
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(18)),
            child: Row(
              children: [
                Icon(Icons.event_seat, size: context.w(18), color: _blue),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    widget.travellerCount > 1
                        ? 'Select up to ${widget.travellerCount} seats for your travellers '
                              '(${_selectedSeats.length}/${widget.travellerCount} selected)'
                        : 'Select a seat for your traveller',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.h(12)),

          // AIRPLANE BODY
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(32)),
                  border: Border.all(color: const Color(0xFFE2E7F0)),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    SizedBox(height: context.h(20)),

                    // PLANE HEAD
                    // Container(
                    //   width: 120,
                    //   height: 40,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFE8ECF4),
                    //     borderRadius: BorderRadius.circular(30),
                    //   ),
                    // ),
                    //
                    // const SizedBox(height: 20),

                    // SEAT LABELS
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                      child: Row(
                        children: [
                          SizedBox(width: context.w(24)),

                          for (final label in const ['A', 'B', 'C'])
                            Expanded(child: Center(child: Text(label))),

                          SizedBox(width: context.w(36)),

                          for (final label in const ['D', 'E', 'F'])
                            Expanded(child: Center(child: Text(label))),
                        ],
                      ),
                    ),

                    SizedBox(height: context.h(10)),

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

                          return _buildPlaneRow(context, rowNumber, rowSeats);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SINGLE ROW
  // =========================

  Widget _buildPlaneRow(
    BuildContext context,
    String rowNumber,
    List<SeatOptionEntity> seats,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),

      child: Row(
        children: [
          SizedBox(width: context.w(10)),

          // ROW NUMBER
          SizedBox(
            width: context.w(24),
            child: Text(
              rowNumber,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // LEFT SIDE
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                if (index >= seats.length) {
                  return SizedBox(width: context.w(34));
                }

                final seat = seats[index];

                return _buildSeat(context, seat, _isSeatSelected(seat));
              }),
            ),
          ),

          // AISLE
          SizedBox(width: context.w(34)),

          // RIGHT SIDE
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final seatIndex = index + 3;

                if (seatIndex >= seats.length) {
                  return SizedBox(width: context.w(34));
                }

                final seat = seats[seatIndex];

                return _buildSeat(context, seat, _isSeatSelected(seat));
              }),
            ),
          ),

          SizedBox(width: context.w(10)),
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
  ) {
    final isBooked = !seat.isAvailable;

    return GestureDetector(
      onTap: isBooked ? null : () => _handleSeatSelection(seat),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SEAT TILE (icon) — only available seats are highlighted (green),
          // booked are greyed, selected are blue.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),

            width: context.w(34),
            height: context.w(34),
            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: isBooked
                  ? Colors.grey.shade300
                  : isSelected
                  ? _blue
                  : _availableFill,

              borderRadius: BorderRadius.circular(context.r(8)),

              border: Border.all(
                color: isBooked
                    ? Colors.grey.shade400
                    : isSelected
                    ? _blue
                    : _availableBorder,
              ),
            ),

            child: Icon(
              Icons.event_seat,
              size: context.w(18),
              color: isBooked
                  ? Colors.grey
                  : isSelected
                  ? Colors.white
                  : _availableBorder,
            ),
          ),

          SizedBox(height: context.h(2)),

          // SEAT NUMBER (below the icon)
          Text(
            seat.seatLabel,
            maxLines: 1,
            style: TextStyle(
              fontSize: context.fs(9),
              fontWeight: FontWeight.w600,
              color: isBooked ? Colors.grey.shade500 : _navy,
            ),
          ),
        ],
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
