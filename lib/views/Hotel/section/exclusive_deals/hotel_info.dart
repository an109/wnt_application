import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class HotelInfoSection extends StatefulWidget {
  const HotelInfoSection({super.key});

  @override
  State<HotelInfoSection> createState() => _HotelInfoSectionState();
}

class _HotelInfoSectionState extends State<HotelInfoSection> {
  int expandedIndex = 0;

  final List<Map<String, String>> faqData = [
    {
      "title": "How to book hotels on WANDER NOVA?",
      "content":
      "Search destination, select check-in/check-out dates, choose rooms and guests, compare hotels, and complete booking securely.",
    },
    {
      "title": "Why book hotels on WANDER NOVA?",
      "content":
      "Get exclusive prices, verified stays, smooth booking experience, responsive support, and easy cancellation options.",
    },
    {
      "title": "WANDER NOVA On Mobile",
      "content":
      "Book hotels faster using the WANDER NOVA mobile app with seamless navigation and instant confirmations.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Column(
            children: List.generate(
              faqData.length,
                  (index) => _buildAccordionItem(
                context,
                index,
                faqData[index],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccordionItem(
      BuildContext context,
      int index,
      Map<String, String> item,
      ) {
    final isExpanded = expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isExpanded
            ? Colors.white
            : const Color(0xFF1F3EA3),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),

      child: Column(
        children: [

          /// HEADER
          InkWell(
            onTap: () {
              setState(() {
                expandedIndex = isExpanded ? -1 : index;
              });
            },

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(5),
                vertical: context.hp(2.2),
              ),

              child: Row(
                children: [

                  /// TITLE
                  Expanded(
                    child: Text(
                      item["title"]!,
                      style: TextStyle(
                        color: isExpanded
                            ? Colors.black87
                            : Colors.white,
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),

                  SizedBox(width: context.gapSmall),

                  /// ICON
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded
                          ? Colors.black87
                          : Colors.white,
                      size: context.iconLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// EXPANDED CONTENT
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),

            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(
                context.wp(5),
                0,
                context.wp(5),
                context.hp(3),
              ),

              child: Text(
                item["content"]!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: context.bodyMedium,
                  height: 1.7,
                ),
              ),
            ),

            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}