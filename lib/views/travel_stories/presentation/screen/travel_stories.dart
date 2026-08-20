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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel Stories',
                    style: TextStyle(
                      fontSize: context.fs(24),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Stories from the road, memories for a lifetime',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTravelStoriesScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff005B7F),
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      Icons.arrow_forward,
                      size: context.iconSmall,
                      color: const Color(0xff005B7F),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(20)),

          /// Stories - Horizontal Scroll (RESTORED FUNCTIONALITY)
          BlocBuilder<TravelStoriesBloc, TravelStoriesState>(
            builder: (context, state) {
              if (state is TravelStoriesLoading) {
                return _buildLoadingCarousel(context);
              } else if (state is TravelStoriesLoaded) {
                if (state.stories.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildHorizontalStories(context, state.stories);
              } else if (state is TravelStoriesError) {
                return _buildErrorState(context, state.message);
              }
              return const SizedBox.shrink();
            },
          ),

          SizedBox(height: context.h(32)),
        ],
      ),
    );
  }

  Widget _buildLoadingCarousel(BuildContext context) {
    return SizedBox(
      height: context.h(280),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(width: context.w(16)),
        itemBuilder: (context, index) {
          return _buildShimmerCard(context);
        },
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      width: context.isMobile ? context.wp(70) : context.w(300),
      height: context.h(280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(16)),
        color: Colors.grey.shade300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(16)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.grey.shade400),
            ),
            Positioned(
              left: context.w(16),
              right: context.w(16),
              bottom: context.h(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: context.h(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(context.r(4)),
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  Container(
                    height: context.h(14),
                    width: context.w(150),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(context.r(4)),
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

  Widget _buildHorizontalStories(
      BuildContext context,
      List<TravelStoryEntity> stories,
      ) {
    return SizedBox(
      height: context.h(280),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(width: context.w(16)),
        itemBuilder: (context, index) {
          final story = stories[index];
          return _buildStoryCard(context, story);
        },
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, TravelStoryEntity story) {
    return GestureDetector(
      onTap: () => _onStoryTap(context, story),
      child: Container(
        width: context.isMobile ? context.wp(70) : context.w(300),
        height: context.h(280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Full Image
            ClipRRect(
              borderRadius: BorderRadius.circular(context.r(16)),
              child: SizedBox(
                height: context.h(280),
                width: double.infinity,
                child: _buildStoryImage(story),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Content Overlay at Bottom
            Positioned(
              left: context.w(16),
              right: context.w(16),
              bottom: context.h(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Title
                  Text(
                    story.title,
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.h(8)),
                  // Excerpt
                  if (story.excerpt != null && story.excerpt!.isNotEmpty)
                    Text(
                      story.excerpt!,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: context.h(12)),
                  // Arrow Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: context.w(32),
                        height: context.h(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: context.iconSmall,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryImage(TravelStoryEntity story) {
    final imageUrl = story.featuredImageUrl ?? story.headerImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: Icon(
          Icons.image,
          size: 48,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: const Color(0xff005B7F),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade300,
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey.shade600,
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return SizedBox(
      height: context.h(200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: context.w(48),
              color: Colors.red.shade400,
            ),
            SizedBox(height: context.h(12)),
            Text(
              'Failed to load stories',
              style: TextStyle(
                fontSize: context.fs(14),
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: context.h(16)),
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
                backgroundColor: const Color(0xff005B7F),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(24),
                  vertical: context.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: context.fs(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: context.h(200),
      child: Center(
        child: Text(
          'No travel stories available',
          style: TextStyle(
            fontSize: context.fs(14),
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  void _onStoryTap(BuildContext context, TravelStoryEntity story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelStoryDetailScreen(slug: story.slug),
      ),
    );
  }
}
