import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomAutocompleteGeneric<T extends Object> extends StatefulWidget {
  final List<T> options;
  final String label;
  final void Function(T) onSelected;
  final String Function(T) displayStringForOption;  // For displaying after selection
  final String Function(T) searchStringForOption;
  final String? initialText;
  final FocusNode? focusNode;
  final Duration debounceDuration; // New parameter for debounce control
  final void Function(String)? onSearchChanged;

  const CustomAutocompleteGeneric({
    super.key,
    required this.options,
    required this.label,
    required this.onSelected,
    required this.displayStringForOption,
    required this.searchStringForOption,
    this.initialText,
    this.focusNode,
    this.debounceDuration = const Duration(milliseconds: 300), //  Default 300ms
    this.onSearchChanged,
  });

  @override
  State<CustomAutocompleteGeneric<T>> createState() =>
      _CustomAutocompleteGenericState<T>();
}

class _CustomAutocompleteGenericState<T extends Object>
    extends State<CustomAutocompleteGeneric<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer; //  Debounce timer
  List<T> _filteredOptions = []; //  Cache filtered results

  @override
  void initState() {
    super.initState();
    print(' [Autocomplete] initState: ${widget.label}');

    _controller = TextEditingController(text: widget.initialText ?? "");
    _focusNode = widget.focusNode ?? FocusNode();

    // Initialize with all options
    _filteredOptions = widget.options;

    // Add listener for real-time filtering (with debounce)
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CustomAutocompleteGeneric<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _filterOptions(_controller.text);
    }
  }

  //  Debounced text change handler
  void _onTextChanged() {
    print('[Autocomplete] Text changed: "${_controller.text}" - ${widget.label}');

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      final searchText = _controller.text;
      print('Debounce triggered: "$searchText" - ${widget.label}');

      // 🔴 ADD THIS - Call the search callback
      if (widget.onSearchChanged != null) {
        widget.onSearchChanged!(searchText);
      }

      _filterOptions(searchText);
    });
  }
  //  Filter options based on input
  // void _filterOptions(String input) {
  //   final lowercaseInput = input.toLowerCase().trim();
  //
  //   if (lowercaseInput.isEmpty && _focusNode.hasFocus) {
  //     print('[Autocomplete] Showing all options: ${widget.options.length} - ${widget.label}');
  //     setState(() {
  //       _filteredOptions = widget.options;
  //     });
  //   } else {
  //     final filtered = widget.options.where((option) {
  //       final display = widget.displayStringForOption(option).toLowerCase();
  //       return display.contains(lowercaseInput);
  //     }).toList();
  //
  //     print('[Autocomplete] Filtered to ${filtered.length} results: "$lowercaseInput" - ${widget.label}');
  //
  //     setState(() {
  //       _filteredOptions = filtered;
  //     });
  //   }
  // }
  void _filterOptions(String input) {
    final lowercaseInput = input.toLowerCase().trim();

    if (lowercaseInput.isEmpty && _focusNode.hasFocus) {
      setState(() {
        _filteredOptions = widget.options;
      });
    } else {
      final filtered = widget.options.where((option) {
        // SEARCH using searchStringForOption
        final searchText = widget.searchStringForOption(option).toLowerCase();
        return searchText.contains(lowercaseInput);
      }).toList();

      setState(() {
        _filteredOptions = filtered;
      });
    }
  }

  @override
  void dispose() {
    print('[Autocomplete] dispose: ${widget.label}');
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(' [Autocomplete] build: ${widget.label}');

    return GestureDetector(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return RawAutocomplete<T>(
            textEditingController: _controller,
            focusNode: _focusNode,
            displayStringForOption: widget.displayStringForOption,

            //  Use cached filtered options instead of filtering on every call
            optionsBuilder: (TextEditingValue textEditingValue) {
              print(' [Autocomplete] optionsBuilder called: "${textEditingValue.text}" - ${widget.label}');
              return _filteredOptions;
            },

            optionsViewBuilder: (context, onSelected, options) {
              print(' [Autocomplete] Showing ${options.length} options in dropdown - ${widget.label}');

              if (options.isEmpty) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8.0,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: 250,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8.0,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: 250,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            print(' [Autocomplete] Selected: "${widget.displayStringForOption(option)}" - ${widget.label}');
                            onSelected(option);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: ListTile(
                            title: Text(widget.displayStringForOption(option)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },

            onSelected: (selected) {
              print(' [Autocomplete] Final selection: "${widget.displayStringForOption(selected)}" - ${widget.label}');
              widget.onSelected(selected);
            },

            fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
                ) {
              final node = widget.focusNode ?? focusNode;

              return TextField(
                controller: controller,
                focusNode: node,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  isDense: true,
                  hintText: widget.label,
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xffBCC1CA),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(width: 1, color: Color(0xffBCC1CA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(width: 1, color: Color(0xffBCC1CA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      width: 1.5,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xffBCC1CA),
                  ),
                ),
                onChanged: (value) {
                  // 👈 This triggers our debounced listener
                  print('[Autocomplete] TextField onChanged: "$value" - ${widget.label}');
                },
                onSubmitted: (value) {
                  print(' [Autocomplete] TextField onSubmitted: "$value" - ${widget.label}');
                  onFieldSubmitted();
                },
              );
            },
          );
        },
      ),
    );
  }
}