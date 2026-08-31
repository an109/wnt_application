import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

class SlidingSearchSection extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onHide;
  final String? initialSearchText;

  const SlidingSearchSection({
    super.key,
    required this.isVisible,
    this.onHide,
    this.initialSearchText,
  });

  @override
  State<SlidingSearchSection> createState() => _SlidingSearchSectionState();
}

class _SlidingSearchSectionState extends State<SlidingSearchSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isVisible) {
      _controller.forward();
      // Focus the search field after animation completes
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _searchFocusNode.requestFocus();
        }
      });
    }

    if (widget.initialSearchText != null) {
      _searchController.text = widget.initialSearchText!;
    }
  }

  @override
  void didUpdateWidget(SlidingSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
      // Focus the search field after animation completes
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _searchFocusNode.requestFocus();
        }
      });
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _searchFocusNode.unfocus();
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed) {
          return const SizedBox.shrink();
        }

        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: child),
        );
      },
      child: _buildSearchSection(context),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return GestureDetector(
      // onTap: widget.onHide,
      onTap: () {
        widget.onHide?.call();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
        child: Column(
          children: [
            // Search card - touches top, left and right edges
            Container(
              width: double.infinity,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.fromLTRB(
                context.w(16),
                topInset + context.h(16),
                context.w(16),
                context.h(16),
              ),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE3EFFF),
                    Colors.white,
                  ],
                ),
                // borderRadius: BorderRadius.zero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(context.r(24)),
                  bottomRight: Radius.circular(context.r(24)),
                ),
              ),
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expanded Search Bar - matches hero style exactly
                    Container(
                      height: context.h(44),
                      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(50)),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/Newgif/search.gif',
                              width: context.w(18),
                              height: context.w(18),
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(width: context.w(12)),
                          Expanded(
                            child: TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search places',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: context.fs(14),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w400,
                              ),
                              onSubmitted: (value) {
                                // Handle search submission
                                widget.onHide?.call();
                              },
                            ),
                          ),
                          Image.asset(
                            'assets/NewIcons/micHD.png',
                            width: context.w(14),
                            height: context.w(14),
                            color: AppColors.AppBlue,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.h(30)),

                    // TRENDING PROMPTS section (same as before)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(16),
                        vertical: context.h(12),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.r(24)),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: context.h(12),
                            offset: Offset(0, -context.h(19)),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRENDING PROMPTS',
                            style: TextStyle(
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: context.h(20)),

                          // FLIGHTS
                          _buildTrendingItem(
                            icon: 'assets/NewIcons/prompt1.png',
                            categoryIcon: Icons.flight,
                            fallbackIcon: Icons.flight,
                            category: 'FLIGHTS',
                            categoryColor: AppColors.AppBlue,
                            title: 'Cheapest flights to Goa',
                            onTap: widget.onHide,
                          ),
                          SizedBox(height: context.h(20)),

                          // TRIP PLANNING
                          _buildTrendingItem(
                            icon: 'assets/NewIcons/prompt2.png',
                            categoryIcon: Icons.account_balance_sharp,
                            fallbackIcon: Icons.travel_explore,
                            category: 'TRIP PLANNING',
                            categoryColor: AppColors.AppBlue,
                            title: 'Plan an itinerary covering Goa in 5 days',
                            onTap: widget.onHide,
                          ),
                          SizedBox(height: context.h(20)),

                          // HOTELS
                          _buildTrendingItem(
                            icon: 'assets/NewIcons/prompt3.png',
                            categoryIcon: Icons.hotel_outlined,
                            fallbackIcon: Icons.hotel,
                            category: 'HOTELS',
                            categoryColor: AppColors.AppBlue,
                            title:
                                'Recommend some iconic palace hotels to stay in Udaipur',
                            onTap: widget.onHide,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingItem({
    required String icon,
    required IconData categoryIcon,
    required IconData fallbackIcon,
    required String category,
    required Color categoryColor,
    required String title,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: context.w(44),
            height: context.w(44),
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(12),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.black.withOpacity(0.25),
            //       blurRadius: 8,
            //       offset: const Offset(0, 2),
            //     ),
            //   ],
            // ),
            child: Center(
              child: Image.asset(
                icon,
                width: context.w(28),
                height: context.w(28),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(fallbackIcon, color: categoryColor, size: context.w(24));
                },
              ),
            ),
          ),
          SizedBox(width: context.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   category,
                //   style: TextStyle(
                //     fontSize: 10,
                //     fontWeight: FontWeight.w700,
                //     color: categoryColor,
                //     letterSpacing: 0.5,
                //   ),
                // ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(2),
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF00A1E4).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(context.r(12)),
                    // border: Border.all(
                    //   color: AppColors.AppBlue.withOpacity(0.15),
                    // ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        categoryIcon,
                        size: context.w(14),
                        color: AppColors.AppBlue,
                      ),
                      SizedBox(width: context.w(5)),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w700,
                          color: AppColors.AppBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
