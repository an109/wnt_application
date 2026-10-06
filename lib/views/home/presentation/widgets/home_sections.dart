import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/fast_network_image_cache_manager.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../Holidays/presentation/screen/holidays_screen.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../NewSection/foryourStay.dart' show hotelData;
import '../../../flight_popularDestination/domain/entities/Popular_destination_entity.dart';
import '../../../flight_popularDestination/presentation/bloc/destination_bloc.dart';
import '../../../flight_popularDestination/presentation/bloc/destination_event.dart';
import '../../../flight_popularDestination/presentation/bloc/destination_state.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart'
    show DestinationDetailSheet;
import '../../../travel_stories/domain/entities/travel_stories_entity.dart';
import '../../../travel_stories/presentation/bloc/travel_stories_bloc.dart';
import '../../../travel_stories/presentation/bloc/travel_stories_event.dart';
import '../../../travel_stories/presentation/bloc/travel_stories_state.dart';
import '../../../travel_stories/presentation/screen/all_travel_stories.dart';
import '../../../travel_stories/presentation/screen/travel_stories_detail_screen.dart';
import '../../../trending_route/domain/entities/trending_routes_entity.dart';
import '../../../trending_route/presentation/bloc/trending_routes_bloc.dart';
import '../../../trending_route/presentation/bloc/trending_routes_event.dart';
import '../../../trending_route/presentation/bloc/trending_routes_state.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart'
    show
        formatTrendingRoutePrice,
        searchTrendingRouteFlights,
        trendingRouteDisplayDate;

// Home-screen sections from the "MAIN HOME" Figma frame (412px wide, hence
// `context.fx`). They reuse the same blocs/APIs as the shared section
// widgets, which other screens (Flight, Hotel, Visa…) still use unchanged.

const Color _textGrey = Color(0xFF757575);
const String _icons = 'assets/home';

/// Shared horizontal gutter of the home frame.
double homeGutter(BuildContext context) => context.fx(16);

// ===========================================================================
// Shared building blocks
// ===========================================================================

/// "View all →" link. Blue/regular in section headers, orange/bold on cards.
class HomeViewAll extends StatelessWidget {
  final VoidCallback? onTap;
  final bool onCard;

  const HomeViewAll({super.key, this.onTap, this.onCard = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View all',
            style: TextStyle(
              fontSize: context.ffs(12),
              fontWeight: onCard ? FontWeight.w700 : FontWeight.w400,
              color: onCard ? AppColors.OrangeColor : AppColors.AppBlue,
            ),
          ),
          SizedBox(width: context.fx(4)),
          // The Figma icon is an up-arrow turned 90° to point right.
          RotatedBox(
            quarterTurns: 1,
            child: SvgPicture.asset(
              onCard ? '$_icons/arrow_orange.svg' : '$_icons/arrow_blue.svg',
              width: context.fx(12),
              height: context.fx(12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title + subtitle, with an optional "View all" on the right.
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onViewAll;
  final bool showViewAll;

  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onViewAll,
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.ffs(24),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: context.fx(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (showViewAll) HomeViewAll(onTap: onViewAll),
        ],
      ),
    );
  }
}

/// White 18px wishlist badge with the outlined heart.
class HomeHeartBadge extends StatelessWidget {
  const HomeHeartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.fx(18),
      height: context.fx(18),
      padding: EdgeInsets.all(context.fx(3)),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset('$_icons/heart_outline.svg'),
    );
  }
}

/// Network image used by every home card, disk-cached like the rest of
/// the app, with a flat placeholder while it loads or if it fails.
class _CardImage extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const _CardImage({required this.url, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: context.fx(32), color: Colors.grey.shade500),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

/// Black-to-clear scrim used on the 144×192 image cards.
const LinearGradient _cardScrim = LinearGradient(
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
  colors: [Color(0xE6000000), Color(0x00000000), Color(0x00000000)],
  stops: [0.0, 0.71154, 1.0],
);

/// Horizontal card rail that starts at the gutter and bleeds off the right.
class _CardRail extends StatelessWidget {
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _CardRail({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(width: context.fx(12)),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _RailPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _RailPlaceholder({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return _CardRail(
      height: context.fx(height),
      itemCount: 3,
      itemBuilder: (context, _) => Container(
        width: context.fx(width),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(context.fx(radius)),
        ),
      ),
    );
  }
}

class _RailMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _RailMessage({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: context.ffs(12), color: _textGrey),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ===========================================================================
// Popular Destination
// ===========================================================================

class HomePopularDestinations extends StatefulWidget {
  const HomePopularDestinations({super.key});

  @override
  State<HomePopularDestinations> createState() =>
      _HomePopularDestinationsState();
}

class _HomePopularDestinationsState extends State<HomePopularDestinations> {
  static const _filters = ['All', 'Domestic', 'International'];
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PopularDestinationBloc>().add(
          const FetchPopularDestinations(),
        );
      }
    });
  }

  List<DestinationEntity> _filtered(List<DestinationEntity> all) {
    if (_selectedFilter == 0) return all;
    final type = _filters[_selectedFilter].toLowerCase();
    return all.where((d) => d.type.toLowerCase() == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const HomeSectionHeader(
          title: 'Popular Destination',
          subtitle: 'Travel to the Most Loved Destinations',
          showViewAll: false,
        ),
        SizedBox(height: context.fx(24)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
          child: Row(
            children: [
              for (var i = 0; i < _filters.length; i++) ...[
                if (i > 0) SizedBox(width: context.fx(12)),
                _FilterChip(
                  label: _filters[i],
                  selected: _selectedFilter == i,
                  onTap: () => setState(() => _selectedFilter = i),
                ),
              ],
              const Spacer(),
              HomeViewAll(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HolidaysScreen()),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.fx(12)),
        BlocBuilder<PopularDestinationBloc, PopularDestinationState>(
          builder: (context, state) {
            if (state is PopularDestinationLoading) {
              return const _RailPlaceholder(width: 144, height: 192, radius: 12);
            }
            if (state is PopularDestinationError) {
              return _RailMessage(
                message: state.message,
                onRetry: () => context.read<PopularDestinationBloc>().add(
                  const FetchPopularDestinations(),
                ),
              );
            }
            if (state is PopularDestinationLoaded) {
              final destinations = _filtered(state.destinations);
              if (destinations.isEmpty) {
                return const _RailMessage(message: 'No destinations found');
              }
              return ValueListenableBuilder<String>(
                valueListenable: CurrencyConverter.currencyListenable,
                builder: (context, currency, _) => _CardRail(
                  height: context.fx(192),
                  itemCount: destinations.length,
                  itemBuilder: (context, i) =>
                      _DestinationCard(destination: destinations[i], currency: currency),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: context.fx(8),
          vertical: context.fx(4),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.AppBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(context.fx(6)),
          border: selected
              ? null
              : Border.all(color: _textGrey, width: 0.5),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x3D000000),
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.ffs(12),
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? Colors.white : _textGrey,
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationEntity destination;
  final String currency;

  const _DestinationCard({required this.destination, required this.currency});

  /// Same INR → preferred-currency conversion the shared section uses.
  String get _price {
    final match = RegExp(r'([\d,]+)').firstMatch(destination.price);
    final amount = double.tryParse(match?.group(1)?.replaceAll(',', '') ?? '');
    if (amount == null) return destination.price;
    final converted = CurrencyConverter.convert(
      amount: amount,
      fromCurrency: 'INR',
      toCurrency: currency,
    );
    return CurrencyConverter.format(converted, currency);
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DestinationDetailSheet(destination: destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.fx(12)),
        child: SizedBox(
          width: context.fx(144),
          height: context.fx(192),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CardImage(url: destination.imageUrl, fallbackIcon: Icons.location_city),
              const DecoratedBox(decoration: BoxDecoration(gradient: _cardScrim)),
              Positioned(
                top: context.fx(8),
                right: context.fx(7),
                child: const HomeHeartBadge(),
              ),
              Positioned(
                left: context.fx(8),
                bottom: context.fx(8),
                width: context.fx(117),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (destination.tagline.isNotEmpty) ...[
                      Text(
                        destination.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(6),
                          fontWeight: FontWeight.w700,
                          color: white,
                        ),
                      ),
                      SizedBox(height: context.fx(2)),
                    ],
                    Text(
                      destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w700,
                        color: white,
                      ),
                    ),
                    if (destination.description.isNotEmpty) ...[
                      SizedBox(height: context.fx(2)),
                      Text(
                        destination.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(6),
                          fontWeight: FontWeight.w500,
                          color: white,
                        ),
                      ),
                    ],
                    SizedBox(height: context.fx(8)),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _price,
                            style: TextStyle(fontSize: context.ffs(12)),
                          ),
                          TextSpan(
                            text: '/ Person',
                            style: TextStyle(fontSize: context.ffs(8)),
                          ),
                        ],
                      ),
                      style: TextStyle(fontWeight: FontWeight.w700, color: white),
                    ),
                    SizedBox(height: context.fx(8)),
                    HomeViewAll(onCard: true, onTap: () => _openDetail(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Travel Routes
// ===========================================================================

class HomeTravelRoutes extends StatefulWidget {
  const HomeTravelRoutes({super.key});

  @override
  State<HomeTravelRoutes> createState() => _HomeTravelRoutesState();
}

class _HomeTravelRoutesState extends State<HomeTravelRoutes> {
  static const _load = LoadTrendingRoutes(domain: 'thewandernova.com');

  @override
  void initState() {
    super.initState();
    // Uses the app-wide bloc (main.dart) so the home pull-to-refresh can
    // reload it too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TrendingRoutesBloc>().add(_load);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // There is no "all routes" screen yet; the link is shown to match
        // the design, same as on the shared section.
        const HomeSectionHeader(
          title: 'Travel Routes',
          subtitle: 'Discover routes that take you further',
        ),
        SizedBox(height: context.fx(24)),
        BlocBuilder<TrendingRoutesBloc, TrendingRoutesState>(
          builder: (context, state) {
            if (state is TrendingRoutesLoading) {
              return const _RailPlaceholder(width: 144, height: 192, radius: 12);
            }
            if (state is TrendingRoutesError) {
              return _RailMessage(
                message: state.message,
                onRetry: () => context.read<TrendingRoutesBloc>().add(_load),
              );
            }
            if (state is TrendingRoutesLoaded) {
              if (state.routes.isEmpty) {
                return const _RailMessage(message: 'No trending routes found');
              }
              return ValueListenableBuilder<String>(
                valueListenable: CurrencyConverter.currencyListenable,
                builder: (context, currency, _) => _CardRail(
                  height: context.fx(192),
                  itemCount: state.routes.length,
                  itemBuilder: (context, i) =>
                      _RouteCard(route: state.routes[i], currency: currency),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final TrendingRouteEntity route;
  final String currency;

  const _RouteCard({required this.route, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cityStyle = TextStyle(
      fontSize: context.ffs(11),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      height: 16 / 11,
      color: Colors.white,
    );
    final codeStyle = TextStyle(
      fontSize: context.ffs(12),
      fontWeight: FontWeight.w600,
      color: AppColors.OrangeColor,
    );

    return GestureDetector(
      onTap: () => searchTrendingRouteFlights(context, route),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.fx(12)),
        child: SizedBox(
          width: context.fx(144),
          height: context.fx(192),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CardImage(url: route.imageUrl, fallbackIcon: Icons.flight),
              const DecoratedBox(decoration: BoxDecoration(gradient: _cardScrim)),
              Positioned(
                top: context.fx(8),
                right: context.fx(7),
                child: const HomeHeartBadge(),
              ),
              Positioned(
                left: context.fx(8),
                right: context.fx(13),
                bottom: context.fx(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            route.from,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cityStyle,
                          ),
                        ),
                        SizedBox(width: context.fx(4)),
                        SvgPicture.asset(
                          '$_icons/route_plane.svg',
                          width: context.fx(12),
                          height: context.fx(11),
                        ),
                        SizedBox(width: context.fx(4)),
                        Flexible(
                          child: Text(
                            route.to,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cityStyle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.fx(4)),
                    Row(
                      children: [
                        Text(route.fromCode, style: codeStyle),
                        SizedBox(width: context.fx(8)),
                        SvgPicture.asset(
                          '$_icons/route_chevron.svg',
                          width: context.fx(4.317),
                          height: context.fx(7),
                        ),
                        SizedBox(width: context.fx(8)),
                        Text(route.toCode, style: codeStyle),
                      ],
                    ),
                    SizedBox(height: context.fx(8)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trendingRouteDisplayDate(),
                          style: TextStyle(
                            fontSize: context.ffs(6),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          formatTrendingRoutePrice(
                            route.price,
                            route.currency,
                            targetCurrency: currency,
                          ),
                          style: TextStyle(
                            fontSize: context.ffs(12),
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
      ),
    );
  }
}

// ===========================================================================
// For Your Stay
// ===========================================================================

/// Hotel rail. Still backed by the static `hotelData` list from
/// `foryourStay.dart` — there is no hotel-suggestions API wired up yet.
class HomeStaySection extends StatelessWidget {
  const HomeStaySection({super.key});

  void _openHotels(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSectionHeader(
          title: 'For Your Stay In Delhi',
          subtitle: 'Wed, 19 Aug 26 - Thus, 20 Aug 26',
          onViewAll: () => _openHotels(context),
        ),
        SizedBox(height: context.fx(24)),
        _CardRail(
          // The card's background shape runs ~2px past its 192px frame.
          height: context.fx(195),
          itemCount: hotelData.length,
          itemBuilder: (context, i) =>
              _HotelCard(hotel: hotelData[i], onTap: () => _openHotels(context)),
        ),
      ],
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onTap;

  const _HotelCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = (hotel['rating'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: context.fx(144),
        height: context.fx(195),
        child: Stack(
          children: [
            // Grey card with the bottom-right cut-out the Book Now pill sits in.
            Positioned(
              left: 0,
              top: 0,
              width: context.fx(144),
              height: context.fx(194.138),
              child: SvgPicture.asset('$_icons/hotel_card_bg.svg', fit: BoxFit.fill),
            ),
            Positioned(
              left: context.fx(6),
              top: context.fx(6),
              width: context.fx(132),
              height: context.fx(86),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.fx(8)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CardImage(url: hotel['image'] as String?, fallbackIcon: Icons.hotel),
                    Positioned(
                      top: context.fx(4),
                      right: context.fx(4),
                      child: const HomeHeartBadge(),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: context.fx(6),
              top: context.fx(96),
              width: context.fx(132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.ffs(11),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      height: 17.5 / 11,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: context.fx(2)),
                  Row(
                    children: [
                      SvgPicture.asset(
                        '$_icons/location.svg',
                        width: context.fx(12),
                        height: context.fx(12),
                      ),
                      SizedBox(width: context.fx(4)),
                      Expanded(
                        child: Text(
                          hotel['location']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.ffs(8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                            color: _textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.fx(12)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '₹ ${hotel['price']} ',
                          style: TextStyle(
                            fontSize: context.ffs(12),
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: '/Night',
                          style: TextStyle(
                            fontSize: context.ffs(8),
                            color: _textGrey,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: context.fx(16)),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        if (i > 0) SizedBox(width: context.fx(2)),
                        SvgPicture.asset(
                          i < rating
                              ? '$_icons/star_filled.svg'
                              : '$_icons/star_empty.svg',
                          width: context.fx(10),
                          height: context.fx(10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: context.fx(89),
              top: context.fx(162),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.fx(6),
                    vertical: context.fx(4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.OrangeColor,
                    borderRadius: BorderRadius.circular(context.fx(16)),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: context.ffs(8),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Travel Stories
// ===========================================================================

class HomeTravelStories extends StatefulWidget {
  const HomeTravelStories({super.key});

  @override
  State<HomeTravelStories> createState() => _HomeTravelStoriesState();
}

class _HomeTravelStoriesState extends State<HomeTravelStories> {
  static const _event = GetTravelStoriesEvent(
    status: 'published',
    domain: 'thewandernova.com',
    limit: 8,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TravelStoriesBloc>().add(_event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSectionHeader(
          title: 'Travel Stories',
          subtitle: 'Stories from the road, memories for a lifetime',
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllTravelStoriesScreen()),
          ),
        ),
        SizedBox(height: context.fx(24)),
        BlocBuilder<TravelStoriesBloc, TravelStoriesState>(
          builder: (context, state) {
            if (state is TravelStoriesLoading) {
              return const _RailPlaceholder(width: 220, height: 114, radius: 8);
            }
            if (state is TravelStoriesError) {
              return _RailMessage(
                message: 'Failed to load stories',
                onRetry: () => context.read<TravelStoriesBloc>().add(_event),
              );
            }
            if (state is TravelStoriesLoaded) {
              if (state.stories.isEmpty) {
                return const _RailMessage(message: 'No travel stories available');
              }
              return _CardRail(
                height: context.fx(114),
                itemCount: state.stories.length,
                itemBuilder: (context, i) => _StoryCard(story: state.stories[i]),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final TravelStoryEntity story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    // Design highlights the title's last word in orange
    // ("Best Honeymoon / Destinations").
    final words = story.title.trim().split(RegExp(r'\s+'));
    final lead = words.length > 1 ? '${words.sublist(0, words.length - 1).join(' ')}\n' : '';
    final accent = words.isEmpty ? '' : words.last;
    final category = story.category?.trim() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TravelStoryDetailScreen(slug: story.slug),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.fx(8)),
        child: SizedBox(
          width: context.fx(220),
          height: context.fx(114),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CardImage(
                url: story.featuredImageUrl ?? story.headerImageUrl,
                fallbackIcon: Icons.image,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE6000000), Color(0x66000000), Color(0x1A000000)],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.fx(8)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(context.fx(12)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.fx(9),
                            vertical: context.fx(5),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(context.fx(12)),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: lead),
                                    TextSpan(
                                      text: accent,
                                      style: const TextStyle(color: AppColors.OrangeColor),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.ffs(12),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (category.isNotEmpty) ...[
                                SizedBox(height: context.fx(4)),
                                Text(
                                  category.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.ffs(6),
                                    letterSpacing: 2,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.fx(4)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            story.excerpt ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.ffs(8),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: context.fx(6)),
                        Container(
                          width: context.fx(18),
                          height: context.fx(18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.84),
                            shape: BoxShape.circle,
                          ),
                          // Figma: up-arrow flipped vertically, then -90°.
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationZ(-math.pi / 2)
                              ..multiply(Matrix4.diagonal3Values(1, -1, 1)),
                            child: SvgPicture.asset(
                              '$_icons/story_arrow.svg',
                              width: context.fx(12),
                              height: context.fx(12),
                            ),
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
      ),
    );
  }
}

// ===========================================================================
// Footer — "Where can you next adventure take you?"
// ===========================================================================

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  /// Height of the plane that pokes above the heart-shaped backdrop.
  static const double _planeOverhang = 48;

  /// Part of the 417px backdrop that's inside the frame (it runs 143px
  /// past the bottom edge, under the nav bar).
  static const double _visible = 417 - 143;

  @override
  Widget build(BuildContext context) {
    final boxW = context.fx(633);
    final boxH = context.fx(417);
    final boxLeft = context.screenWidth / 2 + context.fx(5.5) - boxW / 2;

    return SizedBox(
      width: double.infinity,
      height: context.fx(_planeOverhang + _visible),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: boxLeft,
            top: context.fx(_planeOverhang),
            width: boxW,
            height: boxH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SvgPicture.asset('$_icons/footer_bg.svg', fit: BoxFit.fill),
                ),
                Positioned(
                  left: (boxW - context.fx(481)) / 2,
                  top: context.fx(83),
                  child: Opacity(
                    opacity: 0.24,
                    child: HomeCroppedImage(
                      asset: '$_icons/footer_clouds.png',
                      width: 481,
                      height: 251,
                      imageWidthFactor: 1.0011,
                      imageHeightFactor: 1.2798,
                      leftFactor: -0.0005,
                      topFactor: -0.1975,
                    ),
                  ),
                ),
                Positioned(
                  left: context.fx(283),
                  top: -context.fx(48),
                  width: context.fx(326.614),
                  height: context.fx(257.416),
                  child: Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(165.64 * math.pi / 180)
                        ..multiply(Matrix4.diagonal3Values(1, -1, 1)),
                      child: Opacity(
                        opacity: 0.54,
                        child: Image.asset(
                          '$_icons/plane.png',
                          width: context.fx(288),
                          height: context.fx(192),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                // The design wraps "take you?" onto its own line; break it
                // explicitly so wider glyph metrics can't wrap line one.
                Positioned(
                  left: context.fx(121),
                  top: context.fx(128),
                  child: FractionalTranslation(
                    translation: const Offset(0, -0.5),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Where can you next adventure',
                            style: TextStyle(
                              fontSize: context.ffs(14),
                              fontWeight: FontWeight.w600,
                              color: _textGrey,
                            ),
                          ),
                          TextSpan(
                            text: '\n',
                            style: TextStyle(fontSize: context.ffs(16)),
                          ),
                          TextSpan(
                            text: 'take you?',
                            style: GoogleFonts.manuale(
                              fontSize: context.ffs(20),
                              fontWeight: FontWeight.w700,
                              color: AppColors.OrangeColor,
                            ),
                          ),
                        ],
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
}

/// Shows a crop of a larger image, reproducing a Figma image fill that is
/// offset/scaled inside its frame. All factors are fractions of the frame
/// (e.g. `leftFactor: -0.1469` = `left: -14.69%`); sizes are 412-frame px.
class HomeCroppedImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final double imageWidthFactor;
  final double imageHeightFactor;
  final double leftFactor;
  final double topFactor;

  const HomeCroppedImage({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    required this.imageWidthFactor,
    required this.imageHeightFactor,
    required this.leftFactor,
    required this.topFactor,
  });

  @override
  Widget build(BuildContext context) {
    final w = context.fx(width);
    final h = context.fx(height);
    final imageW = w * imageWidthFactor;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      width: w,
      height: h,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: w * leftFactor,
              top: h * topFactor,
              width: imageW,
              height: h * imageHeightFactor,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                // Several of these are large sprite sheets; decode only as
                // many pixels as are drawn.
                cacheWidth: (imageW * dpr).ceil(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
