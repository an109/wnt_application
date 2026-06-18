import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../UI_helper/airport_mapper.dart';
import '../../../flight_search/presentation/screen/booking_screen.dart';
import '../../domain/entities/fare_rule_entity.dart';
import '../bloc/fare_rule_bloc.dart';
import '../bloc/fare_rule_event.dart';
import '../bloc/fare_rule_state.dart';

enum FareRuleTab { cancellation, segment, detail }

class FareRulePopup extends StatefulWidget {
  final String? traceId;
  final String? resultIndex;
  final List<FlightRouteSegment>? routes;
  final String? price;

  const FareRulePopup({
    super.key,
    this.traceId,
    this.resultIndex,
    this.routes,
    this.price,
  });

  /// Show popup using showDialog (like FlightDetailsPopup)
  static void show({
    required BuildContext context,
    String? traceId,
    String? resultIndex,
    List<FlightRouteSegment>? routes,
    String? price,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(3),
        ),
        child: FareRulePopup(
          traceId: traceId,
          resultIndex: resultIndex,
          routes: routes,
          price: price,
        ),
      ),
    );
  }

  @override
  State<FareRulePopup> createState() => _FareRulePopupState();
}

class _FareRulePopupState extends State<FareRulePopup>
    with SingleTickerProviderStateMixin {

  late final FareRuleBloc _fareRuleBloc;
  late final TabController _tabController;
  List<FareRuleEntity> _fareRules = [];
  late final StreamSubscription<FareRuleState> _blocSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fareRuleBloc = context.read<FareRuleBloc>();

    // Store the subscription
    _blocSubscription = _fareRuleBloc.stream.listen(_onBlocState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFareRules());
  }

  @override
  void dispose() {
    _blocSubscription.cancel(); // Cancel the subscription
    _tabController.dispose();
    super.dispose();
  }

  void _onBlocState(FareRuleState state) {
    // Check if widget is still mounted before calling setState
    if (!mounted) return;

    if (state is FareRuleLoading) {
      setState(() => _isLoading = true);
    } else if (state is FareRuleLoaded) {
      setState(() {
        _fareRules = state.fareRuleResponse.fareRules ?? [];
        _isLoading = false;
      });
      print('FareRulePopup: Loaded ${_fareRules.length} fare rules');
    } else if (state is FareRuleError) {
      setState(() => _isLoading = false);
      print('FareRulePopup: Error - ${state.message}');
    }
  }

  void _fetchFareRules() {
    print('FareRulePopup: Fetching fare rules');

    final traceId = widget.traceId ??
        (widget.routes?.isNotEmpty == true ? widget.routes!.first.traceId : null);
    final resultIndex = widget.resultIndex ??
        (widget.routes?.isNotEmpty == true ? widget.routes!.first.resultIndex : null);

    if (traceId == null || traceId.isEmpty) {
      print('FareRulePopup: ERROR - traceId is required');
      setState(() => _isLoading = false);
      return;
    }
    if (resultIndex == null || resultIndex.isEmpty) {
      print('FareRulePopup: ERROR - resultIndex is required');
      setState(() => _isLoading = false);
      return;
    }

    final request = FareRuleRequestEntity(
      endUserIp: '122.161.72.69',
      traceId: traceId,
      tokenId: null,
      resultIndex: resultIndex,
    );

    _fareRuleBloc.add(FetchFareRules(request: request));
  }

  /// Convert HTML-like fare rule text to clean bullet points
  List<String> _parseBulletPoints(String? text) {
    if (text == null || text.isEmpty) return [];

    // Remove HTML tags and split by bullet indicators
    String cleaned = text
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</?ul>'), '')
        .replaceAll(RegExp(r'</?li>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    // If the text contains bullets from API, split them
    if (cleaned.contains('\n')) {
      return cleaned
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length > 5)
          .toList();
    }

    // Otherwise return as single item if text exists
    return cleaned.isNotEmpty ? [cleaned] : [];
  }

  /// Build tab content for the given tab. Driven by the page index so the
  /// body always matches the highlighted tab (both on tap and on swipe).
  Widget _buildTabContent(BuildContext context, FareRuleTab tab) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.gapLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: const Color(0xFFE71D36)),
              SizedBox(height: context.gapMedium),
              Text(
                "Loading fare rules...",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: context.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_fareRules.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.gapLarge),
          child: Text(
            "No fare rules available for this selection.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: context.bodySmall,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    switch (tab) {
      case FareRuleTab.cancellation:
        return _buildCancellationTab(context);
      case FareRuleTab.segment:
        return _buildSegmentTab(context);
      case FareRuleTab.detail:
        return _buildDetailTab(context);
    }
  }

  /// Cancellation Process Tab - NOW USING ACTUAL API DATA
  Widget _buildCancellationTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.w(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cancellation & Reissue Policy",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.titleSmall,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: context.gapMedium),
          ..._fareRules.map((rule) => _buildCancellationCard(context, rule)),
        ],
      ),
    );
  }

  Widget _buildCancellationCard(BuildContext context, FareRuleEntity rule) {
    // Parse the actual fare rule detail from API
    final cancellationRules = _parseBulletPoints(rule.fareRuleDetail);

    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius - 4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Route header with CITY NAMES
          Row(
            children: [
              Text(
                "${AirportMapper.getCity(rule.origin)} → ${AirportMapper.getCity(rule.destination)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodySmall,
                  color: Colors.indigo.shade800,
                ),
              ),
              if (rule.airline != null) ...[
                SizedBox(width: context.gapSmall),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapSmall / 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AirlineMapper.getName(rule.airline),
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: context.gapSmall),

          /// ACTUAL cancellation rules from API - NO HARDCODED TEXT
          if (cancellationRules.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cancellationRules.map((point) => Padding(
                padding: EdgeInsets.only(bottom: context.gapSmall / 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• ",
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            )
          else
            Text(
              "No cancellation rules available",
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  /// Fare Segment Tab - Table with CITY NAMES, Airline Names, and Amount
  Widget _buildSegmentTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.w(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fare Segments",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.titleSmall,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: context.gapMedium),

          /// Table header
          _buildTableHeader(context),

          /// Table rows
          ..._fareRules.map((rule) => _buildSegmentRow(context, rule)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Route",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Airline",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "Fare Basis",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "Restriction",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(BuildContext context, FareRuleEntity rule) {
    // The FareRule API returns no per-segment fare amount; show the real
    // per-segment fare basis code instead of repeating the total price.
    final fareBasis = (rule.fareBasisCode?.trim().isNotEmpty == true)
        ? rule.fareBasisCode!.trim()
        : '—';

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          /// Route column - CITY NAMES
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AirportMapper.getCity(rule.origin)} → ${AirportMapper.getCity(rule.destination)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (rule.departureTime != null && rule.departureTime != '0001-01-01T00:00:00')
                  Text(
                    DateFormat('dd MMM yyyy').format(
                      DateTime.tryParse(rule.departureTime!) ?? DateTime.now(),
                    ),
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),

          /// Airline column - AIRLINE NAME
          Expanded(
            child: Text(
              AirlineMapper.getName(rule.airline),
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// Fare Basis column - REAL PER-SEGMENT DATA FROM API
          Expanded(
            child: Text(
              fareBasis,
              style: TextStyle(
                fontSize: context.bodySmall,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE71D36),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// Restriction column - FROM API
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.gapSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: rule.fareRestriction == 'Y'
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rule.fareRestriction == 'Y' ? 'Yes' : 'No',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: rule.fareRestriction == 'Y'
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fare Detail Tab - Clean bullet points without HTML tags
  Widget _buildDetailTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.w(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fare Conditions & Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.titleSmall,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: context.gapMedium),
          ..._fareRules.map((rule) => _buildDetailCard(context, rule)),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, FareRuleEntity rule) {
    final bulletPoints = _parseBulletPoints(rule.fareRuleDetail);

    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius - 4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Route header with CITY NAMES
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${AirportMapper.getCity(rule.origin)} → ${AirportMapper.getCity(rule.destination)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.bodySmall,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ),
              if (rule.airline != null) ...[
                SizedBox(width: context.gapSmall),
                Text(
                  AirlineMapper.getName(rule.airline),
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: context.gapMedium),

          /// Bullet point fare rule details from API
          if (bulletPoints.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bulletPoints.map((point) => Padding(
                padding: EdgeInsets.only(bottom: context.gapSmall / 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• ",
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            )
          else if (rule.fareRuleDetail?.isNotEmpty == true)
            Text(
              rule.fareRuleDetail!.trim(),
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            )
          else
            Text(
              "No fare details available",
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isDesktop ? 700 : context.isTablet ? 600 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Header with close button
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fare Rules",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.titleMedium,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade100,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade200, height: 1),

          /// Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFE71D36),
            labelColor: const Color(0xFFE71D36),
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: context.labelMedium,
            ),
            unselectedLabelStyle: TextStyle(fontSize: context.labelMedium),
            isScrollable: true,
            // Material 3 defaults scrollable TabBars to TabAlignment.startOffset,
            // which adds a ~52px leading gap. Align to start to remove it.
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: "Cancellation Process"),
              Tab(text: "Fare Segment"),
              Tab(text: "Fare Detail"),
            ],
          ),

          /// Tab Content (fixed height for scrollable content)
          SizedBox(
            height: context.hp(40),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(context, FareRuleTab.cancellation),
                _buildTabContent(context, FareRuleTab.segment),
                _buildTabContent(context, FareRuleTab.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}