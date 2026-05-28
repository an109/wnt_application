import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/travel_stories/presentation/screen/travel_stories_detail_screen.dart';
import '../../domain/entities/travel_stories_entity.dart';
import '../bloc/travel_stories_bloc.dart';
import '../bloc/travel_stories_event.dart';
import '../bloc/travel_stories_state.dart';
import 'all_travel_stories.dart';


class TravelStoriesSection extends StatefulWidget {
  const TravelStoriesSection({super.key});

  @override
  State<TravelStoriesSection> createState() => _TravelStoriesSectionState();
}

class _TravelStoriesSectionState extends State<TravelStoriesSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TravelStoriesBloc>().add(
          const GetTravelStoriesEvent(
            status: 'published',
            domain: 'thewandernova.com',
            limit: 8,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelStoriesBloc, TravelStoriesState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE ROW WITH SEE ALL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Travel Stories",
                    style: TextStyle(
                      fontSize: context.titleLarge,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      print('View all travel stories tapped');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllTravelStoriesScreen(),
                          ),
                        );
                    },
                    child: Text(
                      "See All",
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.hp(3)),

              /// HORIZONTAL SCROLLABLE CONTENT
              if (state is TravelStoriesLoading)
                _buildHorizontalLoading(context)
              else if (state is TravelStoriesLoaded)
                _buildHorizontalStories(context, state.stories)
              else if (state is TravelStoriesError)
                  _buildHorizontalError(context, state.message)
                else
                  _buildHorizontalEmpty(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLoading(BuildContext context) {
    return SizedBox(
      height: context.isMobile ? context.hp(35) : context.hp(40),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(width: context.wp(3)),
        itemBuilder: (context, index) {
          return _buildHorizontalShimmerCard(context);
        },
      ),
    );
  }

  Widget _buildHorizontalStories(
      BuildContext context,
      List<TravelStoryEntity> stories,
      ) {
    if (stories.isEmpty) {
      return _buildHorizontalEmpty(context);
    }

    return SizedBox(
      height: context.isMobile ? context.hp(35) : context.hp(40),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(width: context.wp(3)),
        itemBuilder: (context, index) {
          final story = stories[index];
          return _HorizontalTravelStoryCard(
            title: story.title,
            imageUrl: story.featuredImageUrl ?? story.headerImageUrl,
            excerpt: story.excerpt,
            onTap: () => _onStoryTap(context, story),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalError(BuildContext context, String message) {
    print('Travel Stories Error: $message');
    return SizedBox(
      height: context.hp(25),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: context.iconLarge,
            ),
            SizedBox(height: context.hp(1)),
            Text(
              'Failed to load stories',
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.hp(1.5)),
            ElevatedButton(
              onPressed: () {
                context.read<TravelStoriesBloc>().add(
                  const GetTravelStoriesEvent(
                    status: 'published',
                    domain: 'thewandernova.com',
                    limit: 8,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(6),
                  vertical: context.hp(1),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalEmpty(BuildContext context) {
    return SizedBox(
      height: context.hp(25),
      child: Center(
        child: Text(
          'No travel stories available',
          style: TextStyle(
            fontSize: context.bodyMedium,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalShimmerCard(BuildContext context) {
    final cardWidth = context.isMobile ? context.wp(70) : context.wp(50);
    final cardHeight = context.isMobile ? context.hp(30) : context.hp(35);

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadius),
        color: Colors.grey.shade300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade400,
              ),
            ),
            Positioned(
              left: context.wp(3),
              right: context.wp(3),
              bottom: context.hp(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: context.hp(4),
                    width: context.wp(40),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.hp(1)),
                  Container(
                    height: context.hp(2),
                    width: context.wp(30),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStoryTap(BuildContext context, TravelStoryEntity story) {
    print('Travel Story Selected: ${story.title}');
    print('Story Slug: ${story.slug}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelStoryDetailScreen(slug: story.slug),
      ),
    );
  }
}

class _HorizontalTravelStoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? excerpt;
  final VoidCallback onTap;

  const _HorizontalTravelStoryCard({
    required this.title,
    required this.imageUrl,
    this.excerpt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = context.isMobile ? context.wp(70) : context.wp(50);
    final cardHeight = context.isMobile ? context.hp(30) : context.hp(35);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Stack(
            children: [
              /// IMAGE
              Positioned.fill(
                child: _buildStoryImage(context),
              ),

              /// DARK OVERLAY
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),

              /// CONTENT
              Positioned(
                left: context.wp(3),
                right: context.wp(3),
                bottom: context.hp(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (excerpt != null && excerpt!.isNotEmpty) ...[
                      SizedBox(height: context.hp(0.5)),
                      Text(
                        excerpt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: context.bodySmall,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryImage(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey.shade400,
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade600,
          size: context.iconLarge,
        ),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade300,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Image Load Error: $error');
        return Container(
          color: Colors.grey.shade400,
          child: Icon(
            Icons.broken_image,
            color: Colors.grey.shade600,
            size: context.iconLarge,
          ),
        );
      },
    );
  }
}