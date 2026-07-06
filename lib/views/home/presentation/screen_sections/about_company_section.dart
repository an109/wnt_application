import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';

class AboutCompanySection extends StatefulWidget {
  const AboutCompanySection({super.key});

  @override
  State<AboutCompanySection> createState() => _AboutCompanySectionState();
}

class _AboutCompanySectionState extends State<AboutCompanySection> {

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
          return _buildLoadingSections(context);
        }

        // Handle error state
        if (state is GeneralSettingsError) {
          return _buildErrorSection(context, state.message);
        }

        // Extract about tabs content from state
        List<AboutTabEntity> aboutTabs = [];

        if (state is GeneralSettingsLoaded) {
          aboutTabs = state.generalSettings.aboutTabsContent;
        } else if (state is PopularDestinationsDataLoaded) {
          aboutTabs = state.generalSettings.aboutTabsContent;
        }

        // Show message if no sections available
        if (aboutTabs.isEmpty) {
          return _buildEmptySection(context);
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
            vertical: context.hp(4),
          ),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use grid layout for desktop, single column for mobile/tablet
              if (context.isDesktop && aboutTabs.length >= 2) {
                return _buildGridSections(context, aboutTabs, constraints);
              } else {
                return _buildVerticalSections(context, aboutTabs);
              }
            },
          ),
        );
      },
    );
  }

  /// Grid layout for desktop
  Widget _buildGridSections(BuildContext context, List<AboutTabEntity> sections, BoxConstraints constraints) {
    // Calculate number of columns based on content count
    int crossAxisCount = sections.length >= 3 ? 3 : sections.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: context.gapLarge,
        mainAxisSpacing: context.gapXLarge,
        childAspectRatio: 1.2, // Adjust based on your content needs
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return _buildSectionCard(context, sections[index], index);
      },
    );
  }

  /// Vertical scrollable layout for mobile/tablet
  Widget _buildVerticalSections(BuildContext context, List<AboutTabEntity> sections) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return _buildSectionCard(context, sections[index], index);
      },
    );
  }

  /// Individual section card
  Widget _buildSectionCard(BuildContext context, AboutTabEntity section, int index) {
    // For mobile/tablet, show as sections with dividers
    // For desktop, show as cards

    if (context.isDesktop) {
      // Card style for desktop
      return Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header/Icon
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: context.gapSmall),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: context.titleSmall * 1.2,
                    decoration: BoxDecoration(
                      color: const Color(0xff004b6b),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: context.gapXSmall),
                  Expanded(
                    child: Text(
                      section.heading,
                      style: TextStyle(
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff004b6b),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.gapSmall),

            // Section Content
            Expanded(
              child: Text(
                section.content,
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 8,
              ),
            ),

            // Optional: Read more button for longer content
            if (section.content.length > 300)
              Padding(
                padding: EdgeInsets.only(top: context.gapSmall),
                child: TextButton(
                  onPressed: () => _showFullContentDialog(context, section),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Read More →',
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: const Color(0xff004b6b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // List style for mobile/tablet
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: context.h(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.heading,
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff004b6b),
                  ),
                ),

              ],
            ),
          ),
          SizedBox(height: context.gapSmall),

          // Section Content
          Text(
            section.content,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),

          // Separator (except for last item)
          if (index != (context.read<GeneralSettingsBloc>().state as GeneralSettingsLoaded)
              .generalSettings.aboutTabsContent.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.gapLarge),
              child: Divider(
                color: Colors.grey.shade200,
                thickness: 1,
              ),
            ),
        ],
      );
    }
  }

  /// Dialog to show full content
  void _showFullContentDialog(BuildContext context, AboutTabEntity section) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        ),
        child: Container(
          width: context.isDesktop ? context.wp(50) : context.wp(90),
          constraints: BoxConstraints(
            maxHeight: context.hp(80),
          ),
          padding: EdgeInsets.all(context.gapLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.heading,
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff004b6b),
                ),
              ),
              SizedBox(height: context.gapMedium),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    section.content,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.gapMedium),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: context.bodyLarge,
                      color: const Color(0xff004b6b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading skeleton for sections
  Widget _buildLoadingSections(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
        vertical: context.hp(4),
      ),
      color: Colors.white,
      child: context.isDesktop
          ? GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: context.gapLarge,
          mainAxisSpacing: context.gapXLarge,
          childAspectRatio: 1.2,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _buildLoadingCard(context),
      )
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => _buildLoadingListItem(context),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: context.titleSmall * 1.5,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: context.gapSmall),
          Expanded(
            child: Column(
              children: List.generate(
                4,
                    (index) => Padding(
                  padding: EdgeInsets.only(bottom: context.gapXSmall),
                  child: Container(
                    height: context.bodyMedium,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingListItem(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.gapXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.wp(25),
            height: context.titleLarge,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: context.gapSmall),
          Container(
            width: context.wp(15),
            height: 3,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: context.gapMedium),
          Container(
            height: context.hp(10),
            color: Colors.grey.shade300,
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
        vertical: context.hp(4),
      ),
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: context.iconLarge,
              color: Colors.red.shade400,
            ),
            SizedBox(height: context.gapMedium),
            Text(
              'Failed to load content',
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: context.gapXSmall),
            Text(
              message,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.gapMedium),
            ElevatedButton(
              onPressed: () {
                context.read<GeneralSettingsBloc>()
                    .add(const LoadGeneralSettings(domain: 'thewandernova.com'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff004b6b),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
        vertical: context.hp(4),
      ),
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: context.iconLarge,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: context.gapMedium),
            Text(
              'No information available at the moment.',
              style: TextStyle(
                fontSize: context.bodyLarge,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}