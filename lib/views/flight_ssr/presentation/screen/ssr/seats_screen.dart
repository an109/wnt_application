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
    return BlocConsumer<SsrBloc, SsrState>(
      listener: (context, state) {
        if (state is SsrError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SsrLoading) {
          return _buildLoadingState();
        }

        if (state is SsrError) {
          return _buildErrorState(state.message);
        }

        if (state is SsrLoaded) {
          return _buildSeatContent(state.ssrData);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.iconLarge,
            height: context.iconLarge,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Loading seat map...',
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.gapLarge / 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.airline_seat_recline_normal_outlined,
              size: context.iconLarge,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Unable to load seat map',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Padding(
            padding: context.horizontalPadding,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: context.gapLarge),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.buttonWidth * 0.3,
                vertical: context.gapMedium / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadius),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.gapLarge / 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.airline_seat_recline_normal_outlined,
              size: context.iconLarge,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Seat selection not available',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Seats will appear here once available for selection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatContent(SsrEntity ssrData) {
    final seats = ssrData.seatOptions;

    if (seats == null || seats.isEmpty) {
      return _buildEmptyState();
    }

    // Filter available seats only
    final availableSeats = seats.where((s) => s.isAvailable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: context.horizontalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Seat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.titleMedium,
                ),
              ),
              SizedBox(height: context.gapSmall),
              Text(
                'Select a comfortable seat for your journey',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.gapMedium),

        // Legend
        _buildSeatLegend(),

        SizedBox(height: context.gapMedium),

        // Seat grid
        Expanded(
          child: availableSeats.isEmpty
              ? _buildNoAvailableSeats()
              : GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapSmall,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: context.gapSmall,
              mainAxisSpacing: context.gapSmall,
              childAspectRatio: 0.85,
            ),
            itemCount: availableSeats.length,
            itemBuilder: (context, index) {
              final seat = availableSeats[index];
              final isSelected = _selectedSeat?.code == seat.code;

              return _buildSeatCard(
                context,
                seat: seat,
                isSelected: isSelected,
                onTap: () => _handleSeatSelection(seat),
              );
            },
          ),
        ),

        // Selected seat info
        if (_selectedSeat != null) _buildSelectedSeatInfo(),
      ],
    );
  }

  Widget _buildSeatLegend() {
    return Padding(
      padding: context.horizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Available', Colors.grey.shade600, Colors.grey.shade100),
          SizedBox(width: context.gapMedium),
          _buildLegendItem('Selected', Colors.blue, Colors.blue.shade50),
          SizedBox(width: context.gapMedium),
          _buildLegendItem('Free', Colors.green.shade600, Colors.green.shade50),
          SizedBox(width: context.gapMedium),
          _buildLegendItem('Unavailable', Colors.grey.shade400, Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color iconColor, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: iconColor, width: 1),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: context.labelSmall, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildNoAvailableSeats() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: context.iconLarge,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'No seats available',
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatCard(
      BuildContext context, {
        required SeatOptionEntity seat,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: seat.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(context.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: seat.seatBgColor,
            borderRadius: BorderRadius.circular(context.borderRadius),
            border: Border.all(
              color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Seat icon
              Icon(
                seat.seatIcon,
                size: 20,
                color: seat.seatColor,
              ),
              SizedBox(height: context.gapSmall / 2),

              // Seat label
              Text(
                seat.seatLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodyMedium,
                  color: seat.isAvailable ? Colors.grey.shade800 : Colors.grey.shade400,
                ),
              ),

              // Price badge
              if (seat.price > 0)
                Padding(
                  padding: EdgeInsets.only(top: context.gapSmall / 4),
                  child: Text(
                    seat.displayPrice,
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: seat.isFree ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Seat type indicator
              if (seat.seatTypeLabel != 'Standard')
                Padding(
                  padding: EdgeInsets.only(top: context.gapSmall / 4),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      seat.seatTypeLabel[0], // W, A, or M
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSeatInfo() {
    if (_selectedSeat == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.gapMedium,
        0,
        context.gapMedium,
        context.gapMedium,
      ),
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.blue.shade600,
            size: 24,
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected: ${_selectedSeat!.seatLabel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodyLarge,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  '${_selectedSeat!.seatTypeLabel} seat · ${_selectedSeat!.displayPrice}',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedSeat = null);
              widget.onSeatSelected?.call(null);
            },
            child: Text(
              'Change',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSeatSelection(SeatOptionEntity seat) {
    setState(() {
      _selectedSeat = seat;
    });
    widget.onSeatSelected?.call(seat);
    print('Seat selected: ${seat.seatLabel} - ${seat.seatTypeLabel}');
  }
}