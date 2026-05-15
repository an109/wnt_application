import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class VisaProcessSection extends StatelessWidget {
  const VisaProcessSection({super.key});

  @override
  Widget build(BuildContext context) {

    final steps = [

      {
        "icon": Icons.computer_outlined,
        "title": "Submit documents and pay online",
        "color": Color(0xff2747A3),
      },

      {
        "icon": Icons.check_circle_outline,
        "title":
        "We verify documents & process your Visa application",
        "color": Color(0xff22A652),
      },

      {
        "icon": Icons.thumb_up_alt_outlined,
        "title": "Receive Visa",
        "color": Color(0xff1DA1F2),
      },
    ];

    return Container(
      width: double.infinity,

      color: const Color(0xffD6B487),

      padding: EdgeInsets.symmetric(
        horizontal: context.wp(5),
        vertical: context.hp(1),
      ),

      child: Column(
        children: [

          /// TITLE
          Text(
            "Applying With Wander Nova Is Simple",

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: context.isMobile
                  ? context.sp(20)
                  : context.sp(24),

              fontWeight: FontWeight.w800,
              color: const Color(0xff132238),
            ),
          ),

          SizedBox(height: context.hp(0)),

          /// MOBILE
          if (context.isMobile)
            Column(
              children: List.generate(
                steps.length,
                    (index) {

                  final item = steps[index];

                  return Column(
                    children: [

                      _mobileStep(
                        context,
                        icon: item["icon"] as IconData,
                        title: item["title"] as String,
                        color: item["color"] as Color,
                      ),

                      if (index != steps.length - 1)
                        Container(
                          height: 45,
                          width: 1.5,
                          color:
                          const Color(0xffC8A06B),
                        ),
                    ],
                  );
                },
              ),
            ),

          /// DESKTOP / TABLET
          if (!context.isMobile)
            SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,

                children: [

                  /// HORIZONTAL LINE
                  Positioned(
                    top: 34,

                    left: context.wp(12),
                    right: context.wp(12),

                    child: Container(
                      height: 2,
                      color: const Color(0xffC8A06B),
                    ),
                  ),

                  /// STEPS
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: List.generate(
                      steps.length,
                          (index) {

                        final item = steps[index];

                        return Expanded(
                          child: _desktopStep(
                            context,

                            icon:
                            item["icon"] as IconData,

                            title:
                            item["title"] as String,

                            color:
                            item["color"] as Color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// =========================================
  /// DESKTOP STEP
  /// =========================================

  Widget _desktopStep(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
      }) {

    return Column(
      children: [

        /// ICON CIRCLE
        Container(
          height: 72,
          width: 72,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.white,
              width: 6,
            ),

            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Icon(
            icon,
            size: 34,
            color: color,
          ),
        ),

        SizedBox(height: context.hp(0)),

        /// WHITE DOT
        Container(
          height: 13,
          width: 13,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
        ),

        SizedBox(height: context.hp(0)),

        /// TEXT
        SizedBox(
          width: context.wp(22),

          child: Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: context.bodyLarge,
              fontWeight: FontWeight.w500,
              color: const Color(0xff111827),
            ),
          ),
        ),
      ],
    );
  }

  /// =========================================
  /// MOBILE STEP
  /// =========================================

  Widget _mobileStep(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
      }) {

    return Column(
      children: [

        Container(
          height: 70,
          width: 70,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.white,
              width: 5,
            ),

            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),

        SizedBox(height: context.hp(0)),

        Container(
          height: 12,
          width: 12,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
        ),

        SizedBox(height: context.hp(0)),

        SizedBox(
          width: context.wp(70),

          child: Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: context.bodyMedium,
              fontWeight: FontWeight.w500,
              color: const Color(0xff111827),
            ),
          ),
        ),

        SizedBox(height: context.hp(0)),
      ],
    );
  }
}