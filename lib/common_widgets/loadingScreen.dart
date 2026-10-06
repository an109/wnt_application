import 'package:flutter/material.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Flight-search loading state, shown while results are being fetched.
///
/// It stays up for as long as the search is actually running — the caller
/// swaps it out when results (or an error) arrive.
class ProfessionalLoadingScreen extends StatelessWidget {
  /// Kept for existing callers; no longer invoked because there is no
  /// simulated progress to "complete" any more.
  final VoidCallback onLoadingComplete;
  final Map<String, dynamic>? searchParams;

  const ProfessionalLoadingScreen({
    super.key,
    required this.onLoadingComplete,
    this.searchParams,
  });

  String? _route() {
    final from = searchParams?['fromAirport']?.toString().trim() ?? '';
    final to = searchParams?['toAirport']?.toString().trim() ?? '';
    if (from.isEmpty || to.isEmpty) return null;
    return 'Searching flights from $from to $to…';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: AppLoadingView(
        messages: [
          _route() ?? 'Searching flights…',
          'Checking availability across airlines…',
          'Comparing fares for the best deals…',
          'Almost there, preparing your results…',
        ],
      ),
    );
  }
}
