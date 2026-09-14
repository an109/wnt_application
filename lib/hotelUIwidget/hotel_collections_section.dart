import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../core/resources/app_colours.dart';
import 'hotel_collections_divider.dart';

/// Figma "Collections" section (node 137:1117) — a 1-large + 3-small photo
/// mosaic bracketed by [HotelCollectionsDivider]. There's no Collections API
/// yet, so — same convention already used by `RecentlyViewedSection` and
/// `ForYourStaySection` elsewhere in the app — this uses static curated
/// photos rather than inventing a fake data source.
class HotelCollectionsSection extends StatelessWidget {
  const HotelCollectionsSection({super.key});

  static const _images = [
    'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=500', // pool resort
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500', // lit-up building
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=300', // bedroom
    'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=300', // lounge
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collections',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: context.h(10)),
          const HotelCollectionsDivider(),
          SizedBox(height: context.h(12)),
          SizedBox(
            height: context.h(220),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _collectionImage(_images[0], context.r(16))),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _collectionImage(_images[1], context.r(16)),
                      ),
                      SizedBox(height: context.h(8)),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _collectionImage(_images[2], context.r(12)),
                            ),
                            SizedBox(width: context.w(8)),
                            Expanded(
                              child: _collectionImage(_images[3], context.r(12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),
          const HotelCollectionsDivider(),
        ],
      ),
    );
  }

  Widget _collectionImage(String url, double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      ),
    );
  }
}
