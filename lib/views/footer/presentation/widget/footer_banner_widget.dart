import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../bloc/footer_setting_bloc.dart';
import '../bloc/footer_setting_event.dart';
import '../bloc/footer_setting_state.dart';

class FooterBannerWidget extends StatelessWidget {
  final String domain;
  final double? height;
  final double? width;
  final BoxFit fit;

  const FooterBannerWidget({
    super.key,
    required this.domain,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FooterSettingsBloc>()
        ..add(LoadFooterSettings(domain: domain)),
      child: BlocBuilder<FooterSettingsBloc, FooterSettingsState>(
        builder: (context, state) {
          if (state is FooterSettingsLoaded) {
            final settings = state.settings.settings;

            // Only show if banner is enabled and image exists
            if (!settings.showFooterBanner || settings.footerBannerImage.isEmpty) {
              return const SizedBox.shrink();
            }

            final bannerHeight = height ?? context.hp(15);
            final bannerWidth = width ?? double.infinity;

            return Container(
              width: bannerWidth,
              height: bannerHeight,
              margin: EdgeInsets.only(top: context.gapMedium),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                child: Image.network(
                  settings.footerBannerImage,
                  width: double.infinity,
                  height: double.infinity,
                  // fit: BoxFit.contain,
                  // fit: fit,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.lightBg,
                      child: Center(
                        child: SizedBox(
                          height: context.iconMedium,
                          width: context.iconMedium,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.lightBg,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: context.iconLarge,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          if (state is FooterSettingsError) {
            // Silently fail - don't show error UI for optional banner
            return const SizedBox.shrink();
          }

          // Initial or loading state - show minimal placeholder
          if (state is FooterSettingsLoading || state is FooterSettingsInitial) {
            return Container(
              height: height ?? context.hp(15),
              margin: EdgeInsets.only(top: context.gapMedium),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
              ),
              child: Center(
                child: SizedBox(
                  height: context.iconSmall,
                  width: context.iconSmall,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}