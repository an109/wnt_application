import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../AKFlight_tui/domain/entity/akflight_search_entity.dart';
import '../../../AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';
import '../../domain/entities/trending_routes_entity.dart';
import '../bloc/trending_routes_bloc.dart';
import '../bloc/trending_routes_event.dart';
import '../bloc/trending_routes_state.dart';

class TrendingPackages extends StatelessWidget {
  const TrendingPackages({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TrendingRoutesBloc>()
        ..add(const LoadTrendingRoutes(domain: 'thewandernova.com')),
      child: const TrendingPackagesView(),
    );
  }
}

class TrendingPackagesView extends StatefulWidget {
  const TrendingPackagesView({super.key});

  @override
  State<TrendingPackagesView> createState() => _TrendingPackagesViewState();
}

class _TrendingPackagesViewState extends State<TrendingPackagesView> {
  @override
  void initState() {
    super.initState();
    print('TrendingPackagesView initialized');
  }

  void _onRefresh() {
    print('Pull-to-refresh triggered');
    context.read<TrendingRoutesBloc>().add(
      const RefreshTrendingRoutes(domain: 'thewandernova.com'),
    );
  }

  void _onRetry() {
    print('Retry button pressed');
    context.read<TrendingRoutesBloc>().add(
      const LoadTrendingRoutes(domain: 'thewandernova.com'),
    );
  }

  void _navigateToFlightSearch(BuildContext context, TrendingRouteEntity route) async {
    print('Navigating to FlightSearchScreen');
    print('From: ${route.from} (${route.fromCode})');
    print('To: ${route.to} (${route.toCode})');
    print('Date: ${route.date}');
    print('Price: ${route.price} ${route.currency}');

    final parsedDate = DateTime.now();

    final request = FlightSearchRequestEntity(
      adults: 1,
      children: 0,
      infants: 0,
      cabin: 'E',
      fareType: 'ON',
      trips: [
        TripEntity(
          from: route.fromCode,
          to: route.toCode,
          onwardDate: _formatDateForSearch(parsedDate),
        ),
      ],
    );

    final result = await sl<AkFlightSearchUseCase>().call(request);

    if (!context.mounted) return;

    if (result is DataSuccess<AkFlightSearchEntity> && result.data != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlightSearchScreen(
            from: route.from,
            to: route.to,
            fromCode: route.fromCode,
            toCode: route.toCode,
            fromAirport: route.from,
            toAirport: route.to,
            date: parsedDate,
            travellers: 1,
            adults: 1,
            children: 0,
            infants: 0,
            travelClass: 'Economy',
            isRoundTrip: false,
            returnDate: null,
            tui: result.data!.tui,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error?.message ?? 'Failed to search flights'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateForSearch(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatPrice(num price, String currency, {String? targetCurrency}) {
    double finalPrice = price.toDouble();
    if (targetCurrency != null) {
      finalPrice = CurrencyConverter.convert(
        amount: finalPrice,
        fromCurrency: currency,
        toCurrency: targetCurrency,
      );
      currency = targetCurrency;
    }

    final priceStr = finalPrice.toStringAsFixed(0);
    final buffer = StringBuffer();
    final len = priceStr.length;

    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(priceStr[i]);
    }

    final symbols = {'INR': '₹', 'USD': '\$', 'AED': 'د.إ', 'EUR': '€', 'GBP': '£'};
    final symbol = symbols[currency.toUpperCase()] ?? '$currency ';
    return '$symbol$buffer';
  }

  String getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    print('Building TrendingPackagesView');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel Routes',
                    style: TextStyle(
                      fontSize: context.fs(24),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Discover routes that take you further',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  print('View all tapped');
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w400,
                        color: AppColors.AppBlue,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      Icons.arrow_forward,
                      size: context.iconSmall,
                      color: AppColors.AppBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.h(20)),

        // Routes Carousel
        SizedBox(
          height: context.h(230),
          child: ValueListenableBuilder<String>(
            valueListenable: CurrencyConverter.currencyListenable,
            builder: (context, _, __) => BlocBuilder<TrendingRoutesBloc, TrendingRoutesState>(
              builder: (context, state) {
                print('BLoC State: ${state.runtimeType}');

                if (state is TrendingRoutesLoading) {
                  print('Showing loading indicator');
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xff005B7F),
                      strokeWidth: 2,
                    ),
                  );
                }

                if (state is TrendingRoutesError) {
                  print('Showing error state: ${state.message}');
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.wp(8)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: context.w(48),
                            color: Colors.red.shade400,
                          ),
                          SizedBox(height: context.h(12)),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: context.fs(14),
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: context.h(16)),
                          ElevatedButton(
                            onPressed: _onRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff005B7F),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(24),
                                vertical: context.h(12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.r(20)),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(fontSize: context.fs(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is TrendingRoutesLoaded) {
                  print('Showing ${state.routes.length} routes');

                  if (state.routes.isEmpty) {
                    return Center(
                      child: Text(
                        'No trending routes found',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _onRefresh();
                      await Future.delayed(Duration(milliseconds: 300));
                    },
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: state.routes.length,
                      separatorBuilder: (context, index) => SizedBox(width: context.w(16)),
                      itemBuilder: (context, index) {
                        final route = state.routes[index];
                        print('Building route card at index: $index');
                        return _buildRouteCard(context, route);
                      },
                    ),
                  );
                }

                print('Showing initial/empty state');
                return const SizedBox.shrink();
              },
            ),
          ),
        ),

        SizedBox(height: context.h(32)),
      ],
    );
  }

  Widget _buildRouteCard(BuildContext context, TrendingRouteEntity route) {
    final prefs = sl<PreferencesManager>();
    final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';
    final formattedPrice = _formatPrice(route.price, route.currency, targetCurrency: targetCurrency);
    final currentDate = getCurrentDate();

    return GestureDetector(
      onTap: () {
        _navigateToFlightSearch(context, route);
      },
      child: Container(
        width: context.w(180),
        height: context.h(230),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Full Image
            ClipRRect(
              borderRadius: BorderRadius.circular(context.r(16)),
              child: SizedBox(
                height: context.h(230),
                width: context.w(180),
                child: route.imageUrl.isNotEmpty
                    ? Image.network(
                  route.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.flight,
                        size: context.w(48),
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.flight,
                    size: context.w(48),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Heart Icon
            Positioned(
              top: context.h(12),
              right: context.w(12),
              child: Container(
                width: context.w(22),
                height: context.h(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/NewIcons/heartHD.png',
                  width: context.w(18),
                  height: context.h(18),
                ),
              ),
            ),
            // Content Overlay at Bottom
            Positioned(
              left: context.w(16),
              right: context.w(16),
              bottom: context.h(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Route: Mumbai → Bangalore
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.from,
                          style: TextStyle(
                            fontSize: context.fs(16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.flight_takeoff,
                        size: context.w(16),
                        color: const Color(0xffFF6B00),
                      ),
                      SizedBox(width: context.w(4)),
                      Expanded(
                        child: Text(
                          route.to,
                          style: TextStyle(
                            fontSize: context.fs(16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(4)),
                  // Airport Codes: BOM → BLR
                  Row(
                    children: [
                      Text(
                        route.fromCode,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xffFF6B00),
                        ),
                      ),
                      SizedBox(width: context.w(4)),
                      Icon(
                        Icons.chevron_right,
                        size: context.w(16),
                        color: const Color(0xffFF6B00),
                      ),
                      SizedBox(width: context.w(4)),
                      Text(
                        route.toCode,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xffFF6B00),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(12)),
                  // Date and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentDate,
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: context.fs(20),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('TrendingPackagesView disposed');
    super.dispose();
  }
}
