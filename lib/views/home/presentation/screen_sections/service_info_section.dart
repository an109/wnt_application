// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../UI_helper/responsive_layout.dart';
// import '../../../MainApi/domain/entities/general_setting_entity.dart';
// import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
// import '../../../MainApi/presentation/bloc/general_settings_event.dart';
// import '../../../MainApi/presentation/bloc/general_settings_state.dart';
//
//
// class ServicesInfoSection extends StatefulWidget {
//   const ServicesInfoSection({super.key});
//
//   @override
//   State<ServicesInfoSection> createState() => _ServicesInfoSectionState();
// }
//
// class _ServicesInfoSectionState extends State<ServicesInfoSection> {
//   int _selectedTabIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     // Load general settings data when widget initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         context.read<GeneralSettingsBloc>()
//             .add(const LoadGeneralSettings(domain: 'thewandernova.com'));
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
//       builder: (context, state) {
//         // Handle loading state
//         if (state is GeneralSettingsLoading || state is GeneralSettingsInitial) {
//           return _buildLoadingSection(context);
//         }
//
//         // Handle error state
//         if (state is GeneralSettingsError) {
//           return _buildErrorSection(context, state.message);
//         }
//
//         // Extract more links content from state
//         List<MoreLinkEntity> moreLinks = [];
//
//         if (state is GeneralSettingsLoaded) {
//           moreLinks = state.generalSettings.moreLinksContent;
//         } else if (state is PopularDestinationsDataLoaded) {
//           moreLinks = state.generalSettings.moreLinksContent;
//         }
//
//         // Show message if no links available
//         if (moreLinks.isEmpty) {
//           return _buildEmptySection(context);
//         }
//
//         // Ensure selected index is within bounds
//         if (_selectedTabIndex >= moreLinks.length) {
//           _selectedTabIndex = 0;
//         }
//
//         final selectedLink = moreLinks[_selectedTabIndex];
//
//         return Container(
//           width: double.infinity,
//           padding: EdgeInsets.symmetric(
//             horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
//             vertical: context.hp(2),
//           ),
//           color: const Color(0xfff7f7f7),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// Dynamic Tabs from API
//               Wrap(
//                 spacing: context.gapMedium,
//                 runSpacing: context.gapSmall,
//                 children: List.generate(
//                   moreLinks.length,
//                       (index) => _serviceTab(
//                     context,
//                     title: moreLinks[index].title,
//                     isSelected: index == _selectedTabIndex,
//                     onTap: () => _handleTabTap(index),
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: context.gapMedium),
//
//               Divider(
//                 thickness: 1,
//                 color: Colors.grey.shade300,
//               ),
//
//               SizedBox(height: context.gapMedium),
//
//               /// Dynamic Heading from API with animation
//               AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 transitionBuilder: (child, animation) {
//                   return FadeTransition(opacity: animation, child: child);
//                 },
//                 child: Text(
//                   selectedLink.title,
//                   key: ValueKey<int>(_selectedTabIndex),
//                   style: TextStyle(
//                     fontSize: context.titleLarge,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: context.gapSmall),
//
//               /// Dynamic Content from API with animation
//               AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 transitionBuilder: (child, animation) {
//                   return FadeTransition(opacity: animation, child: child);
//                 },
//                 child: Text(
//                   selectedLink.text,
//                   key: ValueKey<int>(_selectedTabIndex),
//                   style: TextStyle(
//                     fontSize: context.bodyMedium,
//                     color: Colors.grey.shade700,
//                     height: 1.6,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void _handleTabTap(int index) {
//     if (_selectedTabIndex != index) {
//       setState(() {
//         _selectedTabIndex = index;
//       });
//     }
//   }
//
//   Widget _serviceTab(
//       BuildContext context, {
//         required String title,
//         required bool isSelected,
//         VoidCallback? onTap,
//       }) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: context.bodyMedium,
//               fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
//               color: const Color(0xff004b6b),
//             ),
//           ),
//           SizedBox(height: context.gapXSmall),
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 250),
//             height: 2,
//             width: isSelected ? 60 : 0,
//             color: const Color(0xff004b6b),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLoadingSection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(
//         horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
//         vertical: context.hp(2),
//       ),
//       color: const Color(0xfff7f7f7),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Loading tabs skeleton
//           Wrap(
//             spacing: context.gapMedium,
//             runSpacing: context.gapSmall,
//             children: List.generate(
//               4,
//                   (index) => Container(
//                 width: context.wp(22),
//                 height: context.hp(3),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: context.gapMedium),
//           Divider(thickness: 1, color: Colors.grey.shade300),
//           SizedBox(height: context.gapMedium),
//           // Loading heading skeleton
//           Container(
//             width: context.wp(30),
//             height: context.hp(3.5),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//           SizedBox(height: context.gapSmall),
//           // Loading content skeleton
//           Container(
//             height: context.hp(6),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorSection(BuildContext context, String message) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(
//         horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
//         vertical: context.hp(2),
//       ),
//       color: const Color(0xfff7f7f7),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Failed to load services',
//             style: TextStyle(
//               fontSize: context.titleSmall,
//               fontWeight: FontWeight.w600,
//               color: Colors.red,
//             ),
//           ),
//           SizedBox(height: context.gapXSmall),
//           Text(
//             message,
//             style: TextStyle(
//               fontSize: context.bodySmall,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptySection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(
//         horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
//         vertical: context.hp(2),
//       ),
//       color: const Color(0xfff7f7f7),
//       child: Text(
//         'No services information available at the moment.',
//         style: TextStyle(
//           fontSize: context.bodyMedium,
//           color: Colors.grey.shade600,
//         ),
//       ),
//     );
//   }
// }

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
  @override
  void initState() {
    super.initState();
    // Load general settings data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GeneralSettingsBloc>().add(
          const LoadGeneralSettings(domain: 'thewandernova.com'),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        // Handle loading state
        if (state is GeneralSettingsLoading ||
            state is GeneralSettingsInitial) {
          return _buildLoadingSections(context);
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

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.isDesktop ? context.wp(8) : context.wp(4),
            vertical: context.hp(4),
          ),
          color: const Color(0xfff7f7f7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use grid layout for desktop, single column for mobile/tablet
              if (context.isDesktop && moreLinks.length >= 2) {
                return _buildGridSections(context, moreLinks, constraints);
              } else {
                return _buildVerticalSections(context, moreLinks);
              }
            },
          ),
        );
      },
    );
  }

  /// Grid layout for desktop
  Widget _buildGridSections(
    BuildContext context,
    List<MoreLinkEntity> sections,
    BoxConstraints constraints,
  ) {
    // Calculate number of columns based on content count
    int crossAxisCount = sections.length >= 3
        ? 3
        : (sections.length == 2 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: context.gapLarge,
        mainAxisSpacing: context.gapXLarge,
        childAspectRatio: 1.1, // Adjust based on your content needs
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, sections[index], index);
      },
    );
  }

  /// Vertical scrollable layout for mobile/tablet
  Widget _buildVerticalSections(
    BuildContext context,
    List<MoreLinkEntity> sections,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return _buildServiceListItem(context, sections[index], index);
      },
    );
  }

  /// Service card for desktop
  Widget _buildServiceCard(
    BuildContext context,
    MoreLinkEntity service,
    int index,
  ) {
    return Container(
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Title with icon
          Row(
            children: [
              Expanded(
                child: Text(
                  service.title,
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Service Content
          Expanded(
            child: Text(
              service.text,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 6,
            ),
          ),

          // Optional: Read more button for longer content
          if (service.text.length > 200)
            Padding(
              padding: EdgeInsets.only(top: context.gapMedium),
              child: TextButton(
                onPressed: () => _showFullContentDialog(context, service),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read More',
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: const Color(0xff004b6b),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.gapXSmall),
                    Icon(
                      Icons.arrow_forward,
                      size: context.iconXSmall,
                      color: const Color(0xff004b6b),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Service list item for mobile/tablet
  Widget _buildServiceListItem(
    BuildContext context,
    MoreLinkEntity service,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header
          Row(
            children: [
              Expanded(
                child: Text(
                  service.title,
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Service Content
          Text(
            service.text,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),

          // Read more for mobile if content is long
          if (service.text.length > 300)
            Padding(
              padding: EdgeInsets.only(top: context.gapSmall),
              child: TextButton(
                onPressed: () => _showFullContentDialog(context, service),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Read More →',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: const Color(0xff004b6b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Separator (except for last item)
          if (index !=
              (context.read<GeneralSettingsBloc>().state
                          as GeneralSettingsLoaded)
                      .generalSettings
                      .moreLinksContent
                      .length -
                  1)
            Padding(
              padding: EdgeInsets.only(top: context.gapXLarge),
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }

  /// Dialog to show full content
  void _showFullContentDialog(BuildContext context, MoreLinkEntity service) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        ),
        child: Container(
          width: context.isDesktop ? context.wp(50) : context.wp(90),
          constraints: BoxConstraints(maxHeight: context.hp(80)),
          padding: EdgeInsets.all(context.gapLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: TextStyle(
                        fontSize: context.titleLarge,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.gapMedium),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    service.text,
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
      color: const Color(0xfff7f7f7),
      child: context.isDesktop
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: context.gapLarge,
                mainAxisSpacing: context.gapXLarge,
                childAspectRatio: 1.1,
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
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.iconMedium,
                height: context.iconMedium,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(
                    context.borderRadiusSmall,
                  ),
                ),
              ),
              SizedBox(width: context.gapSmall),
              Expanded(
                child: Container(
                  height: context.titleMedium,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),
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
          Row(
            children: [
              Container(
                width: context.iconSmall,
                height: context.iconSmall,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(
                    context.borderRadiusSmall,
                  ),
                ),
              ),
              SizedBox(width: context.gapSmall),
              Expanded(
                child: Container(
                  height: context.titleLarge,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Container(height: context.hp(10), color: Colors.grey.shade300),
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
      color: const Color(0xfff7f7f7),
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
              'Failed to load services',
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
                context.read<GeneralSettingsBloc>().add(
                  const LoadGeneralSettings(domain: 'thewandernova.com'),
                );
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
      color: const Color(0xfff7f7f7),
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
              'No services information available at the moment.',
              style: TextStyle(
                fontSize: context.bodyLarge,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
