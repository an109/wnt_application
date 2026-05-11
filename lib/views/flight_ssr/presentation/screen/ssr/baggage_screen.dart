import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../domain/entities/baggage_option_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';


class BaggageScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final String endUserIp;
  final int? selectedSegmentIndex;
  final Function(List<BaggageOptionEntity>?, int)? onBaggageSelected;

  const BaggageScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    required this.endUserIp,
    this.selectedSegmentIndex,
    this.onBaggageSelected,
  });

  @override
  State<BaggageScreen> createState() => _BaggageScreenState();
}

class _BaggageScreenState extends State<BaggageScreen> {
  int _currentSegmentIndex = 0;
  int? _selectedBaggageIndex;

  @override
  void initState() {
    super.initState();
    _loadSsrData();
  }

  void _loadSsrData() {
    context.read<SsrBloc>().add(
      LoadSsrData(
        endUserIp: widget.endUserIp,
        traceId: widget.traceId,
        tokenId: widget.tokenId,
        resultIndex: widget.resultIndex,
      ),
    );
  }

  void _handleBaggageSelection(int index, BaggageOptionEntity option) {
    setState(() {
      _selectedBaggageIndex = index;
    });

    final segmentBaggage = _getCurrentSegmentBaggage();
    widget.onBaggageSelected?.call(segmentBaggage, index);
  }

  List<BaggageOptionEntity>? _getCurrentSegmentBaggage() {
    final state = context.read<SsrBloc>().state;
    if (state is SsrLoaded) {
      final baggage = state.ssrData.baggageOptions;
      if (baggage != null && baggage.isNotEmpty) {
        final segmentIndex = widget.selectedSegmentIndex ?? _currentSegmentIndex;
        if (segmentIndex < baggage.length) {
          return baggage[segmentIndex];
        }
      }
    }
    return null;
  }

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
          return _buildBaggageContent(state.ssrData);
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
            'Loading baggage options...',
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
              Icons.error_outline,
              size: context.iconLarge,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Unable to load baggage options',
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
            onPressed: _loadSsrData,
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
              Icons.luggage_outlined,
              size: context.iconLarge,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'No baggage options available',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Baggage options will appear here once available',
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

  Widget _buildBaggageContent(SsrEntity ssrData) {
    final baggageSegments = ssrData.baggageOptions;

    if (baggageSegments == null || baggageSegments.isEmpty) {
      return _buildEmptyState();
    }

    final currentSegmentIndex = widget.selectedSegmentIndex ?? _currentSegmentIndex;
    final segmentBaggage = currentSegmentIndex < baggageSegments.length
        ? baggageSegments[currentSegmentIndex]
        : <BaggageOptionEntity>[];

    return Column(
      children: [
        // Flight info card
        if (segmentBaggage.isNotEmpty)
          _buildFlightInfoCard(segmentBaggage.first),

        // Segment selector (if multiple segments)
        if (baggageSegments.length > 1)
          _buildSegmentSelector(baggageSegments.length),

        // Baggage options list
        Expanded(
          child: segmentBaggage.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapSmall,
            ),
            itemCount: segmentBaggage.length,
            itemBuilder: (context, index) {
              final option = segmentBaggage[index];
              final isSelected = _selectedBaggageIndex == index;

              return _buildBaggageOptionCard(
                context,
                option: option,
                isSelected: isSelected,
                onTap: () => _handleBaggageSelection(index, option),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlightInfoCard(BaggageOptionEntity firstOption) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.gapMedium,
        context.gapMedium,
        context.gapMedium,
        0,
      ),
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Airline logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                firstOption.airlineCode,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.titleSmall,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: context.gapMedium),

          // Flight details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getAirlineName(firstOption.airlineCode)} · ${firstOption.flightNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodyLarge,
                  ),
                ),
                SizedBox(height: context.gapSmall / 2),
                Text(
                  '${firstOption.origin} → ${firstOption.destination}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Baggage badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapSmall,
              vertical: context.gapSmall / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '1 Bag Included',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: context.labelSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSelector(int segmentCount) {
    return Container(
      margin: EdgeInsets.only(top: context.gapMedium),
      padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: segmentCount,
          separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
          itemBuilder: (context, index) {
            final isSelected = index == (widget.selectedSegmentIndex ?? _currentSegmentIndex);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentSegmentIndex = index;
                  _selectedBaggageIndex = null;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapMedium,
                  vertical: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 0 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Segment ${index + 1}',
                    style: TextStyle(
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBaggageOptionCard(
      BuildContext context, {
        required BaggageOptionEntity option,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Container(
            padding: EdgeInsets.all(context.gapMedium),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(context.borderRadius),
              border: Border.all(
                color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                  )
                      : null,
                ),
                SizedBox(width: context.gapMedium),

                // Icon
                Container(
                  padding: EdgeInsets.all(context.gapSmall),
                  decoration: BoxDecoration(
                    color: option.isNoBaggage
                        ? Colors.grey.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    option.isNoBaggage ? Icons.no_luggage : Icons.luggage,
                    color: option.isNoBaggage
                        ? Colors.grey.shade600
                        : Colors.blue.shade700,
                    size: 26,
                  ),
                ),
                SizedBox(width: context.gapMedium),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.bodyLarge,
                        ),
                      ),
                      SizedBox(height: context.gapSmall / 2),
                      if (option.displaySubtitle.isNotEmpty)
                        Text(
                          option.displaySubtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: context.bodySmall,
                          ),
                        ),
                      if (option.weight > 0 && !option.isNoBaggage)
                        Padding(
                          padding: EdgeInsets.only(top: context.gapSmall / 2),
                          child: Text(
                            'Up to ${option.weight} kg',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: context.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      option.displayPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.bodyLarge,
                        color: option.isFree
                            ? Colors.green.shade700
                            : Colors.black87,
                      ),
                    ),
                    if (option.pricePerKg.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: context.gapSmall / 2),
                        child: Text(
                          option.pricePerKg,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: context.labelSmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAirlineName(String code) {
    final airlines = {
      'SG': 'SpiceJet',
      'AI': 'Air India',
      '6E': 'IndiGo',
      'UK': 'Vistara',
      'I5': 'AirAsia',
    };
    return airlines[code] ?? code;
  }
}