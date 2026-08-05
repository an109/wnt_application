import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import '../../domain/entity/AKHotelAutosuggest_entity.dart';
import '../bloc/AKHotelAutosuggest_bloc.dart';
import '../bloc/AKHotelAutosuggest_event.dart';
import '../bloc/AKHotelAutosuggest_state.dart';

/// Hotel-only destination search backed by the Akbar Hotels Autosuggest API
/// (`GET /api/akbar-hotels/autosuggest/?term=`). Deliberately separate from
/// flight_destination's [DestinationSearchField] — that widget is shared
/// with the flight flow and hits the old tbo-hotel destination-search
/// endpoint, so it can't be reused or edited here without risking flights.
class HotelAutosuggestField extends StatefulWidget {
  final String hint;
  final AkHotelLocationEntity? initialLocation;
  final void Function(AkHotelLocationEntity) onLocationSelected;

  const HotelAutosuggestField({
    super.key,
    required this.hint,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<HotelAutosuggestField> createState() => _HotelAutosuggestFieldState();
}

class _HotelAutosuggestFieldState extends State<HotelAutosuggestField> {
  late final AkHotelAutosuggestBloc _bloc;
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
    _bloc = sl<AkHotelAutosuggestBloc>();
    _focusNode.addListener(_onFocusChange);
    if (widget.initialLocation != null) {
      _controller.text = widget.initialLocation!.fullName;
      _hasSelection = true;
    }
  }

  @override
  void didUpdateWidget(HotelAutosuggestField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation) {
      if (widget.initialLocation != null) {
        _controller.text = widget.initialLocation!.fullName;
        _hasSelection = true;
      } else {
        _controller.clear();
        _hasSelection = false;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _closeOverlay();
    _focusNode.dispose();
    _controller.dispose();
    _bloc.close();
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
        _bloc.add(SearchAkHotelLocationsEvent(trimmed));
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _selectLocation(AkHotelLocationEntity location) {
    _suppressNextOverlay = true;
    _debounce?.cancel();
    _closeOverlay();

    setState(() {
      _controller.text = location.fullName;
      _hasSelection = true;
    });
    _focusNode.unfocus();
    widget.onLocationSelected(location);

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
                    child: BlocProvider.value(
                      value: _bloc,
                      child: _buildDropdownContent(),
                    ),
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
      return _hintBox(icon: Icons.search, message: 'Type at least 2 characters to search');
    }

    return BlocBuilder<AkHotelAutosuggestBloc, AkHotelAutosuggestState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is AkHotelAutosuggestLoading) {
          return Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AkHotelAutosuggestFailed) {
          return _hintBox(
            icon: Icons.error_outline,
            message: 'Unable to load destinations',
            color: Colors.red.shade400,
          );
        }

        if (state is AkHotelAutosuggestLoaded) {
          final locations = state.locations;
          if (locations.isEmpty) {
            return _hintBox(icon: Icons.info_outline, message: 'No results found');
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(2)),
                leading: Icon(
                  location.type == 'hotel' ? Icons.hotel_outlined : Icons.location_on_outlined,
                  size: context.iconMedium,
                  color: const Color(0xff0D1B3D),
                ),
                title: Text(
                  location.name,
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: const Color(0xff0D1B3D)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  location.fullName,
                  style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectLocation(location),
              );
            },
          );
        }

        return _hintBox(icon: Icons.search, message: 'Type to search destinations');
      },
    );
  }

  Widget _hintBox({required IconData icon, required String message, Color? color}) {
    return Padding(
      padding: EdgeInsets.all(context.w(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconLarge, color: color ?? Colors.grey.shade400),
          SizedBox(height: context.h(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.bodySmall, color: color ?? Colors.grey.shade600),
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
                hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFB8BEC9)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: context.h(4)),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF071638)),
              onChanged: _onSearchChanged,
            ),
          ),
          _hasSelection
              ? GestureDetector(
                  onTap: _clearSelection,
                  child: Icon(Icons.clear, size: context.iconSmall, color: const Color(0xffBCC1CA)),
                )
              : Icon(
                  _overlayEntry != null ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: context.iconMedium,
                  color: const Color(0xffBCC1CA),
                ),
        ],
      ),
    );
  }
}
