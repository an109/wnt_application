import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/VisaDestination/presentation/bloc/visaDestin_event.dart';
import 'package:wander_nova/views/VisaDestination/presentation/bloc/visaDestin_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entity/visaDestin_Entity.dart';
import '../bloc/visaDestin_bloc.dart';


class VisaDestinationSearchTile extends StatefulWidget {
  final String title;
  final String hint;
  final ValueChanged<VisaDestinationEntity> onDestinationSelected;

  const VisaDestinationSearchTile({
    Key? key,
    required this.title,
    required this.hint,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  State<VisaDestinationSearchTile> createState() => _VisaDestinationSearchTileState();
}

class _VisaDestinationSearchTileState extends State<VisaDestinationSearchTile> {
  late final VisaDestinationBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  bool _isSearching = false;
  VisaDestinationEntity? _selectedDestination;
  OverlayEntry? _overlayEntry;
  List<VisaDestinationEntity> _allDestinations = [];

  @override
  void initState() {
    super.initState();
    _bloc = sl<VisaDestinationBloc>();
    _focusNode.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc.add(const LoadVisaDestinations());
    });
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
      if (_controller.text.isNotEmpty) {
        _openOverlay();
        _filterDestinations(_controller.text);
      } else {
        _openOverlay();
      }
    } else {
      _closeOverlay();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.trim().isEmpty) {
      _filterDestinations('');
      return;
    }

    setState(() => _isSearching = true);

    if (_focusNode.hasFocus) {
      _openOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterDestinations(query);
    });
  }

  void _filterDestinations(String query) {
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    final filtered = _allDestinations
        .where((dest) => dest.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() => _isSearching = false);

    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _selectDestination(VisaDestinationEntity destination) {
    setState(() {
      _selectedDestination = destination;
      _controller.text = destination.name;
      _isSearching = false;
    });
    _focusNode.unfocus();
    _closeOverlay();
    widget.onDestinationSelected(destination);
  }

  void _clearSelection() {
    setState(() {
      _selectedDestination = null;
      _controller.clear();
      _isSearching = false;
    });
    _focusNode.unfocus();
    _closeOverlay();
  }

  void _openOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);

        _overlayEntry = OverlayEntry(
          builder: (overlayContext) => GestureDetector(
            //  Tap outside to close overlay
            onTap: () {
              _closeOverlay();
              _focusNode.unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: MediaQuery.of(overlayContext).size.width,
              height: MediaQuery.of(overlayContext).size.height,
              child: Stack(
                children: [
                  // Transparent overlay area (closes on tap)
                  Container(color: Colors.transparent),

                  // Dropdown positioned below the search field
                  Positioned(
                    left: offset.dx,
                    top: offset.dy + renderBox.size.height + 8,
                    width: renderBox.size.width,
                    child: CompositedTransformFollower(
                      link: _layerLink,
                      showWhenUnlinked: false,
                      offset: Offset(0, renderBox.size.height + 8),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                        child: Container(
                          constraints: BoxConstraints(maxHeight: context.hp(25)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
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
                ],
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
    return BlocBuilder<VisaDestinationBloc, VisaDestinationState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is VisaDestinationLoading && _allDestinations.isEmpty) {
          return SizedBox(
            height: context.hp(15),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is VisaDestinationLoaded) {
          if (_allDestinations.isEmpty) {
            _allDestinations = state.destinations;
          }

          final query = _controller.text.trim().toLowerCase();
          final destinations = query.isEmpty
              ? _allDestinations
              : _allDestinations
              .where((dest) => dest.name.toLowerCase().contains(query))
              .toList();

          if (destinations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.wp(4)),
                child: Text(
                  query.isEmpty ? 'No destinations available' : 'No countries found',
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
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(0.5),
                ),
                //  Only show country name - no price, region, or extra data
                title: Text(
                  destination.name,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D1B3D),
                  ),
                ),
                onTap: () => _selectDestination(destination),
              );
            },
          );
        }

        if (state is VisaDestinationError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.wp(4)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: context.iconLarge,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(height: context.hp(1)),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: context.bodySmall,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.hp(2)),
                  ElevatedButton(
                    onPressed: () {
                      _bloc.add(const LoadVisaDestinations());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00A19A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(4),
                        vertical: context.hp(1),
                      ),
                    ),
                    child: Text('Retry', style: TextStyle(fontSize: context.bodyMedium)),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: Padding(
            padding: EdgeInsets.all(context.wp(4)),
            child: Text(
              'Start typing to search countries...',
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
          if (widget.title.isNotEmpty) ...[
            Text(
              widget.title,
              style: TextStyle(
                fontSize: context.labelLarge,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                letterSpacing: context.letterSpacingWide,
              ),
            ),
            SizedBox(height: context.hp(2)),
          ],
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
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
                        height: context.hp(2.5),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: _selectedDestination?.name ?? widget.hint,
                            hintStyle: TextStyle(
                              fontSize: context.titleSmall,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff0D1B3D),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: _selectedDestination != null
                                ? IconButton(
                              icon: Icon(Icons.clear, size: context.iconSmall),
                              onPressed: _clearSelection,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                    //  Removed the subtitle/preview text below the input
                    if (_isSearching && _controller.text.isNotEmpty) ...[
                      SizedBox(height: context.hp(0.5)),
                      SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff00A19A)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}