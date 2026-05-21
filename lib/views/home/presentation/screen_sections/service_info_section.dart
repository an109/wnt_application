import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';


class ServicesInfoSection extends StatefulWidget {
  const ServicesInfoSection({super.key});

  @override
  State<ServicesInfoSection> createState() => _ServicesInfoSectionState();
}

class _ServicesInfoSectionState extends State<ServicesInfoSection> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load general settings data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GeneralSettingsBloc>()
            .add(const LoadGeneralSettings(domain: 'thewandernova.com'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        // Handle loading state
        if (state is GeneralSettingsLoading || state is GeneralSettingsInitial) {
          return _buildLoadingSection(context);
        }

        // Handle error state
        if (state is GeneralSettingsError) {
          return _buildErrorSection(context, state.message);
        }

        // Extract more links content from state
        List<MoreLinkEntity> moreLinks = [];

        if (state is GeneralSettingsLoaded) {
          moreLinks = state.generalSettings.moreLinksContent;
        } else if (state is PopularDestinationsDataLoaded) {
          moreLinks = state.generalSettings.moreLinksContent;
        }

        // Show message if no links available
        if (moreLinks.isEmpty) {
          return _buildEmptySection(context);
        }

        // Ensure selected index is within bounds
        if (_selectedTabIndex >= moreLinks.length) {
          _selectedTabIndex = 0;
        }

        final selectedLink = moreLinks[_selectedTabIndex];

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
            vertical: context.hp(2),
          ),
          color: const Color(0xfff7f7f7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Dynamic Tabs from API
              Wrap(
                spacing: context.gapMedium,
                runSpacing: context.gapSmall,
                children: List.generate(
                  moreLinks.length,
                      (index) => _serviceTab(
                    context,
                    title: moreLinks[index].title,
                    isSelected: index == _selectedTabIndex,
                    onTap: () => _handleTabTap(index),
                  ),
                ),
              ),

              SizedBox(height: context.gapMedium),

              Divider(
                thickness: 1,
                color: Colors.grey.shade300,
              ),

              SizedBox(height: context.gapMedium),

              /// Dynamic Heading from API with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  selectedLink.title,
                  key: ValueKey<int>(_selectedTabIndex),
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: context.gapSmall),

              /// Dynamic Content from API with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  selectedLink.text,
                  key: ValueKey<int>(_selectedTabIndex),
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTabTap(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  Widget _serviceTab(
      BuildContext context, {
        required String title,
        required bool isSelected,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.bodyMedium,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xff004b6b),
            ),
          ),
          SizedBox(height: context.gapXSmall),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 2,
            width: isSelected ? 60 : 0,
            color: const Color(0xff004b6b),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
        vertical: context.hp(2),
      ),
      color: const Color(0xfff7f7f7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading tabs skeleton
          Wrap(
            spacing: context.gapMedium,
            runSpacing: context.gapSmall,
            children: List.generate(
              4,
                  (index) => Container(
                width: context.wp(22),
                height: context.hp(3),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: context.gapMedium),
          Divider(thickness: 1, color: Colors.grey.shade300),
          SizedBox(height: context.gapMedium),
          // Loading heading skeleton
          Container(
            width: context.wp(30),
            height: context.hp(3.5),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: context.gapSmall),
          // Loading content skeleton
          Container(
            height: context.hp(6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
        vertical: context.hp(2),
      ),
      color: const Color(0xfff7f7f7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failed to load services',
            style: TextStyle(
              fontSize: context.titleSmall,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          SizedBox(height: context.gapXSmall),
          Text(
            message,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
        vertical: context.hp(2),
      ),
      color: const Color(0xfff7f7f7),
      child: Text(
        'No services information available at the moment.',
        style: TextStyle(
          fontSize: context.bodyMedium,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}