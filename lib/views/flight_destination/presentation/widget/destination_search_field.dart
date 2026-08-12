import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../domain/entities/destination_entity.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';
import '../bloc/destination_state.dart';

/// Inline destination search: the field itself is the input. Typing triggers a
/// debounced search and suggestions appear in an anchored overlay right below —
/// no separate search popup. Mirrors the flight airport search behaviour.
class DestinationSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final DestinationEntity? initialDestination;
  final void Function(DestinationEntity)? onDestinationSelected;

  const DestinationSearchField({
    super.key,
    required this.label,
    required this.hint,
    this.initialDestination,
    this.onDestinationSelected,
  });

  @override
  State<DestinationSearchField> createState() => _DestinationSearchFieldState();
}

class _DestinationSearchFieldState extends State<DestinationSearchField> {
  DestinationBloc? _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  bool _suppressNextOverlay = false;
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.initialDestination != null) {
      _controller.text = widget.initialDestination!.displayName;
      _hasSelection = true;
    }
  }

  @override
  void didUpdateWidget(DestinationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect a prefilled value supplied asynchronously by the parent.
    if (widget.initialDestination != oldWidget.initialDestination) {
      if (widget.initialDestination != null) {
        _controller.text = widget.initialDestination!.displayName;
        _hasSelection = true;
      } else {
        _controller.clear();
        _hasSelection = false;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<DestinationBloc>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _closeOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_suppressNextOverlay) return;
      _openOverlay();
    } else {
      _closeOverlay();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _suppressNextOverlay = false;

    if (_hasSelection) {
      setState(() => _hasSelection = false);
    }

    if (_focusNode.hasFocus) _openOverlay();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmed = query.trim();
      if (trimmed.length >= 2) {
        _bloc?.add(SearchDestinationsEvent(query: trimmed));
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _selectDestination(DestinationEntity destination) {
    _suppressNextOverlay = true;
    _debounce?.cancel();
    _closeOverlay();

    setState(() {
      _controller.text = destination.displayName;
      _hasSelection = true;
    });
    _focusNode.unfocus();
    widget.onDestinationSelected?.call(destination);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressNextOverlay = false;
    });
  }

  void _clearSelection() {
    _debounce?.cancel();
    setState(() {
      _controller.clear();
      _hasSelection = false;
    });
    _overlayEntry?.markNeedsBuild();
    _focusNode.requestFocus();
  }

  void _openOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _suppressNextOverlay) return;
      if (_overlayEntry != null) return;

      final overlay = Overlay.of(context);
      final renderBox = context.findRenderObject() as RenderBox;
      final offset = renderBox.localToGlobal(Offset.zero);
      final gap = context.h(8);

      _overlayEntry = OverlayEntry(
        builder: (overlayContext) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _focusNode.unfocus();
                  _closeOverlay();
                },
              ),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + renderBox.size.height + gap,
              width: renderBox.size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, renderBox.size.height + gap),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(context.r(12)),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: context.hp(28)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.r(12)),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: context.w(15),
                          offset: Offset(0, context.h(4)),
                        ),
                      ],
                    ),
                    child: _buildDropdownContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      overlay.insert(_overlayEntry!);
    });
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownContent() {
    final query = _controller.text.trim();

    if (query.length < 2) {
      return _hintBox(
        icon: Icons.search,
        message: 'Type at least 2 characters to search',
      );
    }

    return BlocBuilder<DestinationBloc, DestinationState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is DestinationLoading) {
          return Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DestinationError) {
          return _hintBox(
            icon: Icons.error_outline,
            message: 'Unable to load destinations',
            color: Colors.red.shade400,
          );
        }

        if (state is DestinationLoaded) {
          final options = state.destinationData.getAllDestinations();
          if (options.isEmpty) {
            return _hintBox(
              icon: Icons.info_outline,
              message: 'No results found',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final destination = options[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.w(14),
                  vertical: context.h(2),
                ),
                leading: Icon(
                  destination.type == DestinationType.hotel
                      ? Icons.hotel_outlined
                      : Icons.location_on_outlined,
                  size: context.iconMedium,
                  color: const Color(0xff0D1B3D),
                ),
                title: Text(
                  destination.displayName,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D1B3D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectDestination(destination),
              );
            },
          );
        }

        return _hintBox(
          icon: Icons.search,
          message: 'Type to search destinations',
        );
      },
    );
  }

  Widget _hintBox({
    required IconData icon,
    required String message,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.all(context.w(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.iconLarge,
            color: color ?? Colors.grey.shade400,
          ),
          SizedBox(height: context.h(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: color ?? Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB8BEC9),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: context.h(4)),
              ),
              style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF071638),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          _hasSelection
              ? GestureDetector(
                  onTap: _clearSelection,
                  child: Icon(
                    Icons.clear,
                    size: context.iconSmall,
                    color: const Color(0xffBCC1CA),
                  ),
                )
              : Icon(
                  _overlayEntry != null
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: context.iconMedium,
                  color: const Color(0xffBCC1CA),
                ),
        ],
      ),
    );
  }
}
