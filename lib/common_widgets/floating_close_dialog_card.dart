import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

/// White rounded card with a circular "×" button floating outside its
/// top-right corner — the shared dialog treatment used by the transport
/// booking card's Travellers / Time / Date pickers (Figma: floating close
/// icon overlapping the card's top-right corner).
///
/// Used as the `builder` result of a `showDialog` call; the card centers
/// itself, so callers don't need to wrap it further.
class FloatingCloseDialogCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const FloatingCloseDialogCard({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(context.r(24));
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: width ?? context.w(320),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: radius,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: padding,
                  child: child,
                ),
              ),
              Positioned(
                top: -context.h(38),
                right: -context.w(0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: context.w(27),
                    height: context.w(27),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.black.withValues(alpha: 0.18),
                      //     blurRadius: 10,
                      //     offset: const Offset(0, 3),
                      //   ),
                      // ],
                    ),
                    child: Icon(Icons.close_rounded, size: context.w(18), color: Colors.black87),
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
