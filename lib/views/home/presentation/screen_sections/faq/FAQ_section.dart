import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection>
    with TickerProviderStateMixin {
  int? expandedIndex;

  final List<Map<String, String>> faqs = [
    {
      "q": "What destinations do you offer travel packages for?",
      "a":
      "We offer travel packages for domestic and international destinations including Dubai, Singapore, Bali, Europe, and more."
    },
    {
      "q": "How can I book a travel package with Wander Nova?",
      "a":
      "You can book directly through our website or contact our support team for personalized assistance."
    },
    {
      "q": "Do your travel packages include flights?",
      "a":
      "Yes, most of our packages include flights, accommodation, and transfers."
    },
    {
      "q": "Can I customize my travel package?",
      "a":
      "Absolutely! You can customize destinations, hotels, transport, and activities."
    },
    {
      "q": "What payment methods do you accept?",
      "a":
      "We accept credit/debit cards, UPI, net banking, and international payments."
    },
    {
      "q": "Do you provide visa assistance?",
      "a":
      "Yes, we assist with visa documentation and application processes."
    },
    {
      "q": "Can I cancel or reschedule my booking?",
      "a":
      "Yes, cancellations and rescheduling are allowed based on our policy."
    },
  ];

  void toggle(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final isOpen = expandedIndex == index;

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
                            faqs[index]['q']!,
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
                        padding: EdgeInsets.fromLTRB(context.wp(4), 0, context.wp(4), context.hp(2)),
                        child: Text(
                          faqs[index]['a']!,
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
  }
}