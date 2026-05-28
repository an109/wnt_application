import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/travel_stories/presentation/screen/travel_stories_detail_screen.dart';
import '../../domain/entities/travel_stories_entity.dart';
import '../bloc/travel_stories_bloc.dart';
import '../bloc/travel_stories_event.dart';
import '../bloc/travel_stories_state.dart';

class AllTravelStoriesScreen extends StatefulWidget {
  const AllTravelStoriesScreen({super.key});

  @override
  State<AllTravelStoriesScreen> createState() => _AllTravelStoriesScreenState();
}

class _AllTravelStoriesScreenState extends State<AllTravelStoriesScreen> {
  // Remove the pagination controller and just load once
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Load stories only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TravelStoriesBloc>().add(
          const GetTravelStoriesEvent(
            status: 'published',
            domain: 'thewandernova.com',
            limit: 50, // Increase limit to get more stories
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: BlocBuilder<TravelStoriesBloc, TravelStoriesState>(
        builder: (context, state) {
          if (state is TravelStoriesLoading) {
            return _buildLoadingState(context);
          }

          if (state is TravelStoriesLoaded) {
            if (state.stories.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildStoriesGrid(context, state.stories);
          }

          if (state is TravelStoriesError) {
            return _buildErrorState(context, state.message);
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.black87,
          size: context.iconMedium,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'All Travel Stories',
        style: TextStyle(
          fontSize: context.titleLarge,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: context.wp(0.8),
          ),
          SizedBox(height: context.hp(2)),
          Text(
            'Loading stories...',
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: context.iconXLarge,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: context.hp(2)),
          Text(
            'No travel stories available',
            style: TextStyle(
              fontSize: context.bodyLarge,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: context.iconXLarge,
            color: Colors.red.shade400,
          ),
          SizedBox(height: context.hp(2)),
          Text(
            'Failed to load stories',
            style: TextStyle(
              fontSize: context.bodyLarge,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            message,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.hp(2)),
          ElevatedButton(
            onPressed: () {
              context.read<TravelStoriesBloc>().add(
                const GetTravelStoriesEvent(
                  status: 'published',
                  domain: 'thewandernova.com',
                  limit: 50,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(6),
                vertical: context.hp(1.5),
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
    );
  }

  Widget _buildStoriesGrid(BuildContext context, List<TravelStoryEntity> stories) {
    final crossAxisCount = context.isMobile ? 2 : (context.isTablet ? 3 : 4);
    final childAspectRatio = context.isMobile ? 0.75 : 0.8;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(context.wp(3)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: context.wp(3),
          mainAxisSpacing: context.hp(2.5),
          childAspectRatio: childAspectRatio,
        ),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return _StoryGridCard(
            story: stories[index],
            onTap: () => _onStoryTap(context, stories[index]),
          );
        },
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

// _StoryGridCard class remains the same as before
class _StoryGridCard extends StatelessWidget {
  final TravelStoryEntity story;
  final VoidCallback onTap;

  const _StoryGridCard({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildStoryImage(context),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.wp(3)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.titleSmall,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: context.hp(0.5)),
                    if (story.excerpt != null && story.excerpt!.isNotEmpty)
                      Text(
                        story.excerpt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.2,
                        ),
                      ),
                    SizedBox(height: context.hp(1)),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: context.iconSmall,
                          color: Colors.white,
                        ),
                      ],
                    ),
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
    final imageUrl = story.featuredImageUrl ?? story.headerImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade700,
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade500,
          size: context.iconXLarge,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade800,
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
        return Container(
          color: Colors.grey.shade700,
          child: Icon(
            Icons.broken_image,
            color: Colors.grey.shade500,
            size: context.iconXLarge,
          ),
        );
      },
    );
  }
}