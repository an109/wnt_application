import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/travel_stories_entity.dart';
import '../bloc/travel_stories_bloc.dart';
import '../bloc/travel_stories_event.dart';
import '../bloc/travel_stories_state.dart';


class TravelStoryDetailScreen extends StatefulWidget {
  final String slug;

  const TravelStoryDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  State<TravelStoryDetailScreen> createState() => _TravelStoryDetailScreenState();
}

class _TravelStoryDetailScreenState extends State<TravelStoryDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late TravelStoriesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<TravelStoriesBloc>();
    _bloc.add(GetTravelStoryBySlugEvent(widget.slug));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: BlocBuilder<TravelStoriesBloc, TravelStoriesState>(
          builder: (context, state) {
            if (state is TravelStoriesLoading) {
              return _buildLoadingState();
            } else if (state is TravelStoryDetailLoaded) {
              return _buildDetailContent(state.story);
            } else if (state is TravelStoriesError) {
              return _buildErrorState(state.message);
            }
            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          SizedBox(height: context.hp(2)),
          Text(
            'Failed to load story',
            style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: context.hp(1)),
          Text(message, style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600)),
          SizedBox(height: context.hp(3)),
          ElevatedButton(
            onPressed: () {
              _bloc.add(GetTravelStoryBySlugEvent(widget.slug));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No story found'),
    );
  }

  Widget _buildDetailContent(TravelStoryEntity story) {
    return CustomScrollView(
      slivers: [
        // Hero Header Section
        _buildHeroHeader(story),

        // Main Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: context.isDesktop ? context.wp(20) : context.wp(5),
                  vertical: context.hp(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article Content
                    _buildArticleContent(story),

                    SizedBox(height: context.hp(3)),

                    // Comment Section
                    // _buildCommentSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(TravelStoryEntity story) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Background Image
          Container(
            height: context.isMobile ? context.hp(50) : context.hp(60),
            width: double.infinity,
            child: story.featuredImageUrl != null && story.featuredImageUrl!.isNotEmpty
                ? Image.network(
              story.featuredImageUrl!,
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
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey.shade400);
              },
            )
                : Container(color: Colors.grey.shade400),
          ),

          // Gradient Overlay
          Container(
            height: context.isMobile ? context.hp(50) : context.hp(60),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Content Overlay
          Positioned(
            bottom: context.hp(3),
            left: context.wp(5),
            right: context.wp(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge
                if (story.category != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(3),
                      vertical: context.hp(0.8),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      story.category!.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.bodySmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                SizedBox(height: context.hp(2)),

                // Title
                Text(
                  story.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.isMobile ? context.headlineMedium : context.headlineLarge,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                SizedBox(height: context.hp(2)),

              ],
            ),
          ),

          // Back Button
          Positioned(
            top: context.hp(2),
            left: context.wp(2),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons() {
    return Row(
      children: [
        _buildShareButton(Icons.share, Colors.blue, () {}),
        SizedBox(width: context.wp(1)),
        _buildShareButton(Icons.chat_bubble, Colors.green, () {}),
      ],
    );
  }

  Widget _buildShareButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildArticleContent(TravelStoryEntity story) {
    // Parse HTML content and convert to widgets
    final document = html_parser.parse(story.content);
    final elements = document.body?.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Excerpt
        if (story.excerpt != null && story.excerpt!.isNotEmpty)
          Container(
            padding: EdgeInsets.all(context.isMobile ? context.wp(4) : context.wp(6)),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(context.borderRadius),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              story.excerpt!,
              style: TextStyle(
                fontSize: context.bodyLarge,
                color: Colors.grey.shade800,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        SizedBox(height: context.hp(3)),

        // Main Content
        ...elements.map((element) {
          final tagName = element.localName;
          final text = element.text.trim();

          if (text.isEmpty) return SizedBox.shrink();

          switch (tagName) {
            case 'h1':
              return _buildHeading(text, context.headlineSmall, FontWeight.bold);
            case 'h2':
              return _buildHeading(text, context.titleLarge, FontWeight.bold);
            case 'h3':
              return _buildHeading(text, context.titleMedium, FontWeight.w600);
            case 'p':
              return _buildParagraph(text);
            case 'ul':
              return _buildUnorderedList(element);
            case 'ol':
              return _buildOrderedList(element);
            default:
              return _buildParagraph(text);
          }
        }).toList(),

        // Tags
        if (story.tags != null && story.tags!.isNotEmpty) ...[
          SizedBox(height: context.hp(3)),
          Wrap(
            spacing: context.wp(1),
            runSpacing: context.hp(1),
            children: story.tags!.split(',').map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(0.8),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag.trim(),
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHeading(String text, double fontSize, FontWeight fontWeight) {
    return Padding(
      padding: EdgeInsets.only(
        top: context.hp(2),
        bottom: context.hp(1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black87,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(2)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.bodyMedium,
          color: Colors.grey.shade700,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _buildUnorderedList(dynamic element) {
    final items = element.children.map((li) => li.text.trim()).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map<Widget>((item) {  // <-- Add <Widget> type parameter
          return Padding(
            padding: EdgeInsets.only(bottom: context.hp(0.8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: context.bodyLarge, color: Colors.grey.shade700)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderedList(dynamic element) {
    final items = element.children.map((li) => li.text.trim()).toList();

    // Check if this looks like FAQ (even count, alternating Q/A pattern)
    final isFaq = items.length.isEven && items.length >= 2;

    if (isFaq) {
      // Pair questions with answers
      return Padding(
        padding: EdgeInsets.only(bottom: context.hp(2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(items.length ~/ 2, (index) {
            final question = items[index * 2];
            final answer = items[index * 2 + 1];
            return Padding(
              padding: EdgeInsets.only(bottom: context.hp(2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question with number
                  Text(
                    '${index + 1}. $question',
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: context.hp(0.5)),
                  // Answer without number
                  Padding(
                    padding: EdgeInsets.only(left: context.wp(4)),
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    }

    // Default ordered list for non-FAQ content
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map<Widget>((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: context.hp(0.8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList().cast<Widget>(),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave a Comment',
          style: TextStyle(
            fontSize: context.titleLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: context.hp(2)),

        // Comment Input
        Container(
          padding: EdgeInsets.all(context.isMobile ? context.wp(4) : context.wp(6)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your thoughts about this story',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: context.hp(2)),

              // Comment TextField
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write your comment here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    borderSide: BorderSide(color: Colors.black, width: 1),
                  ),
                  contentPadding: EdgeInsets.all(context.wp(3)),
                ),
                style: TextStyle(fontSize: context.bodyMedium),
              ),

              SizedBox(height: context.hp(2)),

              // Post Comment Button
              SizedBox(
                width: double.infinity,
                height: context.isMobile ? context.hp(6) : context.hp(7),
                child: ElevatedButton(
                  onPressed: () {
                    _postComment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius),
                    ),
                  ),
                  child: Text(
                    'Post a Comment',
                    style: TextStyle(
                      fontSize: context.bodyLarge,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _postComment() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comment posted successfully!'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _commentController.clear();
  }

}