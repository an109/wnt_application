import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common_widgets/custom_dropdown.dart';
import '../../domain/entities/destination_entity.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';
import '../bloc/destination_state.dart';


class DestinationSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final void Function(DestinationEntity)? onDestinationSelected;

  const DestinationSearchField({
    super.key,
    required this.label,
    required this.hint,
    this.onDestinationSelected,
  });

  @override
  State<DestinationSearchField> createState() => _DestinationSearchFieldState();
}

class _DestinationSearchFieldState extends State<DestinationSearchField> {
  String? _selectedDisplayText;
  final TextEditingController _searchController = TextEditingController();
  String _lastSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Only trigger API for new queries (avoid duplicate calls)
    if (query.length >= 2 && query != _lastSearchQuery) {
      _lastSearchQuery = query;
      context.read<DestinationBloc>().add(
        SearchDestinationsEvent(query: query.trim()),
      );
    }
    // If query cleared, we still show all current results (no reset to empty)
  }

  void _onDestinationSelected(DestinationEntity destination) {
    setState(() {
      _selectedDisplayText = destination.displayName;
    });
    widget.onDestinationSelected?.call(destination);
  }

  String _displayDestination(DestinationEntity destination) {
    return destination.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinationBloc, DestinationState>(
      builder: (context, state) {
        List<DestinationEntity> options = [];
        bool isLoading = false;

        if (state is DestinationLoading) {
          isLoading = true;
        } else if (state is DestinationLoaded) {
          // FIXED: Always use fresh API response, never cache/append
          options = state.destinationData.getAllDestinations();
        }

        return CustomDropdownSearch<DestinationEntity>(
          options: options, // Always fresh from API
          label: widget.label,
          hint: widget.hint,
          selectedValue: _selectedDisplayText,
          isLoading: isLoading,
          displayStringForOption: _displayDestination,
          onSearchChanged: _onSearchChanged,
          searchController: _searchController,
          onSelected: _onDestinationSelected,
        );
      },
    );
  }
}