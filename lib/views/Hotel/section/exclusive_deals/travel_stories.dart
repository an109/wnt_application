import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TravelStoriesSection extends StatelessWidget {
  const TravelStoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = [
      {
        "title":
        "How to Plan a Bali Trip from India: Itinerary, Costs & Tips",
        "image":
        "https://images.unsplash.com/photo-1537953773345-d172ccf13cf1?q=80&w=1200&auto=format&fit=crop",
      },
      {
        "title":
        "Shimla Manali Family Trip 2026: What to Know",
        "image":
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1200&auto=format&fit=crop",
      },
      {
        "title":
        "1 Day Mussoorie Itinerary: What to See and Do",
        "image":
        "https://images.unsplash.com/photo-1521295121783-8a321d551ad2?q=80&w=1200&auto=format&fit=crop",
      },
      {
        "title":
        "Shimla Trip Plan for Couples 2026",
        "image":
        "https://images.unsplash.com/photo-1517760444937-f6397edcbbcd?q=80&w=1200&auto=format&fit=crop",
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE
          Text(
            "Travel Stories",
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.hp(2)),

          /// GRID
          GridView.builder(
            itemCount: stories.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.isTablet ? 3 : 2,
              crossAxisSpacing: context.wp(3),
              mainAxisSpacing: context.hp(1.8),
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final story = stories[index];

              return _TravelStoryCard(
                title: story["title"]!,
                image: story["image"]!,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TravelStoryCard extends StatelessWidget {
  final String title;
  final String image;

  const _TravelStoryCard({
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(title),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
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
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                ),
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
                bottom: context.hp(1.5),
                child: Text(
                  title,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}