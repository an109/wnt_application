import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/error/data_state.dart';
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelDetailContent/domain/usecase/AKHotelDetailContent_usecase.dart';
import '../../../AKHotelRooms/domain/entity/AKHotelRooms_entity.dart';
import '../../../AKHotelRooms/domain/usecase/AKHotelRooms_usecase.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../../../Hotel_Details/presentation/screens/widgets/amenities.dart';
import '../../../Hotel_Details/presentation/screens/widgets/photo_gallery_section.dart';
import 'ak_hotel_price_confirm_screen.dart';

/// Hotel detail page: static Content (images, address, policies, geoCode)
/// and Rooms (bookable options) are independent calls, fetched in parallel —
/// same "fire both, don't wait on one for the other" contract as the
/// results screen's Content+Rate. Reuses [PhotoGallerySection] and
/// [AmenitiesSection] from Hotel_Details (both are generic, list-in /
/// widget-out — no TBO coupling) so Photos and Map look like the old
/// tbo-hotel detail page; Akbar's hotel Content does carry multiple images
/// (images[].url) and a geoCode (lat/long), same as TBO did.
class AkHotelDetailScreen extends StatefulWidget {
  final String searchId;
  final String searchTracingKey;
  final String hotelId;
  final String hotelName;
  final String priceProvider;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final String nationality;
  /// The exact per-room adults/children/childAges the user searched with —
  /// see [AkHotelResultsScreen.rooms] for why this is threaded through
  /// rather than re-derived from the Rooms API response.
  final List<AkHotelSearchInitRoomEntity> rooms;

  const AkHotelDetailScreen({
    super.key,
    required this.searchId,
    required this.searchTracingKey,
    required this.hotelId,
    required this.hotelName,
    required this.priceProvider,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.nationality,
    required this.rooms,
  });

  @override
  State<AkHotelDetailScreen> createState() => _AkHotelDetailScreenState();
}

class _AkHotelDetailScreenState extends State<AkHotelDetailScreen> {
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _border = Color(0xFFE2E7F0);
  static const _muted = Color(0xFF6B7280);

  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Rooms', 'Photos', 'Amenities', 'Map'];

  AkHotelDetailContentEntity? _content;
  AkHotelRoomsResultEntity? _rooms;
  bool _roomsLoading = true;
  String? _roomsError;
  String _currentCurrency = 'INR';

  @override
  void initState() {
    super.initState();
    _currentCurrency = CurrencyConverter.getPreferredCurrency();
    _loadContent();
    _loadRooms();
  }

  String _formatConvertedPrice(double price, String fromCurrency) {
    final targetCurrency = CurrencyConverter.getPreferredCurrency();
    final converted = CurrencyConverter.convert(
      amount: price,
      fromCurrency: fromCurrency,
      toCurrency: targetCurrency,
    );
    return CurrencyConverter.format(converted, targetCurrency);
  }

  Future<void> _loadContent() async {
    final result = await sl<AkHotelDetailContentUseCase>().call(
      AkHotelDetailContentRequestEntity(
        searchId: widget.searchId,
        hotelId: widget.hotelId,
        priceProvider: widget.priceProvider,
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result is DataSuccess<AkHotelDetailContentEntity>) _content = result.data;
    });
  }

  Future<void> _loadRooms() async {
    final result = await sl<AkHotelRoomsUseCase>().call(
      AkHotelRoomsRequestEntity(
        searchId: widget.searchId,
        hotelId: widget.hotelId,
        searchTracingKey: widget.searchTracingKey,
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result is DataSuccess<AkHotelRoomsResultEntity>) {
        _rooms = result.data;
      } else {
        // A "no rooms found" 502 is normal, real unavailability for this
        // hotel/these dates (confirmed availability is only known at this
        // step, not at the earlier Rate estimate) — say so plainly instead
        // of a generic error. Any other failure shows the backend's actual
        // message when available, since it's usually more informative than
        // a hardcoded string.
        final message = result is DataFailed<AkHotelRoomsResultEntity> ? result.error?.message : null;
        _roomsError = (message != null && message.toLowerCase().contains('no rooms found'))
            ? 'No rooms are available for this hotel on the selected dates.'
            : (message ?? 'Could not load room options. Please try again.');
      }
      _roomsLoading = false;
    });
  }

  void _selectRoom(AkHotelRecommendationEntity recommendation, AkHotelRoomGroupEntity roomGroup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelPriceConfirmScreen(
          searchId: widget.searchId,
          searchTracingKey: widget.searchTracingKey,
          hotelId: widget.hotelId,
          hotelName: widget.hotelName,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          recommendationId: recommendation.id,
          roomGroup: roomGroup,
          nationality: widget.nationality,
          rooms: widget.rooms,
        ),
      ),
    );
  }

  List<String> get _images {
    final c = _content;
    if (c == null) return const [];
    final all = <String>[if (c.heroImage.isNotEmpty) c.heroImage, ...c.images];
    return all.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.h(35),
              errorBuilder: (context, error, stackTrace) => Icon(Icons.hotel, size: context.w(35)),
            ),
          ),
        ],
      ),
      // Content (photos/description/policies) and Rooms are independent,
      // parallel calls — the page no longer waits for Content to finish
      // before showing the tabs, so Rooms (already fetching since
      // initState) renders and displays results as soon as it's ready
      // instead of being hidden behind Content's own loading time.
      // PhotoGallerySection/_buildInfo already degrade gracefully to
      // placeholders/widget-supplied data while _content is still null.
      body: SingleChildScrollView(
        physics: context.scrollPhysics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoGallerySection(
              images: _images,
              hotelName: widget.hotelName,
              rating: (_content?.starRating ?? 0).round(),
              enableFullScreen: false,
            ),
            _buildInfo(),
            _buildBookingBar(),
            SizedBox(height: context.gapMedium),
            _buildTabs(),
            _buildTabContent(),
            SizedBox(height: context.h(30)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final c = _content;
    return Padding(
      padding: context.responsivePadding.copyWith(top: context.gapLarge, bottom: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hotelName,
            style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w800, color: _navy),
          ),
          if (c != null && c.starRating > 0) ...[
            SizedBox(height: context.h(8)),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < c.starRating.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: context.w(15),
                ),
              ),
            ),
          ],
          if (c != null && (c.addressLine1.isNotEmpty || c.city.isNotEmpty)) ...[
            SizedBox(height: context.h(10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: context.w(16), color: _muted),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    [c.addressLine1, c.city, c.state, c.country].where((s) => s.isNotEmpty).join(', '),
                    style: TextStyle(fontSize: context.fs(13), color: _muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (c != null && c.descriptions.isNotEmpty && _stripHtmlTags(c.descriptions.first).isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            Text(
              _stripHtmlTags(c.descriptions.first),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: context.fs(13), color: _muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingBar() {
    return Padding(
      padding: context.horizontalPadding,
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(14)),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(child: _bookingInfoItem('Check in', widget.checkIn)),
            Container(width: 0.6, height: context.h(30), color: _border),
            Expanded(child: _bookingInfoItem('Check out', widget.checkOut)),
            Container(width: 0.6, height: context.h(30), color: _border),
            Expanded(
              child: _bookingInfoItem(
                'Guests',
                '${widget.adults} Adult${widget.adults > 1 ? 's' : ''}${widget.children > 0 ? ', ${widget.children} Child${widget.children > 1 ? 'ren' : ''}' : ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: context.fs(9), color: _muted, fontWeight: FontWeight.w800)),
        SizedBox(height: context.h(3)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: context.fs(12), color: _navy, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      color: _pageBg,
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Padding(
              padding: EdgeInsets.only(right: context.w(10)),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(horizontal: context.w(18), vertical: context.h(9)),
                  decoration: BoxDecoration(
                    color: isSelected ? _blue : Colors.white,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(color: isSelected ? _blue : _border),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _blue.withValues(alpha: 0.25), blurRadius: context.r(10), offset: Offset(0, context.h(4)))]
                        : null,
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: isSelected ? Colors.white : _muted),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildRoomsSection();
      case 1:
        return PhotoGallerySection(
          images: _images,
          hotelName: widget.hotelName,
          rating: (_content?.starRating ?? 0).round(),
          showMainImage: false,
          enableFullScreen: true,
        );
      case 2:
        return AmenitiesSection(
          hotelFacilities: _content?.facilities ?? const [],
          attractions: {
            for (final a in _content?.nearByAttractions ?? const <AkHotelAttractionEntity>[])
              a.name: '${a.distance.toStringAsFixed(1)} ${a.unit}',
          },
        );
      case 3:
        return _buildMapSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoomsSection() {
    return Padding(
      padding: context.responsivePadding.copyWith(top: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_roomsLoading)
            _buildRoomsSkeleton()
          else if (_roomsError != null)
            Text(_roomsError!, style: TextStyle(color: Colors.red.shade400))
          else if ((_rooms?.recommendations ?? []).isEmpty)
            Text('No rooms available for these dates.', style: TextStyle(color: _muted))
          else
            ..._buildGroupedRoomSections(),
        ],
      ),
    );
  }

  /// Skeleton placeholder cards (same shape as [_roomCard]) shown while
  /// Rooms is loading, instead of a bare spinner.
  Widget _buildRoomsSkeleton() {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.r(4))),
        );

    Widget skeletonCard() => Container(
          margin: EdgeInsets.only(bottom: context.gapMedium),
          padding: EdgeInsets.all(context.w(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(context.w(140), context.h(14)),
              SizedBox(height: context.h(8)),
              bar(context.w(90), context.h(11)),
              SizedBox(height: context.h(10)),
              bar(double.infinity, context.h(11)),
              SizedBox(height: context.h(6)),
              bar(context.w(180), context.h(11)),
              SizedBox(height: context.h(14)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: bar(context.w(70), context.h(18))),
                  bar(context.w(90), context.h(36)),
                ],
              ),
            ],
          ),
        );

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(children: List.generate(3, (_) => skeletonCard())),
    );
  }

  /// Groups every (recommendation, roomGroup) pair by room title — options
  /// that share a title (e.g. several "Premium Room" rate plans/providers)
  /// are shown together under one section heading instead of as
  /// indistinguishable repeated cards.
  List<Widget> _buildGroupedRoomSections() {
    final entries = <MapEntry<AkHotelRecommendationEntity, AkHotelRoomGroupEntity>>[
      for (final rec in _rooms!.recommendations)
        for (final rg in rec.roomGroups) MapEntry(rec, rg),
    ];

    final grouped = <String, List<MapEntry<AkHotelRecommendationEntity, AkHotelRoomGroupEntity>>>{};
    for (final e in entries) {
      final title = e.value.roomName.isEmpty ? 'Room' : e.value.roomName;
      grouped.putIfAbsent(title, () => []).add(e);
    }

    final widgets = <Widget>[];
    for (final group in grouped.entries) {
      if (group.value.length > 1) {
        widgets.add(_roomTypeSection(group.key, group.value));
      } else {
        final e = group.value.first;
        widgets.add(_roomCard(e.key, e.value));
      }
    }
    return widgets;
  }

  Widget _roomTypeSection(
      String title,
      List<MapEntry<AkHotelRecommendationEntity, AkHotelRoomGroupEntity>> options,
      ) {
    // Calculate price range for this room type
    final prices = options.map((e) => e.value.totalRate).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.only(bottom: context.gapSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: context.h(8), left: context.w(2)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: context.h(2)),
                  child: Icon(Icons.meeting_room_outlined, size: context.w(16), color: _blue),
                ),
                SizedBox(width: context.w(6)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: _navy, height: 1.25),
                  ),
                ),
                // Add price range here
                ValueListenableBuilder<String>(
                  valueListenable: CurrencyConverter.currencyListenable,
                  builder: (context, currency, _) {
                    final convertedMin = CurrencyConverter.convert(
                      amount: minPrice,
                      fromCurrency: 'INR',
                      toCurrency: currency,
                    );
                    final convertedMax = CurrencyConverter.convert(
                      amount: maxPrice,
                      fromCurrency: 'INR',
                      toCurrency: currency,
                    );
                    final minFormatted = CurrencyConverter.format(convertedMin, currency);
                    final maxFormatted = CurrencyConverter.format(convertedMax, currency);

                    String priceDisplay;
                    if (minPrice == maxPrice) {
                      priceDisplay = minFormatted;
                    } else {
                      priceDisplay = '$minFormatted - $maxFormatted';
                    }

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(context.r(20)),
                      ),
                      child: Text(
                        priceDisplay,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: context.w(4)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(context.r(20)),
                  ),
                  child: Text(
                    '${options.length} options',
                    style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: _blue),
                  ),
                ),
              ],
            ),
          ),
          for (final e in options) _roomCard(e.key, e.value),
        ],
      ),
    );
  }

  // Widget _roomTypeSection(
  //   String title,
  //   List<MapEntry<AkHotelRecommendationEntity, AkHotelRoomGroupEntity>> options,
  // ) {
  //   return Container(
  //     margin: EdgeInsets.only(bottom: context.gapSmall),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.only(bottom: context.h(8), left: context.w(2)),
  //           child: Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Padding(
  //                 padding: EdgeInsets.only(top: context.h(2)),
  //                 child: Icon(Icons.meeting_room_outlined, size: context.w(16), color: _blue),
  //               ),
  //               SizedBox(width: context.w(6)),
  //               // Full title, wraps to as many lines as it needs — never
  //               // truncated — instead of squeezing it onto one line.
  //               Expanded(
  //                 child: Text(
  //                   title,
  //                   style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: _navy, height: 1.25),
  //                 ),
  //               ),
  //               SizedBox(width: context.w(8)),
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
  //                 decoration: BoxDecoration(
  //                   color: _blue.withValues(alpha: 0.08),
  //                   borderRadius: BorderRadius.circular(context.r(20)),
  //                 ),
  //                 child: Text(
  //                   '${options.length} options',
  //                   style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: _blue),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         for (final e in options) _roomCard(e.key, e.value),
  //       ],
  //     ),
  //   );
  // }

  // Widget _roomCard(AkHotelRecommendationEntity rec, AkHotelRoomGroupEntity rg) {
  //   return Container(
  //     margin: EdgeInsets.only(bottom: context.gapMedium),
  //     padding: EdgeInsets.all(context.w(14)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(context.r(12)),
  //       border: Border.all(color: _border),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Full room title — wraps to as many lines as it needs
  //         // (responsive font via context.fs), never truncated.
  //         Text(
  //           rg.roomName.isEmpty ? 'Room' : rg.roomName,
  //           style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800, color: _navy, height: 1.25),
  //         ),
  //         SizedBox(height: context.h(4)),
  //         Text(
  //           rg.providerName,
  //           style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w600),
  //         ),
  //         if (_stripHtmlTags(rg.description).isNotEmpty) ...[
  //           SizedBox(height: context.h(6)),
  //           Text(
  //             _stripHtmlTags(rg.description),
  //             maxLines: 3,
  //             overflow: TextOverflow.ellipsis,
  //             style: TextStyle(fontSize: context.fs(12), color: _muted, height: 1.35),
  //           ),
  //         ],
  //         if (_stripHtmlTags(rg.boardBasisDescription).isNotEmpty) ...[
  //           SizedBox(height: context.h(6)),
  //           Text(_stripHtmlTags(rg.boardBasisDescription), style: TextStyle(fontSize: context.fs(12), color: _muted)),
  //         ],
  //         SizedBox(height: context.h(10)),
  //         Wrap(
  //           spacing: context.w(8),
  //           runSpacing: context.h(6),
  //           children: [
  //             if (rg.refundable) _badge('Refundable', Colors.green),
  //             if (!rg.refundable) _badge('Non-refundable', Colors.red),
  //             if (rg.needsPriceCheck) _badge('Price check required', Colors.orange),
  //             // Real availability from the API — only shown when the vendor
  //             // actually reported a count, never a guessed number.
  //             if (rg.availability > 0) _badge('${rg.availability} room${rg.availability > 1 ? 's' : ''} left', Colors.orange),
  //           ],
  //         ),
  //         SizedBox(height: context.h(12)),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.end,
  //           children: [
  //             // Expanded(
  //             //   child: Text(
  //             //     rg.totalRate.toStringAsFixed(0),
  //             //     maxLines: 1,
  //             //     overflow: TextOverflow.ellipsis,
  //             //     style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy),
  //             //   ),
  //             // ),
  //             Expanded(
  //               child: ValueListenableBuilder<String>(
  //                 valueListenable: CurrencyConverter.currencyListenable,
  //                 builder: (context, currency, _) {
  //                   final converted = CurrencyConverter.convert(
  //                     amount: rg.totalRate,
  //                     fromCurrency: 'INR', // Assuming rooms are in INR
  //                     toCurrency: currency,
  //                   );
  //                   final formatted = CurrencyConverter.format(converted, currency);
  //                   return Text(
  //                     formatted,
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy),
  //                   );
  //                 },
  //               ),
  //             ),
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: _blue,
  //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
  //               ),
  //               onPressed: () => _selectRoom(rec, rg),
  //               child: const Text('Select', style: TextStyle(color: Colors.white)),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _roomCard(AkHotelRecommendationEntity rec, AkHotelRoomGroupEntity rg) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rg.roomName.isEmpty ? 'Room' : rg.roomName,
            style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800, color: _navy, height: 1.25),
          ),
          SizedBox(height: context.h(4)),
          Text(
            rg.providerName,
            style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w600),
          ),
          if (_stripHtmlTags(rg.description).isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Text(
              _stripHtmlTags(rg.description),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: context.fs(12), color: _muted, height: 1.35),
            ),
          ],
          if (_stripHtmlTags(rg.boardBasisDescription).isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Text(_stripHtmlTags(rg.boardBasisDescription), style: TextStyle(fontSize: context.fs(12), color: _muted)),
          ],
          SizedBox(height: context.h(10)),
          Wrap(
            spacing: context.w(8),
            runSpacing: context.h(6),
            children: [
              if (rg.refundable) _badge('Refundable', Colors.green),
              if (!rg.refundable) _badge('Non-refundable', Colors.red),
              if (rg.needsPriceCheck) _badge('Price check required', Colors.orange),
              if (rg.availability > 0) _badge('${rg.availability} room${rg.availability > 1 ? 's' : ''} left', Colors.orange),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: CurrencyConverter.currencyListenable,
                  builder: (context, currency, _) {
                    final converted = CurrencyConverter.convert(
                      amount: rg.totalRate,
                      fromCurrency: 'INR', // Assuming rooms are in INR
                      toCurrency: currency,
                    );
                    final formatted = CurrencyConverter.format(converted, currency);
                    return Text(
                      formatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy),
                    );
                  },
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
                ),
                onPressed: () => _selectRoom(rec, rg),
                child: const Text('Select', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Vendor description/board-basis text sometimes arrives as raw HTML
  /// (e.g. "<p>Free WiFi</b>") — strip tags and decode the handful of
  /// entities that commonly survive that, so only plain text is shown.
  String _stripHtmlTags(String html) {
    if (html.isEmpty) return html;
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _badge(String text, MaterialColor color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: color.shade200),
      ),
      child: Text(text, style: TextStyle(fontSize: context.fs(10), color: color.shade700, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildMapSection() {
    final lat = _content?.lat;
    final long = _content?.long;
    if (lat == null || long == null) {
      return Padding(
        padding: context.responsivePadding,
        child: Center(
          child: Column(
            children: [
              Icon(Icons.location_off, size: context.w(44), color: Colors.grey[400]),
              SizedBox(height: context.h(8)),
              Text('Location not available', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final position = LatLng(lat, long);

    return Container(
      padding: context.responsivePadding,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: TextStyle(fontSize: context.titleSmall, fontWeight: FontWeight.bold)),
          SizedBox(height: context.h(12)),
          Container(
            height: context.h(220),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(context.r(12)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: context.r(8), offset: Offset(0, context.h(4)))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.r(12)),
              child: InkWell(
                onTap: () => _openInGoogleMaps(position),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/map1.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: context.w(48), color: Colors.grey[400]),
                              SizedBox(height: context.h(8)),
                              Text('Map View', style: TextStyle(color: Colors.grey[500], fontSize: context.fs(12))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: context.h(12),
                      right: context.w(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(5)),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(context.r(6))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new, size: context.w(14), color: Colors.white),
                            SizedBox(width: context.w(4)),
                            Text('Open in Maps', style: TextStyle(color: Colors.white, fontSize: context.fs(10), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(16)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInGoogleMaps(position),
              icon: Icon(Icons.directions, size: context.w(16)),
              label: const Text('Get Directions'),
              style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: context.h(12))),
            ),
          ),
        ],
      ),
    );
  }

  void _openInGoogleMaps(LatLng position) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }
}
