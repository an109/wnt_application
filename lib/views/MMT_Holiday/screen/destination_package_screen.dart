import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';
import '../MMT_reviewDetails/screen/paackage_details_screen.dart';
import '../sections/cutomize_trip_dialogue.dart';

class DestinationPackagesScreen extends StatefulWidget {
  final String destination;
  final String packageType;
  final String? origin;


  const DestinationPackagesScreen({
    super.key,
    required this.destination,
    required this.packageType,
    this.origin
  });

  @override
  State<DestinationPackagesScreen> createState() => _DestinationPackagesScreenState();
}

class _DestinationPackagesScreenState extends State<DestinationPackagesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  double _headerHeight = 250;

  // Filter selection animation
  int _selectedFilterIndex = 0;

  // Package card visibility animation
  List<bool> _cardVisible = [false, false];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Add scroll listener for collapsing header
    _scrollController.addListener(_onScroll);

    // Start animations
    _animationController.forward();

    // Animate cards with delay
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _cardVisible[0] = true;
        });
      }
    });

    Future.delayed(Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _cardVisible[1] = true;
        });
      }
    });
  }

  void _onScroll() {
    setState(() {
      _headerHeight = 250 - (_scrollController.offset * 0.5);
      if (_headerHeight < 120) _headerHeight = 120;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Animated Header with Collapsing Effect
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                return _buildAnimatedHeader(context);
              },
            ),
          ),

          // Travel Details Section with Slide Animation
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildTravelDetails(context),
              ),
            ),
          ),

          // Filter Chips with Scale Animation
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildFilterChips(context),
            ),
          ),

          // Package Cards
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(4),
              vertical: context.gapMedium,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 500),
                      opacity: _cardVisible[0] ? 1.0 : 0.0,
                      child: Transform.translate(
                        offset: Offset(0, _cardVisible[0] ? 0 : 50),
                        child: _buildPackageCard(context),
                      ),
                    );
                  },
                ),
                SizedBox(height: context.gapMedium),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 500),
                      opacity: _cardVisible[1] ? 1.0 : 0.0,
                      child: Transform.translate(
                        offset: Offset(0, _cardVisible[1] ? 0 : 50),
                        child: _buildPackageCard(context, isSecondCard: true),
                      ),
                    );
                  },
                ),
                SizedBox(height: context.hp(15)),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAnimatedCustomiseTripButton(context),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {

    final originText = widget.origin != null && widget.origin!.isNotEmpty
        ? '${widget.origin} to'
        : '';

    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://picsum.photos/seed/kashmir-header/800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Animated gradient overlay
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(
                      _headerHeight > 150 ? 0.7 : 0.9
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Animated text size based on scroll
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: _headerHeight > 150 ? context.sp(14) : context.sp(12),
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    // child: Text('New Delhi to'),
                    child: Text('$originText'),
                  ),
                  SizedBox(height: context.gapXSmall),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: _headerHeight > 150 ? context.sp(32) : context.sp(24),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(widget.destination),
                  ),
                  SizedBox(height: _headerHeight > 150 ? context.gapMedium : context.gapSmall),
                ],
              ),
            ),
          ),
          // Back button with animation
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCustomiseTripButton(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9C27B0),
                    Color(0xFF673AB7),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9C27B0).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    showCustomTripDialog(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(4),
                      vertical: context.hp(1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.gapSmall),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.white,
                            size: context.iconSmall,
                          ),
                        ),
                        SizedBox(width: context.gapSmall),
                        Text(
                          'Customise my trip',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: context.bodyMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTravelDetails(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(context.wp(4)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Travel Date',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: context.gapXXSmall),
                Text(
                  '2 Adults, 1 Room',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // Add edit animation
                _animateEditButton(context);
              },
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200),
                builder: (context, double value, child) {
                  return Transform.rotate(
                    angle: value * 0.5,
                    child: Container(
                      width: context.wp(10),
                      height: context.wp(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: context.sp(16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _animateEditButton(BuildContext context) async {
    // Add your edit functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit travel details')),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Container(
      color: AppColors.lightBg,
      padding: EdgeInsets.symmetric(vertical: context.gapMedium),
      child: SizedBox(
          height: context.h(65),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          children: [
            _buildAnimatedFilterChip(
              context,
              'All Packages',
              '225 Packages',
              index: 0,
            ),
            SizedBox(width: context.gapMedium),
            _buildAnimatedFilterChip(
              context,
              'Group Tours',
              '5 Packages',
              index: 1,
            ),
            SizedBox(width: context.gapMedium),
            _buildAnimatedFilterChip(
              context,
              'Luxurious Stays',
              '35 Packages',
              index: 2,
            ),
            SizedBox(width: context.gapMedium),
            _buildAnimatedFilterChip(
              context,
              'Honeymoon',
              '18 Packages',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFilterChip(
      BuildContext context,
      String title,
      String subtitle, {
        required int index,
      }) {
    final isSelected = _selectedFilterIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
        // Add haptic feedback
        _animateFilterChip(context);
      },
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: isSelected ? 1.05 : 1.0),
        duration: Duration(milliseconds: 200),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.gapSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _animateFilterChip(BuildContext context) {
    // Add haptic feedback (requires vibration package)
    // HapticFeedback.lightImpact();
  }

  Widget _buildPackageCard(BuildContext context, {bool isSecondCard = false}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package Image with Badge and Hover effect
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        _showPackageOptionsBottomSheet(context);
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(context.borderRadiusLarge),
                            ),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 1.0, end: 1.0),
                              duration: Duration(milliseconds: 300),
                              builder: (context, double scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Image.network(
                                    isSecondCard
                                        ? 'https://picsum.photos/seed/kashmir2/800'
                                        : 'https://picsum.photos/seed/kashmir1/800',
                                    height: context.hp(22),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: context.gapMedium,
                            right: context.gapMedium,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 600),
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.wp(3),
                                      vertical: context.gapXXSmall,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      '1 More Option',
                                      style: TextStyle(
                                        fontSize: context.bodySmall,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rest of the card content with animations
                  _buildAnimatedCardContent(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showPackageOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: context.isMobile ? 0.42 : 0.36,
          minChildSize: 0.30,
          maxChildSize: 0.45,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(context.borderRadiusLarge),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.all(context.wp(5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      SizedBox(height: context.gapSmall),

                      /// TITLE + CLOSE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Mystical Kashmir Trip with\nHouseboat Stay',
                              style: TextStyle(
                                fontSize: context.headlineSmall,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(context.gapSmall),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: context.iconSmall,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.gapLarge),

                      Text(
                        'Please select an option',
                        style: TextStyle(
                          fontSize: context.bodyLarge,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      SizedBox(height: context.gapLarge),

                      /// WITHOUT FLIGHT CARD
                      _buildOptionCard(
                        context,
                        startFrom: 'Srinagar',
                        title: 'Without Flight',
                        oldPrice: '₹20,030',
                        newPrice: '₹19,113',
                      ),

                      SizedBox(height: context.gapMedium),

                      /// WITH FLIGHT CARD
                      _buildOptionCard(
                        context,
                        startFrom: widget.origin ?? 'Agartala',
                        title: 'With Flight',
                        oldPrice: '₹52,478',
                        newPrice: '₹50,139',
                      ),

                      SizedBox(height: context.hp(3)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required String startFrom,
        required String title,
        required String oldPrice,
        required String newPrice,
      }) {
    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageDetailsScreen(
              packageData: {
                'title': 'Most Wanted Goa Package',
                'duration': '4N / 5D',
                'location': 'Goa',
                'price': 7084,
              },
            ),
          ),
        );

      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.wp(2.8)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            context.borderRadiusMedium,
          ),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [

            /// LEFT SIDE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Starting from - $startFrom',
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  SizedBox(height: context.gapSmall),

                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.titleLarge,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT SIDE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                Text(
                  oldPrice,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.red.shade300,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),

                SizedBox(height: context.gapXXSmall),

                Text(
                  newPrice,
                  style: TextStyle(
                    fontSize: context.headlineSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                Text(
                  'per person',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            SizedBox(width: context.gapMedium),

            Icon(
              Icons.arrow_forward_ios,
              size: context.iconSmall,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCardContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Duration
          Row(
            children: [
              Expanded(
                child: Text(
                  'Amazing Kashmir Vacay with Gulmarg & Pahalgam',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(3),
                        vertical: context.gapXXSmall,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                      ),
                      child: Text(
                        '6N/7D',
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: context.gapMedium),

          // Itinerary with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildItinerary(context),
          ),

          SizedBox(height: context.gapMedium),

          // Inclusions with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: _buildInclusions(context),
          ),

          SizedBox(height: context.gapMedium),

          // Special Inclusions with staggered animation
          _buildStaggeredSpecialInclusions(context),

          SizedBox(height: context.gapMedium),

          // Price Section with pulse animation on hover
          MouseRegion(
            onEnter: (_) => _animatePriceSection(context, true),
            onExit: (_) => _animatePriceSection(context, false),
            child: _buildAnimatedPriceSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredSpecialInclusions(BuildContext context) {
    final specialInclusions = [
      'Gulmarg Gondola Tickets - Phase 1',
      'Tour of Pahalgam Valley',
      'Visit to Avantipura Ruins, Nishat Bagh, Cheshma Shahi',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specialInclusions.asMap().entries.map((entry) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300),
          // delay: Duration(milliseconds: entry.key * 100),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: EdgeInsets.only(bottom: context.gapSmall),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: context.sp(16),
                      ),
                      SizedBox(width: context.gapSmall),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: context.bodyMedium,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedPriceSection(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: Duration(milliseconds: 200),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.all(context.wp(4)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.lightBg, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book this now by paying',
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 10381.0),
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, double value, child) {
                          return Text(
                            'only ₹${value.toInt()}',
                            style: TextStyle(
                              fontSize: context.titleMedium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 38231.0),
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            return Text(
                              '₹${value.toInt()}',
                              style: TextStyle(
                                fontSize: context.titleLarge,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: context.gapXSmall),
                        Text(
                          '/Person',
                          style: TextStyle(
                            fontSize: context.bodySmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total Price ₹76,462',
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _animatePriceSection(BuildContext context, bool isHovering) {
    // Add price section hover animation logic here
  }

  // Keep the original helper methods
  Widget _buildItinerary(BuildContext context) {
    final itinerary = [
      '1N Srinagar',
      '1N Sonmarg',
      '2N Pahalgam',
      '1N Gulmarg',
      '1N Srinagar',
    ];

    return Wrap(
      spacing: context.gapMedium,
      runSpacing: context.gapSmall,
      children: itinerary.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.gapXSmall),
            Text(
              item,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInclusions(BuildContext context) {
    final inclusions = [
      'Round Trip Flights',
      'Intercity Car Transfers',
      '3 Star Hotels',
      'Airport Transfers',
      '8 Activities',
      'Selected Meals',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: inclusions.sublist(0, 3).map((item) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.gapSmall),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: context.gapXSmall),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: context.bodyMedium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: context.wp(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: inclusions.sublist(3).map((item) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.gapSmall),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: context.gapXSmall),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: context.bodyMedium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}