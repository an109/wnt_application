import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final EdgeInsets? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    } else {
      content = Padding(
        padding: context.horizontalPadding,
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: context.scrollPhysics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: content,
            ),
          ),
        );
      },
    );
  }
}