import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';

class AnimatedMyTripButton extends StatefulWidget {
  final VoidCallback? onTap;

  const AnimatedMyTripButton({super.key, this.onTap});

  @override
  State<AnimatedMyTripButton> createState() => _AnimatedMyTripButtonState();
}

class _AnimatedMyTripButtonState extends State<AnimatedMyTripButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: AppColors.primary,
      end: AppColors.accent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(1.5),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _colorAnimation.value ?? AppColors.primary,
                    AppColors.primary.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    color: AppColors.white,
                    size: context.iconSmall,
                  ),
                  SizedBox(width: context.gapSmall),
                  Text(
                    'My Trip',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}