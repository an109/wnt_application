import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../VisaDestination/presentation/section/visa_search_card.dart';


class VisaBannerSection extends StatefulWidget {
  const VisaBannerSection({super.key});

  @override
  State<VisaBannerSection> createState() => _VisaBannerSectionState();
}

class _VisaBannerSectionState extends State<VisaBannerSection> {
  String? _visaHeroImage;
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
            _visaHeroImage = state.sectionHeroes.visa;
            _isLoadingImage = false;
          });
        } else if (state is GeneralSettingsError) {
          setState(() {
            _isLoadingImage = false;
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          /// BANNER IMAGE - Dynamic from API
          SizedBox(
            height: context.isMobile
                ? context.hp(38)
                : context.hp(50),

            width: double.infinity,

            child: Stack(
              fit: StackFit.expand,
              children: [
                _getBackgroundImage(),

                Container(
                  color: Colors.black.withOpacity(0.25),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(6),
                    vertical: context.hp(5),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      SizedBox(height: context.hp(9)),

                      Text(
                        "Choose Destination.",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: context.sp(25),
                          height: 1,
                        ),
                      ),

                      SizedBox(height: context.hp(0.2)),

                      Text(
                        "We'll Handle the Visa",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: context.bodyLarge,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// SEARCH CARD
          Positioned(
            left: context.wp(4),
            right: context.wp(4),
            bottom: -context.hp(-7),

            child: const VisaSearchCard(),
          ),
        ],
      ),
    );
  }

  Widget _getBackgroundImage() {
    // If we have an image URL from API, use it
    if (_visaHeroImage != null && _visaHeroImage!.isNotEmpty) {
      return Image.network(
        _visaHeroImage!,
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
          print('Error loading visa hero image: $error');
          // Fallback to default image if API image fails
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