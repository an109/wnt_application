import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_Details/presentation/screens/widgets/photo_gallery_section.dart';

/// Full photo gallery, reached by tapping the thumbnail strip on
/// [AkHotelDetailScreen]. Just hosts the same [PhotoGallerySection] the old
/// "Photos" tab used (`showMainImage: false` for its grid layout,
/// `enableFullScreen: true` so each tile still opens the section's own
/// tap-to-zoom dialog) — the exact same widget/data, on its own screen.
class AkHotelPhotoGalleryScreen extends StatelessWidget {
  final List<String> images;
  final String hotelName;
  final int rating;

  const AkHotelPhotoGalleryScreen({
    super.key,
    required this.images,
    required this.hotelName,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: Text(
          hotelName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: context.titleSmall, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
      ),
      body: SingleChildScrollView(
        physics: context.scrollPhysics,
        child: PhotoGallerySection(
          images: images,
          hotelName: hotelName,
          rating: rating,
          showMainImage: false,
          enableFullScreen: true,
        ),
      ),
    );
  }
}
