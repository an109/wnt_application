import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../core/resources/app_colours.dart';
import '../sections/book_now_pay_later.dart';
import '../sections/cutomize_trip_dialogue.dart';
import '../sections/hero_section.dart';
import '../sections/holidays_by_theme_Section.dart';
import '../sections/international_destination_section.dart';
import '../sections/last-minute escape sale.dart';
import '../sections/recently_viewed_section.dart';
import '../sections/visaFreeDestination.dart';
import '../widget/animated_my_trip_button.dart';
import '../widget/holiday_search_card.dart';

class NewHolidayScreen extends StatefulWidget {
  const NewHolidayScreen({super.key});

  @override
  State<NewHolidayScreen> createState() => _NewHolidayScreenState();
}

class _NewHolidayScreenState extends State<NewHolidayScreen> {
  bool _isSearchCollapsed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final scrollPosition = _scrollController.offset;
      final threshold = 200.0; // Adjust based on your design

      setState(() {
        _isSearchCollapsed = scrollPosition > threshold;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Holiday Packages',
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'India and International',
              style: TextStyle(
                fontSize: context.labelSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.wp(4)),
            child: AnimatedMyTripButton(
              onTap: () {
                // Navigate to My Trips
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: context.scrollPhysics,
          slivers: [
            // Search Card (Sticky when collapsed)
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child: HolidaySearchCard(
                  isCollapsed: _isSearchCollapsed,
                  onSearch: (origin, destination, date, adults, rooms) {
                    _handleSearch(origin, destination, date, adults, rooms);
                  },
                ),
              ),
            ),

            // Recently Viewed Packages
            SliverToBoxAdapter(
              child: RecentlyViewedSection(),
            ),

            SliverToBoxAdapter(
              child: LastMinuteEscape(),
            ),

            SliverToBoxAdapter(
              child: HolidaysByThemeSection(),
            ),

            SliverToBoxAdapter(
              child: BookNowPayLaterSection(),
            ),

            //  International Destinations Section
            SliverToBoxAdapter(
              child: InternationalDestinationsSection(),
            ),


            SliverToBoxAdapter(
              child: SizedBox(height: context.gapLarge),
            ),

            // Categories
            // SliverToBoxAdapter(
            //   child: CategoriesSection(),
            // ),
            // SliverToBoxAdapter(
            //   child: SizedBox(height: context.gapLarge),
            // ),
            //
            // // Popular Packages
            // SliverToBoxAdapter(
            //   child: PackagesSection(),
            // ),

            // Summer Escapes
            SliverToBoxAdapter(
              child: VisaFreeSection(),
            ),

            // Hero Carousel
            SliverToBoxAdapter(
              child: HeroSection(),
            ),

            // Bottom Padding
            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(2)),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCustomiseTripButton(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildCustomiseTripButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9C27B0),
            Color(0xFF673AB7),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9C27B0).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            showCustomTripDialog(context);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(4),
              vertical: context.hp(1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(context.gapSmall),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.white,
                    size: context.iconSmall,
                  ),
                ),
                SizedBox(width: context.gapSmall),
                Text(
                  'Customise my trip',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSearch(String origin, String destination, DateTime date, int adults, int rooms) {
    // Handle search logic
    print('Search: $origin -> $destination');
    print('Date: ${DateFormat('dd MMM yyyy').format(date)}');
    print('Adults: $adults, Rooms: $rooms');

    // Show success message or navigate to results
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching packages from $origin to $destination...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}