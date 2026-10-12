import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../UI_helper/responsive_layout.dart';
import '../../core/resources/app_colours.dart';
import '../../newUIWidgets/Home_nav.dart';
import '../MyBookings/Screen/MyBooking_Screen.dart';
import '../TrishaAI/presentation/screen/trisha_chat_screen.dart';
import '../offers/offers_screen.dart';
import 'wishlist_heart.dart';
import 'wishlist_store.dart';

/// Figma "Wishlist all" / "Wishlist empty".
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  /// Back to the home screen to keep exploring.
  void _addNew(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Same tabs as the home bar; Wishlist (3) is this screen.
  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyBookingScreen()),
        );
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OffersScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: context.h(12)),
          child: CustomBottomNav(
            currentIndex: 3,
            onItemSelected: (index) => _onNavTap(context, index),
            onCenterTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrishaChatScreen()),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: ListenableBuilder(
          listenable: WishlistStore.instance,
          builder: (context, _) {
            final items = WishlistStore.instance.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  showAddNew: items.isNotEmpty,
                  onAddNew: () => _addNew(context),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            context.w(16),
                            context.h(8),
                            context.w(16),
                            context.h(130),
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => SizedBox(height: context.h(16)),
                          itemBuilder: (_, i) => _WishlistCard(item: items[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool showAddNew;
  final VoidCallback onAddNew;

  const _Header({required this.showAddNew, required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(24)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // if (Navigator.of(context).canPop()) ...[
          //   GestureDetector(
          //     onTap: () => Navigator.of(context).pop(),
          //     child: Padding(
          //       padding: EdgeInsets.only(bottom: context.h(22), right: context.w(8)),
          //       child: Icon(Icons.arrow_back_ios_new, size: context.w(18), color: AppColors.authInk),
          //     ),
          //   ),
          // ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wishlist',
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w600,
                    color: AppColors.authInk,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  'Your saved destination & packages',
                  style: TextStyle(fontSize: context.fs(12), color: AppColors.authSubtle, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (showAddNew)
            GestureDetector(
              onTap: onAddNew,
              child: Padding(
                padding: EdgeInsets.only(bottom: context.h(10)),
                child: Row(
                  children: [
                    Icon(Icons.add, size: context.w(16), color: AppColors.AppBlue),
                    SizedBox(width: context.w(4)),
                    Text(
                      'Add New',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.AppBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;

  const _WishlistCard({required this.item});

  void _share() {
    final text = item.subtitle.isEmpty
        ? '${item.title} — found on Wander Nova'
        : '${item.title} (${item.subtitle}) — found on Wander Nova';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final images = item.images;
    final thumbs = images.length > 1 ? images.skip(1).take(3).toList() : const <String>[];

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Photo(
            url: images.isNotEmpty ? images.first : null,
            width: context.w(140),
            height: context.w(106),
            radius: 12,
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(15),
                              fontWeight: FontWeight.w500,
                              color: AppColors.authInk,
                            ),
                          ),
                          if (item.subtitle.isNotEmpty) ...[
                            SizedBox(height: context.h(2)),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: context.fs(11), color: AppColors.authSubtle),
                            ),
                          ],
                        ],
                      ),
                    ),
                    WishlistHeart(item: item, size: 18, badge: false),
                    GestureDetector(
                      onTap: _share,
                      child: Padding(
                        padding: EdgeInsets.all(context.w(4)),
                        child: Icon(Icons.share, size: context.w(18), color: AppColors.authInk),
                      ),
                    ),
                  ],
                ),
                if (thumbs.isNotEmpty) ...[
                  SizedBox(height: context.h(10)),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) SizedBox(width: context.w(6)),
                        Expanded(
                          child: i < thumbs.length
                              ? AspectRatio(
                                  aspectRatio: 1,
                                  child: _Photo(url: thumbs[i], radius: 8),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double radius;

  const _Photo({required this.url, this.width, this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFEFF3F8),
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
    );
    final link = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(radius)),
      child: link == null || link.isEmpty
          ? placeholder
          : link.startsWith('assets/')
              ? Image.asset(link, width: width, height: height, fit: BoxFit.cover)
              : CachedNetworkImage(
                  imageUrl: link,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => placeholder,
                  errorWidget: (_, __, ___) => placeholder,
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/wishlist_empty.png', width: context.w(240)),
            SizedBox(height: context.h(12)),
            Text(
              'No more places in wishlist',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(17),
                fontWeight: FontWeight.w500,
                color: AppColors.authInk,
              ),
            ),
            SizedBox(height: context.h(6)),
            Text(
              'Keep exploring and save your next favorite destinations here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(13), color: AppColors.authSubtle, height: 1.4),
            ),
            SizedBox(height: context.h(60)),
          ],
        ),
      ),
    );
  }
}
