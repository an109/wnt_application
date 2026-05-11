import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../domain/entities/service_selection_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';


class SpecialServiceScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final Function(List<SpecialServiceEntity>)? onServicesSelected;

  const SpecialServiceScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    this.onServicesSelected,
  });

  @override
  State<SpecialServiceScreen> createState() => _SpecialServiceScreenState();
}

class _SpecialServiceScreenState extends State<SpecialServiceScreen> {
  final Set<String> _selectedServiceCodes = {};

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
          return _buildServiceContent(state.ssrData);
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Loading special services...',
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
              Icons.star_outline,
              size: context.iconLarge,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Unable to load services',
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
              backgroundColor: Colors.green,
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
              Icons.star_outline,
              size: context.iconLarge,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'No special services available',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Additional services will appear here once available',
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

  Widget _buildServiceContent(SsrEntity ssrData) {
    final services = ssrData.specialServiceOptions;

    if (services == null || services.isEmpty) {
      return _buildEmptyState();
    }

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
                'Special Services',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.titleMedium,
                ),
              ),
              SizedBox(height: context.gapSmall),
              Text(
                'Enhance your travel experience',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.gapMedium),

        // Services list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapSmall,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final isSelected = _selectedServiceCodes.contains(service.code);

              return _buildServiceCard(
                context,
                service: service,
                isSelected: isSelected,
                onToggle: () => _handleServiceToggle(service),
              );
            },
          ),
        ),

        // Selected services summary
        if (_selectedServiceCodes.isNotEmpty) _buildSelectedSummary(services),
      ],
    );
  }

  Widget _buildServiceCard(
      BuildContext context, {
        required SpecialServiceEntity service,
        required bool isSelected,
        required VoidCallback onToggle,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Container(
            padding: EdgeInsets.all(context.gapMedium),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(context.borderRadius),
              border: Border.all(
                color: isSelected ? Colors.green.shade400 : Colors.grey.shade200,
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
                // Icon with colored background
                Container(
                  padding: EdgeInsets.all(context.gapSmall),
                  decoration: BoxDecoration(
                    color: service.iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    service.serviceIcon,
                    color: service.iconColor,
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
                        service.displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.bodyLarge,
                        ),
                      ),
                      SizedBox(height: context.gapSmall / 2),
                      Text(
                        service.displaySubtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: context.bodySmall,
                        ),
                      ),
                      // Flight route badge
                      Padding(
                        padding: EdgeInsets.only(top: context.gapSmall / 2),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.gapSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${service.origin} → ${service.destination}',
                            style: TextStyle(
                              fontSize: context.labelSmall,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price and checkbox column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      service.displayPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.bodyLarge,
                        color: service.isFree
                            ? Colors.green.shade700
                            : Colors.black87,
                      ),
                    ),
                    SizedBox(height: context.gapSmall / 2),
                    // Custom checkbox
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.green.shade600
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected ? Colors.green : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                            : null,
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

  Widget _buildSelectedSummary(List<SpecialServiceEntity> allServices) {
    final selectedServices = allServices
        .where((s) => _selectedServiceCodes.contains(s.code))
        .toList();

    final totalPrice = selectedServices.fold(0.0, (sum, s) => sum + s.price);

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.gapMedium,
        0,
        context.gapMedium,
        context.gapMedium,
      ),
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: Colors.green.shade600,
                size: 20,
              ),
              SizedBox(width: context.gapSmall),
              Text(
                '${selectedServices.length} service(s) selected',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: context.bodyMedium,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                totalPrice <= 0 ? 'Free' : 'USD ${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodyLarge,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleServiceToggle(SpecialServiceEntity service) {
    setState(() {
      if (_selectedServiceCodes.contains(service.code)) {
        _selectedServiceCodes.remove(service.code);
      } else {
        _selectedServiceCodes.add(service.code);
      }
    });

    // Only call callback if it exists and we have loaded data
    if (widget.onServicesSelected != null) {
      final state = context.read<SsrBloc>().state;

      if (state is SsrLoaded && state.ssrData.specialServiceOptions != null) {
        // Explicitly type the list to avoid List<dynamic> inference
        final List<SpecialServiceEntity> selectedServices = state.ssrData.specialServiceOptions!
            .where((s) => _selectedServiceCodes.contains(s.code))
            .toList();

        widget.onServicesSelected?.call(selectedServices);
      } else {
        // Fallback: empty typed list
        widget.onServicesSelected?.call(<SpecialServiceEntity>[]);
      }
    }

    print('Service ${service.code}: ${_selectedServiceCodes.contains(service.code) ? 'selected' : 'deselected'}');
  }
}