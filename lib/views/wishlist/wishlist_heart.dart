import 'package:flutter/material.dart';

import '../../UI_helper/responsive_layout.dart';
import 'wishlist_store.dart';

const _heartRed = Color(0xFFFF4D4F);

/// Heart that adds/removes [item] from the wishlist; filled red when saved.
/// [badge] wraps it in the white circle used on image cards.
class WishlistHeart extends StatelessWidget {
  final WishlistItem item;
  final double size;
  final bool badge;
  final Color outlineColor;

  const WishlistHeart({
    super.key,
    required this.item,
    this.size = 13,
    this.badge = true,
    this.outlineColor = _heartRed,
  });

  void _toggle(BuildContext context) {
    final store = WishlistStore.instance;
    final adding = !store.contains(item.id);
    store.toggle(item);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(adding ? 'Added to wishlist' : 'Removed from wishlist'),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WishlistStore.instance,
      builder: (context, _) {
        final saved = WishlistStore.instance.contains(item.id);
        final icon = Icon(
          saved ? Icons.favorite : Icons.favorite_border,
          size: context.w(size),
          color: saved ? _heartRed : outlineColor,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggle(context),
          child: badge
              ? Container(
                  padding: EdgeInsets.all(context.w(size * 0.35)),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                )
              : Padding(padding: EdgeInsets.all(context.w(4)), child: icon),
        );
      },
    );
  }
}

/// Same toggle, but keeps a screen's own heart artwork while unsaved.
class WishlistHeartImage extends StatelessWidget {
  final WishlistItem item;
  final String asset;
  final double size;

  const WishlistHeartImage({
    super.key,
    required this.item,
    this.asset = 'assets/NewIcons/heartHD.png',
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WishlistStore.instance,
      builder: (context, _) {
        final saved = WishlistStore.instance.contains(item.id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            WishlistStore.instance.toggle(item);
            ScaffoldMessenger.maybeOf(context)
              ?..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(saved ? 'Removed from wishlist' : 'Added to wishlist'),
                duration: const Duration(seconds: 1),
              ));
          },
          child: saved
              ? Icon(Icons.favorite, size: context.w(size), color: _heartRed)
              : Image.asset(asset, width: context.w(size), height: context.h(size)),
        );
      },
    );
  }
}
