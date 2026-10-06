import 'package:flutter/material.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Transfer/cab-search loading state.
class TransportLoadingIndicator extends StatelessWidget {
  const TransportLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView(
      messages: [
        'Searching transfers for you…',
        'Checking vehicle availability…',
        'Comparing prices for the best deals…',
        'Almost there, preparing your results…',
      ],
    );
  }
}
