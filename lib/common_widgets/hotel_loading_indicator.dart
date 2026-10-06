import 'package:flutter/material.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Hotel-search loading state.
class HotelLoadingIndicator extends StatelessWidget {
  const HotelLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView(
      messages: [
        'Searching hotels for you…',
        'Checking room availability…',
        'Comparing prices for the best deals…',
        'Almost there, preparing your results…',
      ],
    );
  }
}
