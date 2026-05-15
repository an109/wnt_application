import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class VisaSearchCard extends StatelessWidget {
  const VisaSearchCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [


        /// SINGLE SEARCH BAR
        Container(
          height: context.isMobile ? 58 : 64,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),

            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),

          child: Row(
            children: [

              SizedBox(width: context.gapMedium),

              Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: context.iconMedium,
              ),

              SizedBox(width: context.gapSmall),

              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                    "Search destination country",

                    hintStyle: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade500,
                    ),

                    border: InputBorder.none,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(
                  context.gapSmall,
                ),

                child: SizedBox(
                  height: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {},

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xff00A19A),

                      elevation: 0,

                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(2),
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(60),
                      ),
                    ),

                    child: Icon(Icons.arrow_forward_sharp, color: Colors.white,)
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topButton(
      BuildContext context, {
        required String title,
        required bool isSelected,
      }) {

    return Container(
      height: context.buttonHeight,

      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xff0B5ED7)
            : Colors.grey.shade100,

        borderRadius: BorderRadius.circular(12),
      ),

      alignment: Alignment.center,

      child: Text(
        title,

        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.black87,

          fontWeight: FontWeight.w600,
          fontSize: context.bodyMedium,
        ),
      ),
    );
  }
}