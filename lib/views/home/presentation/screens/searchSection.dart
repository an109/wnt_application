import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlidingSearchSection extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onHide;

  const SlidingSearchSection({
    super.key,
    required this.isVisible,
    this.onHide,
  });

  @override
  State<SlidingSearchSection> createState() => _SlidingSearchSectionState();
}

class _SlidingSearchSectionState extends State<SlidingSearchSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SlidingSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          ),
        );
      },
      child: _buildSearchSection(context),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    // Prevent taps inside the white card from closing it
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar inside the card (matching Figma)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF), // Light blueish bg like Figma
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF005B7F), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Search places',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(Icons.mic, color: Color(0xFF005B7F), size: 20),
                ],
              ),
            ),

            // TRENDING PROMPTS section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRENDING PROMPTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FLIGHTS
                  _buildTrendingItem(
                    icon: 'assets/NewIcons/HFlight.png',
                    fallbackIcon: Icons.flight,
                    category: 'FLIGHTS',
                    categoryColor: const Color(0xFF56B0FF),
                    title: 'Cheapest flights to Goa',
                    onTap: widget.onHide,
                  ),
                  const SizedBox(height: 20),

                  // TRIP PLANNING
                  _buildTrendingItem(
                    icon: 'assets/NewIcons/holidays.png',
                    fallbackIcon: Icons.travel_explore,
                    category: 'TRIP PLANNING',
                    categoryColor: const Color(0xFF3DFF5A),
                    title: 'Plan an itinerary covering Goa in 5 days',
                    onTap: widget.onHide,
                  ),
                  const SizedBox(height: 20),

                  // HOTELS
                  _buildTrendingItem(
                    icon: 'assets/NewIcons/hotel.png',
                    fallbackIcon: Icons.hotel,
                    category: 'HOTELS',
                    categoryColor: const Color(0xFFFFB411),
                    title: 'Recommend some iconic palace hotels to stay in Udaipur',
                    onTap: widget.onHide,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingItem({
    required String icon,
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
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                icon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(fallbackIcon, color: categoryColor, size: 24);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text content (No container, no arrow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: categoryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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