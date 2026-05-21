import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../../MainApi/presentation/bloc/general_settings_state.dart';

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> with TickerProviderStateMixin {
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    // Load FAQ list when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GeneralSettingsBloc>()
            .add(const LoadFaqList(domain: 'thewandernova.com'));
      }
    });
  }

  void toggle(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        // Handle loading state
        if (state is GeneralSettingsLoading || state is GeneralSettingsInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle error state
        if (state is GeneralSettingsError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(2)),
            child: Text(
              'Failed to load FAQs: ${state.message}',
              style: TextStyle(
                color: Colors.red,
                fontSize: context.bodySmall,
              ),
            ),
          );
        }

        // Extract FAQ list from state
        List<FaqEntity> faqList = [];

        if (state is FaqListLoaded) {
          faqList = state.faqList;
        } else if (state is PopularDestinationsDataLoaded) {
          faqList = state.faqList;
        }

        // Show message if no FAQs available
        if (faqList.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(3)),
            child: Text(
              'No FAQs available at the moment.',
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1.5)),
              child: Text(
                "Frequently asked questions",
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqList.length,
              itemBuilder: (context, index) {
                final isOpen = expandedIndex == index;
                final faq = faqList[index];

                return Column(
                  children: [
                    InkWell(
                      onTap: () => toggle(index),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.wp(4),
                          vertical: context.hp(2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                faq.question,
                                style: TextStyle(
                                  fontSize: context.bodyMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: isOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: context.iconMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: isOpen
                              ? const BoxConstraints()
                              : const BoxConstraints(maxHeight: 0),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.wp(4),
                              0,
                              context.wp(4),
                              context.hp(2),
                            ),
                            child: Text(
                              faq.answer,
                              style: TextStyle(
                                fontSize: context.bodySmall,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[300],
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}