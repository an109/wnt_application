import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class AIFloatingButton extends StatefulWidget {
  final VoidCallback? onTap;
  final double? bottom;
  final double? right;
  final double? size;
  final String? frameImagePath;
  final String? gifImagePath;
  final Color? backgroundColor;
  final Color? shadowColor;
  final double? blurRadius;
  final bool showPulseAnimation;
  final bool showTooltip;
  final String? tooltipText;

  const AIFloatingButton({
    Key? key,
    this.onTap,
    this.bottom,
    this.right,
    this.size,
    this.frameImagePath = 'assets/Newgif/ai_frame.png',
    this.gifImagePath = 'assets/Newgif/home_ai.gif',
    this.backgroundColor = Colors.white,
    this.shadowColor = Colors.black26,
    this.blurRadius,
    this.showPulseAnimation = false,
    this.showTooltip = false,
    this.tooltipText = 'AI Assistant',
  }) : super(key: key);

  @override
  State<AIFloatingButton> createState() => _AIFloatingButtonState();
}

class _AIFloatingButtonState extends State<AIFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showPulseAnimation) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
          parent: _pulseController,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? context.w(50);
    final bottomPosition = widget.bottom ?? context.h(56);
    final rightPosition = widget.right ?? context.w(20);

    Widget button = GestureDetector(
      onTap: widget.onTap ?? () {
        debugPrint("AI button tapped");
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor!,
              blurRadius: widget.blurRadius ?? context.h(10),
              offset: Offset(0, context.h(4)),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Colorful AI Frame
            ClipOval(
              child: Image.asset(
                widget.frameImagePath!,
                width: buttonSize * 1.3,
                height: buttonSize * 1.3,
                fit: BoxFit.cover,
              ),
            ),
            // AI GIF
            ClipOval(
              child: Image.asset(
                widget.gifImagePath!,
                width: buttonSize * 1.35,
                height: buttonSize * 1.35,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );

    // Add pulse animation if enabled
    if (widget.showPulseAnimation) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: button,
      );
    }

    // Add tooltip if enabled
    if (widget.showTooltip) {
      button = Tooltip(
        message: widget.tooltipText ?? 'AI Assistant',
        child: button,
      );
    }

    return Positioned(
      bottom: bottomPosition,
      right: rightPosition,
      child: button,
    );
  }
}