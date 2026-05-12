import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../UI_helper/responsive_layout.dart';
import '../../../domain/entities/seat_option_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';

class SeatScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final int? selectedSegmentIndex;
  final Function(SeatOptionEntity?)? onSeatSelected;

  const SeatScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    this.selectedSegmentIndex,
    this.onSeatSelected,
  });

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  SeatOptionEntity? _selectedSeat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: BlocConsumer<SsrBloc, SsrState>(
        listener: (context, state) {
          if (state is SsrError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          }
        },

        builder: (context, state) {
          if (state is SsrLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SsrError) {
            return _buildErrorState(state.message);
          }

          if (state is SsrLoaded) {
            return _buildSeatContent(state.ssrData);
          }

          return const Center(
            child: Text("No seats available"),
          );
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
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                context.read<SsrBloc>().add(
                  LoadSsrData(
                    endUserIp: '::1',
                    traceId: widget.traceId,
                    tokenId: widget.tokenId,
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
      return const Center(
        child: Text("No seats available"),
      );
    }

    final Map<String, List<SeatOptionEntity>> seatsByRow = {};

    for (final seat in seats) {
      seatsByRow.putIfAbsent(seat.rowNo, () => []);
      seatsByRow[seat.rowNo]!.add(seat);
    }

    final sortedRows = seatsByRow.keys.toList()
      ..sort(
            (a, b) => int.parse(a).compareTo(int.parse(b)),
      );

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),

          // AIRPLANE BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // PLANE HEAD
                    Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SEAT LABELS
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Row(
                        children: const [
                          SizedBox(width: 24),

                          Expanded(
                            child: Center(
                              child: Text("A"),
                            ),
                          ),

                          Expanded(
                            child: Center(
                              child: Text("B"),
                            ),
                          ),

                          Expanded(
                            child: Center(
                              child: Text("C"),
                            ),
                          ),

                          SizedBox(width: 36),

                          Expanded(
                            child: Center(
                              child: Text("D"),
                            ),
                          ),

                          Expanded(
                            child: Center(
                              child: Text("E"),
                            ),
                          ),

                          Expanded(
                            child: Center(
                              child: Text("F"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // SEAT ROWS
                    Expanded(
                      child: ListView.builder(
                        padding:
                        const EdgeInsets.only(bottom: 20),
                        itemCount: sortedRows.length,
                        itemBuilder: (context, index) {
                          final rowNumber =
                          sortedRows[index];

                          final rowSeats =
                          List<SeatOptionEntity>.from(
                            seatsByRow[rowNumber]!,
                          )..sort(
                                (a, b) => a.seatNo
                                .compareTo(
                              b.seatNo,
                            ),
                          );

                          return _buildPlaneRow(
                            rowNumber,
                            rowSeats,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM SELECTION BAR
          if (_selectedSeat != null)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom:
                MediaQuery.of(context)
                    .padding
                    .bottom +
                    14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Seat ${_selectedSeat!.seatLabel}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _selectedSeat!
                              .displayPrice,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                            Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSeatSelected
                            ?.call(_selectedSeat);

                        Navigator.pop(context);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.black,
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
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

  // =========================
  // SINGLE ROW
  // =========================

  Widget _buildPlaneRow(
      String rowNumber,
      List<SeatOptionEntity> seats,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Row(
        children: [
          const SizedBox(width: 10),

          // ROW NUMBER
          SizedBox(
            width: 24,
            child: Text(
              rowNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // LEFT SIDE
          Expanded(
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                    (index) {
                  if (index >= seats.length) {
                    return const SizedBox(
                      width: 34,
                    );
                  }

                  final seat = seats[index];

                  return _buildSeat(
                    seat,
                    _selectedSeat?.code ==
                        seat.code,
                  );
                },
              ),
            ),
          ),

          // AISLE
          const SizedBox(width: 34),

          // RIGHT SIDE
          Expanded(
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                    (index) {
                  final seatIndex =
                      index + 3;

                  if (seatIndex >=
                      seats.length) {
                    return const SizedBox(
                      width: 34,
                    );
                  }

                  final seat =
                  seats[seatIndex];

                  return _buildSeat(
                    seat,
                    _selectedSeat?.code ==
                        seat.code,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // =========================
  // SINGLE SEAT
  // =========================

  Widget _buildSeat(
      SeatOptionEntity seat,
      bool isSelected,
      ) {
    final isBooked = !seat.isAvailable;

    return GestureDetector(
      onTap: isBooked
          ? null
          : () => _handleSeatSelection(seat),

      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 200),

        width: 34,
        height: 34,

        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey.shade300
              : isSelected
              ? Colors.black
              : Colors.white,

          borderRadius:
          BorderRadius.circular(8),

          border: Border.all(
            color: isSelected
                ? Colors.black
                : Colors.grey.shade400,
          ),
        ),

        child: Icon(
          Icons.event_seat,
          size: 18,
          color: isBooked
              ? Colors.grey
              : isSelected
              ? Colors.white
              : Colors.black87,
        ),
      ),
    );
  }

  // =========================
  // SEAT SELECTION
  // =========================

  void _handleSeatSelection(
      SeatOptionEntity seat,
      ) {
    setState(() {
      if (_selectedSeat?.code ==
          seat.code) {
        _selectedSeat = null;
      } else {
        _selectedSeat = seat;
      }
    });

    widget.onSeatSelected?.call(
      _selectedSeat,
    );
  }
}