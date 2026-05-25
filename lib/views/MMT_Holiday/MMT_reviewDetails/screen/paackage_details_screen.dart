import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/MMT_Holiday/MMT_reviewDetails/section/destination_guideSection.dart';
import 'package:wander_nova/views/MMT_Holiday/MMT_reviewDetails/section/expandable_section.dart';
import 'package:wander_nova/views/MMT_Holiday/MMT_reviewDetails/section/headerSection.dart';
import 'package:wander_nova/views/MMT_Holiday/MMT_reviewDetails/section/itinerary_section.dart';
import 'package:wander_nova/views/MMT_Holiday/MMT_reviewDetails/section/package_infoSection.dart';
import 'package:wander_nova/views/MMT_Holiday/MMT_reviewDetails/widget/package_bottom_bar.dart';
import '../../../../core/resources/app_colours.dart';
import '../../sections/cutomize_trip_dialogue.dart';
import '../section/T&C.dart';
import '../section/policy_section.dart';
import '../section/summary_timeline_section.dart';


class PackageDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> packageData;

  const PackageDetailsScreen({
    super.key,
    required this.packageData,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  int _currentImageIndex = 0;
  // final CarouselController _carouselController = CarouselController();
  final CarouselSliderController _carouselController = CarouselSliderController();
  // Sample images
  final List<String> _images = [
    'https://picsum.photos/seed/goa1/800/400',
    'https://picsum.photos/seed/goa2/800/400',
    'https://picsum.photos/seed/goa3/800/400',
    'https://picsum.photos/seed/goa4/800/400',
    'https://picsum.photos/seed/goa5/800/400',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Image Carousel
              SliverToBoxAdapter(
                child: PackageHeaderSection(
                  images: _images,
                  currentIndex: _currentImageIndex,
                  carouselController: _carouselController,
                  onIndexChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                ),
              ),

              // Package Info Section
              SliverToBoxAdapter(
                child: PackageInfoSection(
                  packageName: widget.packageData['title'] ?? 'Most Wanted Goa Package',
                  duration: widget.packageData['duration'] ?? '4N / 5D',
                  location: widget.packageData['location'] ?? 'Goa',
                  originCity: 'New Delhi',
                  travellers: 2,
                  startDate: DateTime(2026, 6, 22),
                  endDate: DateTime(2026, 6, 26),
                  onModify: () {

                  },
                ),
              ),

              // Warning Message
              SliverToBoxAdapter(
                child: _buildWarningMessage(),
              ),

              // Booking Offer
              SliverToBoxAdapter(
                child: _buildBookingOffer(),
              ),

              //  FIX: Wrap SizedBox with SliverToBoxAdapter
              SliverToBoxAdapter(
                child: SizedBox(height: context.gapMedium),
              ),

              // Itinerary Section
              SliverToBoxAdapter(
                child: ItinerarySection(
                  packageData: widget.packageData,
                ),
              ),


              // Destination Guide
              SliverToBoxAdapter(
                child: DestinationGuideSection(
                  destination: 'Goa',
                ),
              ),

              // Expandable Sections
              SliverToBoxAdapter(
                child: ExpandableSection(
                  title: 'Summary',
                  child: const SummaryTimelineSection(),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const TermsConditionsScreen(),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(4),
                        vertical: context.gapMedium,
                      ),
                      child: Row(
                        children: [

                          Text(
                            'Terms and Conditions',
                            style: TextStyle(
                              fontSize: context.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),

                          const Spacer(),

                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                            size: context.iconMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PoliciesScreen(),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(4),
                        vertical: context.gapMedium,
                      ),
                      child: Row(
                        children: [

                          Text(
                            'Policies',
                            style: TextStyle(
                              fontSize: context.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),

                          const Spacer(),

                          Icon(
                            Icons.keyboard_arrow_up,
                            color: AppColors.primary,
                            size: context.iconMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Padding for FAB and Bottom Bar
              SliverToBoxAdapter(
                child: SizedBox(height: context.hp(15)),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildCustomiseTripButton(),
        bottomNavigationBar: PackageBottomBar(
          originalPrice: 6513,
          discountedPrice: 6361,
          offersCount: 2,
          onBookNow: () {
            _showBookingDialog();
          },
        ),
      ),
    );
  }


  Widget _buildWarningMessage() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        border: Border.all(color: Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFA000),
            size: context.iconMedium,
          ),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Text(
              'Please note that the start city of your package is Goa',
              style: TextStyle(
                fontSize: context.bodySmall,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: context.iconSmall, color: Color(0xFFFFA000),),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOffer() {
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_rupee,
            color: Color(0xFF4CAF50),
            size: context.iconMedium,
          ),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book this package only @ ₹1',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Next installment payable by 11 Jun \'26',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    color: Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking'),
        content: Text('Proceed to book this package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}