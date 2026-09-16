import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';
import '../widgets/ak_hotel_bottom_bar.dart';
import '../widgets/ak_hotel_client_filters.dart';
import '../widgets/ak_hotel_section_card.dart';
import '../widgets/ak_hotel_sort_sheet.dart';
import '../widgets/ak_hotel_top_bar.dart';
import 'ak_hotel_filter_screen.dart';

/// "View All" destination for a single [AkHotelResultsScreen] section
/// (Match / Recommended Hotel / Near by). Shows every hotel already loaded
/// into that section — a plain snapshot [hotels] list, so this screen never
/// fetches anything itself and can't introduce mock/static data. Its own
/// Sort/Filter are purely local, additive refinements layered on top of that
/// snapshot; [onSelectHotel] delegates the actual navigation/booking flow
/// back to the caller so it stays byte-identical to the main results screen.
class AkHotelViewAllScreen extends StatefulWidget {
  final String title;
  final List<HotelUiModel> hotels;
  final ValueChanged<HotelUiModel> onSelectHotel;
  // Same search summary [AkHotelResultsScreen] shows in its AkHotelTopBar —
  // threaded through so this screen can show that bar too, instead of a
  // plain "<section title>" AppBar.
  final String locationName;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int roomCount;

  const AkHotelViewAllScreen({
    super.key,
    required this.title,
    required this.hotels,
    required this.onSelectHotel,
    required this.locationName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.roomCount,
  });

  @override
  State<AkHotelViewAllScreen> createState() => _AkHotelViewAllScreenState();
}

class _AkHotelViewAllScreenState extends State<AkHotelViewAllScreen> {
  AkHotelSortOption? _sortOption;
  bool _isFilterApplied = false;
  Map<String, dynamic> _activeFilters = {};

  List<HotelUiModel> get _visibleHotels {
    final filtered = applyAkHotelClientFilters(widget.hotels, _activeFilters);
    return applyAkHotelSort(filtered, _sortOption);
  }

  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelFilterScreen(
          initialFilters: _activeFilters,
          hotels: widget.hotels,
          onApply: (filters) => setState(() {
            _isFilterApplied = true;
            _activeFilters = filters;
          }),
          onClear: () => setState(() {
            _isFilterApplied = false;
            _activeFilters = {};
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotels = _visibleHotels;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AkHotelTopBar(
            locationName: widget.locationName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            adults: widget.adults,
            children: widget.children,
            roomCount: widget.roomCount,
            onBack: () => Navigator.of(context).maybePop(),
            onEdit: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Stack(
              children: [
                hotels.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          context.w(12),
                          context.h(12),
                          context.w(12),
                          context.h(90),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.isTablet || context.isDesktop ? 3 : 2,
                          crossAxisSpacing: context.w(10),
                          mainAxisSpacing: context.h(12),
                          childAspectRatio: 0.72,
                        ),
                        itemCount: hotels.length,
                        itemBuilder: (context, index) {
                          final hotel = hotels[index];
                          return AkHotelSectionCard(
                            hotel: hotel,
                            width: null,
                            onTap: () => widget.onSelectHotel(hotel),
                          );
                        },
                      ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AkHotelBottomBar(
                    sortActive: _sortOption != null,
                    filterActive: _isFilterApplied,
                    onMapTap: () {},
                    onSortTap: () => showAkHotelSortSheet(
                      context: context,
                      current: _sortOption,
                      onSelected: (option) => setState(() => _sortOption = option),
                    ),
                    onFilterTap: _openFilterScreen,
                    onAiTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: context.horizontalPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_outlined, size: context.iconLarge * 2, color: Colors.grey.shade400),
            SizedBox(height: context.gapLarge),
            Text(
              'No hotels match your filters',
              style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}
