import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/T_locationEntity.dart';
import '../bloc/T_locationBloc.dart';
import '../bloc/T_locationEvent.dart';
import '../bloc/T_locationState.dart';

class T_locationSearchTile extends StatefulWidget {
  final String title;
  final String hint;
  final String initialSubtitle;
  final ValueChanged<T_locationEntity> onLocationSelected;

  const T_locationSearchTile({
    Key? key,
    required this.title,
    required this.hint,
    required this.initialSubtitle,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<T_locationSearchTile> createState() => _T_locationSearchTileState();
}

class _T_locationSearchTileState extends State<T_locationSearchTile> {
  late final T_locationBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  bool _isSearching = false;
  T_locationEntity? _selectedLocation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _bloc = sl<T_locationBloc>();
    _focusNode.addListener(_onFocusChange);
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
      // ✅ Always try to open overlay when focused AND has text
      if (_controller.text.isNotEmpty) {
        _openOverlay();
      }
    } else {
      _closeOverlay();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.trim().isEmpty) {
      _bloc.add(const ClearT_locationsEvent());
      _closeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    // ✅ FIX: Reopen overlay when typing (in case it was closed)
    if (_focusNode.hasFocus) {
      _openOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _bloc.add(SearchT_locationsEvent(searchQuery: query));
    });
  }

  void _selectLocation(T_locationEntity location) {
    setState(() {
      _selectedLocation = location;
      _controller.text = location.label;
      _isSearching = false;
    });
    _focusNode.unfocus();
    _closeOverlay();
    widget.onLocationSelected(location);
  }

  void _clearSelection() {
    setState(() {
      _selectedLocation = null;
      _controller.clear();
      _isSearching = false;
    });
    _focusNode.unfocus();
    _closeOverlay();
  }

  void _openOverlay() {
    // ✅ Allow reopening if overlay was closed
    if (_overlayEntry != null) {
      // Overlay already exists, just mark for rebuild
      _overlayEntry?.markNeedsBuild();
      return;
    }

    // Small delay to ensure render box is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);

        _overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            left: offset.dx,
            top: offset.dy + renderBox.size.height + 8,
            width: renderBox.size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, renderBox.size.height + 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(context.borderRadius),
                child: Container(
                  constraints: BoxConstraints(maxHeight: context.hp(25)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildDropdownContent(),
                ),
              ),
            ),
          ),
        );

        overlay.insert(_overlayEntry!);
      } catch (e) {
        print('Error opening overlay: $e');
      }
    });
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownContent() {
    return BlocBuilder<T_locationBloc, T_locationState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is T_locationsLoading || state is T_locationsSearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is T_locationsLoaded || state is T_locationsSearchLoaded) {
          final locations = state is T_locationsLoaded
              ? state.locations
              : (state as T_locationsSearchLoaded).locations;

          if (locations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.wp(4)),
                child: Text(
                  'No locations found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: context.bodyMedium,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(0.5),
                ),
                leading: Icon(
                  _getIconForType(location.type),
                  size: context.iconMedium,
                  color: const Color(0xff0D1B3D),
                ),
                title: Text(
                  location.name,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D1B3D),
                  ),
                ),
                subtitle: Text(
                  location.label,
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: location.iataCode.isNotEmpty
                    ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F6FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    location.iataCode,
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff0D1B3D),
                    ),
                  ),
                )
                    : null,
                onTap: () => _selectLocation(location),
              );
            },
          );
        }

        if (state is T_locationsError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.wp(4)),
              child: Text(
                state.message,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: context.bodySmall,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Center(
          child: Padding(
            padding: EdgeInsets.all(context.wp(4)),
            child: Text(
              'Type to search locations...',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: context.bodyMedium,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: context.labelLarge,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: context.hp(2)),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: context.iconLarge,
                color: const Color(0xff0D1B3D),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(
                      onFocusChange: (focused) {
                        if (focused) setState(() => _isSearching = true);
                      },
                      child: SizedBox(
                        height: 20,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: _selectedLocation?.label ?? widget.hint,
                            hintStyle: TextStyle(
                              fontSize: context.titleSmall,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff0D1B3D),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: _selectedLocation != null
                                ? IconButton(
                              icon: Icon(Icons.clear, size: context.iconSmall),
                              onPressed: _clearSelection,
                            )
                                : null,
                          ),
                          style: TextStyle(
                            fontSize: context.titleSmall,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff0D1B3D),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedLocation?.formattedAddress ?? widget.initialSubtitle,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    // if (_isSearching) ...[
                    //   SizedBox(height: context.hp(0.5)),
                    //   SizedBox(
                    //     height: 2,
                    //     child: LinearProgressIndicator(
                    //       backgroundColor: Colors.grey.shade200,
                    //       valueColor: AlwaysStoppedAnimation<Color>(
                    //         const Color(0xffF97316),
                    //       ),
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'airport':
        return Icons.airplanemode_active;
      case 'port':
        return Icons.directions_boat;
      case 'city':
        return Icons.location_city;
      case 'place':
        return Icons.place;
      default:
        return Icons.location_on_outlined;
    }
  }
}