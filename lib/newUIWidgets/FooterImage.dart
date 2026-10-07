
import 'package:flutter/cupertino.dart';

import '../UI_helper/responsive_layout.dart';
import '../views/splash/widgets/wander_logo.dart';

class AuthFooterBadge extends StatelessWidget {
  const AuthFooterBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        WanderLogoLayers.footerBadge,
        width: context.w(130),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}