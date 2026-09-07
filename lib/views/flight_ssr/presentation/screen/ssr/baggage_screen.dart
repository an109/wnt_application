import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../../core/resources/app_colours.dart';
import '../../../domain/entities/baggage_option_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';
import 'ssr_price_formatter.dart';

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
        final segmentIndex =
            widget.selectedSegmentIndex ?? _currentSegmentIndex;
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
            child: Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
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

    final currentSegmentIndex =
        widget.selectedSegmentIndex ?? _currentSegmentIndex;
    final segmentBaggage = currentSegmentIndex < baggageSegments.length
        ? baggageSegments[currentSegmentIndex]
        : <BaggageOptionEntity>[];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Segment selector (if multiple segments) — the route/airline
          // badge itself now lives in the shared Add-ons header.
          if (baggageSegments.length > 1)
            _buildSegmentSelector(baggageSegments.length),

          SizedBox(height: context.h(baggageSegments.length > 1 ? 8 : 20)),

          // Baggage options list
          Expanded(
            child: segmentBaggage.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                    itemCount: segmentBaggage.length,
                    separatorBuilder: (_, __) => SizedBox(height: context.h(24)),
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
          separatorBuilder: (context, index) =>
              SizedBox(width: context.gapSmall),
          itemBuilder: (context, index) {
            final isSelected =
                index == (widget.selectedSegmentIndex ?? _currentSegmentIndex);

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
                            color: Colors.blue.withValues(alpha: 0.3),
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

  // Figma "Flighjt BAGGAGE": a plain bordered row per option; the selected
  // one gets a pale-blue tint, a blue border, and a check badge straddling
  // its top-right corner.
  Widget _buildBaggageOptionCard(
    BuildContext context, {
    required BaggageOptionEntity option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.r(8)),
            child: Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.AppBlue.withValues(alpha: 0.04) : Colors.white,
                borderRadius: BorderRadius.circular(context.r(8)),
                border: Border.all(
                  color: isSelected ? AppColors.AppBlue : const Color(0xFFCCCCCC),
                  width: isSelected ? 0.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: context.w(38),
                    height: context.h(39),
                    alignment: Alignment.center,
                    child: Icon(
                      option.isNoBaggage ? Icons.no_luggage : Icons.luggage,
                      color: AppColors.AppBlue,
                      size: context.w(24),
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.displayTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.fs(14),
                            color: const Color(0xFF111527),
                          ),
                        ),
                        if (option.displaySubtitle.isNotEmpty)
                          Text(
                            option.displaySubtitle,
                            style: TextStyle(color: AppColors.subhead, fontSize: context.fs(8)),
                          ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: SsrPriceFormatter.format(option.price, option.currency),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.fs(14),
                            color: const Color(0xFF111527),
                          ),
                        ),
                        if (!option.isFree)
                          TextSpan(
                            text: '/person',
                            style: TextStyle(color: AppColors.subhead, fontSize: context.fs(8)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            right: -context.w(6),
            top: -context.h(12),
            child: Container(
              width: context.w(24),
              height: context.w(24),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: AppColors.AppBlue, size: context.w(24)),
            ),
          ),
      ],
    );
  }
}
