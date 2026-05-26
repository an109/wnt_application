import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [

              /// TOP HANDLE
              Container(
                margin: EdgeInsets.only(top: context.hp(1.2)),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              /// HEADER
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(2),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back,
                          size: 28,
                        ),
                      ),
                    ),

                    SizedBox(width: context.wp(3)),

                    Text(
                      'Terms And Conditions',
                      style: TextStyle(
                        fontSize: context.titleLarge,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),

              /// CONTENT
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(5),
                    vertical: context.hp(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// EXCLUSIONS
                      _sectionTitle(
                        context,
                        'Exclusions',
                      ),

                      SizedBox(height: context.hp(1.5)),

                      _bullet(
                        context,
                        'Expenses of personal nature',
                      ),

                      _bullet(
                        context,
                        'Mentioned cost is not valid between 6 pm and 8 am',
                      ),

                      _bullet(
                        context,
                        'Anything not mentioned under inclusions',
                      ),

                      _bullet(
                        context,
                        'Package price does not include Gala dinner charges applicable on Christmas and New Year\'s Eve',
                      ),

                      SizedBox(height: context.hp(3)),

                      /// TERMS
                      _sectionTitle(
                        context,
                        'Terms And Conditions',
                      ),

                      SizedBox(height: context.hp(1.5)),

                      _bullet(
                        context,
                        'Standard check-in time at the hotel is normally 2:00 pm and check-out is 11:00 am. An early check-in, or a late check-out is solely based on the discretion of the hotel.',
                      ),

                      _bullet(
                        context,
                        'A maximum of 3 adults are allowed in one room. The third occupant shall be provided a mattress/rollaway bed.',
                      ),

                      _bullet(
                        context,
                        'The itinerary is fixed and cannot be modified. Transportation shall be provided as per the itinerary and will not be at disposal.',
                      ),

                      _bullet(
                        context,
                        'Also, for any activity which is complimentary and not charged to MMT & guest, no refund will be processed.',
                      ),

                      _bullet(
                        context,
                        'AC will not be functional anywhere in cool or hilly areas.',
                      ),

                      _bullet(
                        context,
                        'Entrance fee, parking and guide charges are not included in the packages.',
                      ),

                      _bullet(
                        context,
                        'Booking rates are subject to change without prior notice.',
                      ),

                      _bullet(
                        context,
                        'Airline seats and hotel rooms are subject to availability at the time of booking.',
                      ),

                      SizedBox(height: context.hp(5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.titleLarge,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(1.7)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: EdgeInsets.only(
              top: context.hp(0.7),
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),

          SizedBox(width: context.wp(3)),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.bodyLarge,
                height: 1.45,
                color: const Color(0xFF4A4A4A),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}