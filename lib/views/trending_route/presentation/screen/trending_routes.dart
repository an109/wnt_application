import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';
import '../../domain/entities/trending_routes_entity.dart';
import '../bloc/trending_routes_bloc.dart';
import '../bloc/trending_routes_event.dart';
import '../bloc/trending_routes_state.dart';
import '../widget/package_card.dart';

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

  // Navigate to FlightSearchScreen with route data
  void _navigateToFlightSearch(BuildContext context, TrendingRouteEntity route) {
    print('Navigating to FlightSearchScreen');
    print('From: ${route.from} (${route.fromCode})');
    print('To: ${route.to} (${route.toCode})');
    print('Date: ${route.date}');
    print('Price: ${route.price} ${route.currency}');

    // Parse date from API format "DD/MM/YYYY" to DateTime
    final parsedDate = DateTime.now();

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
          BookingMode: 5,
        ),
      ),
    );
  }

  // Helper: Parse date string "DD/MM/YYYY" to DateTime
  DateTime? _parseDate(String dateString) {
    try {
      if (dateString.isEmpty) return null;

      // Expected format: "18/04/2026"
      final parts = dateString.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;

      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date: $dateString, error: $e');
      return null;
    }
  }

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

  Map<String, dynamic> _mapToRouteCard(TrendingRouteEntity entity) {
    final prefs = sl<PreferencesManager>();
    final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';

    return {
      'from': entity.from,
      'to': entity.to,
      'fromCode': entity.fromCode,
      'toCode': entity.toCode,
      'date': getCurrentDate(),
      'price': _formatPrice(entity.price, entity.currency, targetCurrency: targetCurrency),
      'image': entity.imageUrl,
      'bgColor': Colors.blue.shade50,
      'color': Colors.blue,
      'type': 'Flights',
      'icon': Icons.flight,
      'time': '08:00 - 10:30',
      'duration': '2h 30m',
      'stops': 'Non-stop',
      'airline': 'Air Arabia',
      'rating': '4.5',
      'originalPrice': _formatPrice(
        (entity.price * 1.2).toInt(),
        entity.currency,
        targetCurrency: targetCurrency,
      ),
      'discount': '20% OFF',
      'busType': '',
      'train': '',
      'entity': entity,
    };
  }

  @override
  Widget build(BuildContext context) {
    print('Building TrendingPackagesView');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16), // 16px on design
            vertical: context.h(12),   // 12px on design
          ),
          child: Text(
            "Trending Routes With Best Prices",
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: context.isMobile
              ? context.h(192)  // 192px on design
              : (context.isTablet
              ? context.h(224)  // 224px on design
              : context.h(256)), // 256px on design
          child: BlocBuilder<TrendingRoutesBloc, TrendingRoutesState>(
            builder: (context, state) {
              print('BLoC State: ${state.runtimeType}');

              if (state is TrendingRoutesLoading) {
                print('Showing loading indicator');
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: context.w(3), // 3px on design
                  ),
                );
              }

              if (state is TrendingRoutesError) {
                print('Showing error state: ${state.message}');
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(32)), // 32px on design
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: context.iconLarge,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(height: context.gapMedium),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.bodySmall,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: context.gapLarge),
                        ElevatedButton.icon(
                          onPressed: _onRetry,
                          icon: Icon(Icons.refresh, size: context.iconSmall),
                          label: Text('Retry', style: TextStyle(fontSize: context.bodySmall)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(24), // 24px on design
                              vertical: context.h(12),   // 12px on design
                            ),
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
                        fontSize: context.bodySmall,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                final routeCards = state.routes.map(_mapToRouteCard).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    _onRefresh();
                    await Future.delayed(Duration(milliseconds: context.gapMedium.toInt() * 20));
                  },
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: context.w(12)), // 12px on design
                    physics: context.scrollPhysics,
                    itemCount: (routeCards.length / 2).ceil(),
                    itemBuilder: (context, index) {
                      print('Building route card at index: $index');

                      return Column(
                        children: [
                          RouteCard(
                            route: routeCards[index * 2],
                            onTap: () {
                              // Get the entity from the mapped data
                              final entity = routeCards[index * 2]['entity'] as TrendingRouteEntity?;
                              if (entity != null) {
                                _navigateToFlightSearch(context, entity);
                              }
                            },
                          ),
                          SizedBox(height: context.gapMedium),
                          if (index * 2 + 1 < routeCards.length)
                            RouteCard(
                              route: routeCards[index * 2 + 1],
                              onTap: () {
                                final entity = routeCards[index * 2 + 1]['entity'] as TrendingRouteEntity?;
                                if (entity != null) {
                                  _navigateToFlightSearch(context, entity);
                                }
                              },
                            ),
                        ],
                      );
                    },
                  ),
                );
              }

              print('Showing initial/empty state');
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('TrendingPackagesView disposed');
    super.dispose();
  }
}