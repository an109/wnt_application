import 'dart:async';

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

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) return;

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (trimmedQuery.length >= 2 &&
          trimmedQuery != _lastSearchQuery) {

        _lastSearchQuery = trimmedQuery;

        context.read<DestinationBloc>().add(
          SearchDestinationsEvent(query: trimmedQuery),
        );
      }
    });
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