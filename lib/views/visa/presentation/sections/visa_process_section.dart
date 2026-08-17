import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class VisaProcessSection extends StatelessWidget {
  const VisaProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1769F6);
    const textDark = Color(0xFF071638);

    final steps = [
      {
        "icon": Icons.computer_outlined,
        "title": "Submit documents and pay online",
        "color": primaryBlue,
      },

      {
        "icon": Icons.check_circle_outline,
        "title": "We verify documents & process your Visa application",
        "color": Color(0xff22A652),
      },

      {
        "icon": Icons.thumb_up_alt_outlined,
        "title": "Receive Visa",
        "color": primaryBlue,
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F6FC),

      padding: EdgeInsets.symmetric(
        horizontal: context.w(18),
        vertical: context.h(24),
      ),

      child: Column(
        children: [
          /// TITLE
          Text(
            "Applying With Wander Nova Is Simple",

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: context.isMobile ? context.fs(20) : context.fs(24),
              fontWeight: FontWeight.w800,
              color: textDark,
              height: 1.18,
            ),
          ),

          SizedBox(height: context.h(18)),

          /// MOBILE
          if (context.isMobile)
            Container(
              padding: EdgeInsets.all(context.w(14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(22)),
                border: Border.all(color: const Color(0xFFE6EAF2)),
                boxShadow: [
                  BoxShadow(
                    color: textDark.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(steps.length, (index) {
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
                          height: context.h(20),
                          width: 1,
                          margin: EdgeInsets.symmetric(vertical: context.h(4)),
                          color: const Color(0xFFDCE7F8),
                        ),
                    ],
                  );
                }),
              ),
            ),

          /// DESKTOP / TABLET
          if (!context.isMobile)
            SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,

                children: [
                  Positioned(
                    top: 28,

                    left: context.wp(12),
                    right: context.wp(12),

                    child: Container(height: 2, color: const Color(0xFFDCE7F8)),
                  ),

                  /// STEPS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: List.generate(steps.length, (index) {
                      final item = steps[index];

                      return Expanded(
                        child: _desktopStep(
                          context,

                          icon: item["icon"] as IconData,

                          title: item["title"] as String,

                          color: item["color"] as Color,
                        ),
                      );
                    }),
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
          height: context.w(58),
          width: context.w(58),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(color: Colors.white, width: 5),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Icon(icon, size: context.w(27), color: color),
        ),

        SizedBox(height: context.hp(0)),

        /// WHITE DOT
        Container(
          height: context.w(10),
          width: context.w(10),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(color: Colors.grey.shade300),
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
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
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
          height: context.w(54),
          width: context.w(54),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(color: Colors.white, width: 4),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Icon(icon, size: context.w(25), color: color),
        ),

        SizedBox(height: context.hp(0)),

        Container(
          height: context.w(9),
          width: context.w(9),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(color: Colors.grey.shade300),
          ),
        ),

        SizedBox(height: context.hp(0)),

        SizedBox(
          width: context.w(250),

          child: Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w600,
              color: const Color(0xff111827),
            ),
          ),
        ),

        SizedBox(height: context.hp(0)),
      ],
    );
  }
}
