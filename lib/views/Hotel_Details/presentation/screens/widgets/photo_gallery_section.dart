import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class PhotoGallerySection extends StatefulWidget {
  final List<String> images;
  final String hotelName;
  final int rating;
  final bool showMainImage;

  const PhotoGallerySection({
    super.key,
    required this.images,
    required this.hotelName,
    required this.rating,
    this.showMainImage = true,
  });

  @override
  State<PhotoGallerySection> createState() => _PhotoGallerySectionState();
}

class _PhotoGallerySectionState extends State<PhotoGallerySection> {
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    print('PhotoGallerySection: Building with ${widget.images.length} images');

    if (!widget.showMainImage) {
      return _buildPhotoGrid();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainImage(),
        if (widget.images.length > 1) _buildThumbnailGrid(),
      ],
    );
  }

  Widget _buildMainImage() {
    return Stack(
      children: [
        Container(
          height: context.hp(35),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          child: widget.images.isNotEmpty
              ? Image.network(
            widget.images[_selectedImageIndex],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('PhotoGallerySection: Error loading image - $error');
              return Center(
                child: Icon(
                  Icons.hotel,
                  size: 64,
                  color: Colors.grey[400],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          )
              : Center(
            child: Icon(
              Icons.hotel,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${widget.rating} Star',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              print('PhotoGallerySection: Heart button pressed');
              // Add to wishlist functionality
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.images.length} photos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailGrid() {
    final visibleImages = widget.images.length > 1
        ? widget.images.sublist(1, widget.images.length > 5 ? 5 : widget.images.length)
        : [];

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.isMobile ? 3 : 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: visibleImages.length,
        itemBuilder: (context, index) {
          final actualIndex = index + 1;
          final isSelected = _selectedImageIndex == actualIndex;

          return GestureDetector(
            onTap: () {
              print('PhotoGallerySection: Thumbnail $actualIndex tapped');
              setState(() {
                _selectedImageIndex = actualIndex;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.images[actualIndex],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.grey[300]);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Container(
      padding: context.responsivePadding,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Photos',
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.isMobile ? 2 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.grey[300]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}