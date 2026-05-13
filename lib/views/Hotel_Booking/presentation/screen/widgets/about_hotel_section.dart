import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class AboutHotelSection extends StatefulWidget {
  final String description;
  final String hotelName;

  const AboutHotelSection({
    super.key,
    required this.description,
    required this.hotelName,
  });

  @override
  State<AboutHotelSection> createState() => _AboutHotelSectionState();
}

class _AboutHotelSectionState extends State<AboutHotelSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.description.isEmpty) {
      return const SizedBox.shrink();
    }

    print('AboutHotelSection: Building for ${widget.hotelName}');

    // Strip HTML tags and clean the description
    final String cleanDescription = _stripHtmlTags(widget.description);

    return Container(
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
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [

                // SizedBox(width: context.gapSmall),
                Text(
                  'ABOUT THE HOTEL',
                  style: TextStyle(
                    fontSize: context.titleSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.hotelName,
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildDescriptionText(cleanDescription),
            if (_isTextTooLong(cleanDescription)) ...[
              SizedBox(height: context.gapSmall),
              _buildReadMoreButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionText(String description) {
    final textSpan = TextSpan(
      text: description,
      style: TextStyle(
        fontSize: context.sp(14),
        color: Colors.grey[700],
        height: 1.6,
      ),
    );

    if (_isExpanded || !_isTextTooLong(description)) {
      return Text.rich(textSpan);
    }

    // Show truncated version
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 4,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        if (textPainter.didExceedMaxLines) {
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: description.substring(0, _findTruncationPoint(description)),
                  style: textSpan.style,
                ),
                TextSpan(
                  text: '...',
                  style: textSpan.style?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            maxLines: 4,
            overflow: TextOverflow.clip,
          );
        }

        return Text.rich(textSpan);
      },
    );
  }

  Widget _buildReadMoreButton() {
    return GestureDetector(
      onTap: () {
        print('AboutHotelSection: Read ${_isExpanded ? 'Less' : 'More'} tapped');
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.gapSmall,
          vertical: context.gapSmall / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isExpanded ? 'Read Less' : 'Read More',
              style: TextStyle(
                fontSize: context.sp(13),
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: context.gapSmall / 2),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: context.sp(16),
              color: Colors.blue.shade700,
            ),
          ],
        ),
      ),
    );
  }

  bool _isTextTooLong(String text) {
    // Consider text too long if it has more than 300 characters or 4+ lines
    return text.length > 300;
  }

  int _findTruncationPoint(String text) {
    // Find a good breaking point (space or period) around 300 characters
    if (text.length <= 300) return text.length;

    // Try to find a period first
    int lastPeriod = text.lastIndexOf('.', 300);
    if (lastPeriod > 250) return lastPeriod + 1;

    // Otherwise find last space
    int lastSpace = text.lastIndexOf(' ', 300);
    if (lastSpace > 250) return lastSpace;

    return 300;
  }

  String _stripHtmlTags(String html) {
    String text = html;

    // Remove HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Remove multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Decode common HTML entities
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");

    // Remove section labels but keep content
    text = text.replaceAll(RegExp(r'HeadLine\s*:'), '');
    text = text.replaceAll(RegExp(r'Location\s*:'), '');
    text = text.replaceAll(RegExp(r'Rooms\s*:'), '');
    text = text.replaceAll(RegExp(r'Dining\s*:'), '');
    text = text.replaceAll(RegExp(r'Amenities?\s*:'), '');

    // Trim whitespace
    return text.trim();
  }
}