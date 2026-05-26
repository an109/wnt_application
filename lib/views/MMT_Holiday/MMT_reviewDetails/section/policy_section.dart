import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

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

              /// HANDLE
              Container(
                margin: EdgeInsets.only(top: context.hp(1.2)),
                width: 42,
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
                      'Policies',
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

                      /// TITLE
                      Text(
                        'Package Cancellation Policy',
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: context.hp(1.3)),

                      Text(
                        'Cancellation Possible till 14 Jun.*',
                        style: TextStyle(
                          fontSize: context.titleMedium,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00897B),
                        ),
                      ),

                      SizedBox(height: context.hp(0.5)),

                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: context.bodyLarge,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(
                              text: 'After that Package is ',
                            ),
                            TextSpan(
                              text: 'Non-Refundable.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.hp(2.5)),

                      Text(
                        'Package Cancellation Policy',
                        style: TextStyle(
                          fontSize: context.bodyLarge,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: context.hp(2.5)),

                      /// TIMELINE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// LEFT LINE
                          Column(
                            children: [

                              Container(
                                width: 30,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7CB342),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),

                              Container(
                                width: 4,
                                height: 90,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF7CB342),
                                      Color(0xFFFFA726),
                                    ],
                                  ),
                                ),
                              ),

                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFA726),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: context.wp(4)),

                          /// RIGHT TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  'Till 14 Jun 26',
                                  style: TextStyle(
                                    fontSize: context.titleMedium,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF00796B),
                                  ),
                                ),

                                SizedBox(height: context.hp(0.7)),

                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: context.bodyLarge,
                                      color: Colors.black,
                                      height: 1.4,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: '₹ 1 ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'per person\nCancellation fee',
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: context.hp(4)),

                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: context.titleMedium,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'After ',
                                        style: TextStyle(
                                          color: Color(0xFFE67E22),
                                        ),
                                      ),
                                      TextSpan(
                                        text: '14 Jun 26',
                                        style: TextStyle(
                                          color: Color(0xFFD84315),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: context.hp(0.7)),

                                Text(
                                  'Non-Refundable.\nCancellation will not be allowed.',
                                  style: TextStyle(
                                    fontSize: context.bodyLarge,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.hp(3)),

                      /// GREY CARD
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.wp(5)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [

                            _bullet(
                              context,
                              'These are non-refundable amounts as per the current components attached.',
                            ),

                            _bullet(
                              context,
                              'Please check the exact cancellation and date change policy on the review page before proceeding further.',
                            ),

                            _bullet(
                              context,
                              'Please note, TCS once collected cannot be refunded in case of any cancellation / modification.',
                            ),

                            _bullet(
                              context,
                              'Cancellation charges shown is exclusive of all taxes.',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.hp(4)),

                      Text(
                        'Package Date Change Policy',
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: context.hp(1.3)),

                      Text(
                        'Date Change Possible till 14 Jun.*',
                        style: TextStyle(
                          fontSize: context.titleMedium,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00897B),
                        ),
                      ),

                      SizedBox(height: context.hp(0.5)),

                      Text(
                        'After that Package date cannot be changed.',
                        style: TextStyle(
                          fontSize: context.bodyLarge,
                          color: Colors.black87,
                        ),
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

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(2)),
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
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}