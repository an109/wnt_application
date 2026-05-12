import 'package:flutter/material.dart';

class CustomDropdownSearch<T extends Object> extends StatefulWidget {
  final List<T> options;
  final String label;
  final String hint;
  final String? selectedValue;
  final void Function(T) onSelected;
  final String Function(T) displayStringForOption;
  final bool isLoading;
  final void Function(String)? onSearchChanged;
  final TextEditingController? searchController;

  const CustomDropdownSearch({
    super.key,
    required this.options,
    required this.label,
    required this.hint,
    required this.onSelected,
    required this.displayStringForOption,
    this.selectedValue,
    this.isLoading = false,
    this.onSearchChanged,
    this.searchController,
  });

  @override
  State<CustomDropdownSearch<T>> createState() => _CustomDropdownSearchState<T>();
}

class _CustomDropdownSearchState<T extends Object> extends State<CustomDropdownSearch<T>> {
  late TextEditingController _searchController;
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();

  // FIXED: Fixed dropdown height with internal scrolling
  static const double _dropdownHeight = 250.0;
  static const double _headerHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isDropdownOpen) return;
    setState(() => _isDropdownOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isDropdownOpen = false);
  }

  void _showOverlay() {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            // Transparent overlay to catch outside taps
            Positioned.fill(child: Container(color: Colors.transparent)),

            // FIXED: Dropdown with fixed height positioned below field
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 8,
              width: size.width,
              child: Material(
                elevation: 8,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: _dropdownHeight, // FIXED HEIGHT
                  child: _buildDropdownContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownContent() {
    final input = _searchController.text.toLowerCase().trim();

    // FIXED: Filter only current API response, no cached results
    final filteredOptions = widget.options.where((option) {
      final displayText = widget.displayStringForOption(option).toLowerCase();
      return input.isEmpty || displayText.contains(input);
    }).toList();

    return Column(
      children: [
        // Fixed height search header
        SizedBox(
          height: _headerHeight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      widget.onSearchChanged?.call(value);
                      _overlayEntry?.markNeedsBuild();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // FIXED: Scrollable options list with remaining height
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            // FIXED: Force rebuild when options change (no cached results)
            key: ValueKey(widget.options.hashCode),
            itemCount: filteredOptions.length,
            itemBuilder: (context, index) {
              final option = filteredOptions[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onSelected(option);
                    _searchController.clear();
                    _closeDropdown();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      widget.displayStringForOption(option),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main display field - matches nationality field style
        GestureDetector(
          key: _fieldKey,
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.selectedValue ?? widget.hint,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: widget.selectedValue != null
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: widget.selectedValue != null
                          ? Colors.black
                          : const Color(0xffBCC1CA),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                Icon(
                  _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xffBCC1CA),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Loading indicator below field (only when closed)
        if (widget.isLoading && !_isDropdownOpen)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}