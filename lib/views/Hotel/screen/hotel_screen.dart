import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../common_widgets/logo.dart';
import '../../../injection_container.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../home/presentation/screen_sections/about_company_section.dart';
import '../../home/presentation/screen_sections/service_info_section.dart';
import '../../home/presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../section/exclusive_deals/hotel_info.dart';
import '../section/exclusive_deals/hotel_search_card.dart';
import '../section/exclusive_deals/popular_destination.dart';
import '../../travel_stories/presentation/screen/travel_stories.dart';


class HotelBookingScreen extends StatefulWidget {
  const HotelBookingScreen({super.key});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  String? _hotelHeroImage;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    // Load section heroes data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GeneralSettingsBloc>()
            .add(const LoadSectionHeroes(domain: 'thewandernova.com'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded) {
          setState(() {
            _hotelHeroImage = state.sectionHeroes.hotel;
            _isLoadingImage = false;
          });
        } else if (state is GeneralSettingsError) {
          setState(() {
            _isLoadingImage = false;
          });
        }
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.w(8)),
              child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
            )
          ],
        ),
        body: CustomScrollView(
          physics: context.scrollPhysics,
          slivers: [

            /// TOP IMAGE + SEARCH CARD
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  /// BACKGROUND IMAGE - Dynamic from API
                  SizedBox(
                    height: context.hp(55),
                    width: double.infinity,
                    child: _getBackgroundImage(),
                  ),

                  /// DARK OVERLAY
                  IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height: context.hp(55),
                      color: Colors.black.withOpacity(0.25),
                    ),
                  ),

                  /// TITLE
                  Positioned(
                    top: context.hp(12),
                    left: context.wp(5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hotel,
                          color: Colors.white,
                          size: context.iconLarge,
                        ),

                        SizedBox(width: context.gapSmall),

                        Text(
                          "Book Hotel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.titleLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// SEARCH CARD
                  Positioned(
                    left: context.wp(4),
                    right: context.wp(4),
                    bottom: -context.hp(-4),
                    child: Material(
                      color: Colors.transparent,
                      child: HotelSearchCard(),
                    ),
                  ),
                ],
              ),
            ),

            /// SPACE BELOW OVERLAPPING CARD
            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(2)),
            ),

            /// EXCLUSIVE DEALS SECTION
            SliverToBoxAdapter(
              child: BlocProvider<ExclusiveDealsBloc>(
                create: (context) => sl<ExclusiveDealsBloc>(),
                child: const TransportExclusiveDealsSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HotelPopularDestinationsSection(),
            ),

            const SliverToBoxAdapter(
              child: TravelStoriesSection(),
            ),

            const SliverToBoxAdapter(
              child: HotelInfoSection(),
            ),

            const SliverToBoxAdapter(
              child: WhyChooseUs(),
            ),

            SliverToBoxAdapter(
              child: BlocProvider(
                create: (_) => sl<GeneralSettingsBloc>()
                  ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
                child: const AboutCompanySection(),
              ),
            ),

            SliverToBoxAdapter(
              child: BlocProvider(
                create: (_) => sl<GeneralSettingsBloc>()
                  ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
                child: const ServicesInfoSection(),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(10)),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNav(
          currentIndex: 1,
        ),
      ),
    );
  }

  Widget _getBackgroundImage() {
    // If we have an image URL from API, use it
    if (_hotelHeroImage != null && _hotelHeroImage!.isNotEmpty) {
      return Image.network(
        _hotelHeroImage!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFE0E0E0),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading hotel hero image: $error');
          return Container(color: const Color(0xFFE0E0E0));
        },
      );
    }

    // Show loading or default image
    return _isLoadingImage
        ? Container(
      color: const Color(0xFFE0E0E0),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    )
        :  Container(color: const Color(0xFFE0E0E0));
  }

}