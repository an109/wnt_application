// airport_search_dropdown.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../bloc/airport_state.dart';

class AirportSearchDropdown extends StatefulWidget {
  final String title;
  final String hint;
  final String initialSubtitle;
  final AirportEntity? selectedAirport;
  final ValueChanged<AirportEntity?> onAirportSelected;

  const AirportSearchDropdown({
    Key? key,
    required this.title,
    required this.hint,
    required this.initialSubtitle,
    this.selectedAirport,
    required this.onAirportSelected,
  }) : super(key: key);

  @override
  State<AirportSearchDropdown> createState() => _AirportSearchDropdownState();
}

class _AirportSearchDropdownState extends State<AirportSearchDropdown> {
  late final AirportBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;

  // @override
  // void initState() {
  //   super.initState();
  //   _bloc = sl<AirportBloc>();
  //   if (widget.selectedAirport != null) {
  //     _controller.text =
  //         "${widget.selectedAirport!.cityName} (${widget.selectedAirport!.airportCode})";
  //   }
  //   _focusNode.addListener(_onFocusChange);
  // }

  @override
  void initState() {
    super.initState();
    _bloc = sl<AirportBloc>();

    // Load initial airports from /flights/airports endpoint
    _bloc.add( LoadAirports());

    if (widget.selectedAirport != null) {
      _controller.text = "${widget.selectedAirport!.cityName} (${widget.selectedAirport!.airportCode})";
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AirportSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAirport != oldWidget.selectedAirport) {
      if (widget.selectedAirport != null) {
        _controller.text =
            "${widget.selectedAirport!.cityName} (${widget.selectedAirport!.airportCode})";
      } else {
        _controller.clear();
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
    super.dispose();
  }

  // void _onFocusChange() {
  //   if (_focusNode.hasFocus) {
  //     if (_controller.text.isNotEmpty) {
  //       _openOverlay();
  //     }
  //   } else {
  //     _closeOverlay();
  //   }
  // }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // When focused and text is empty, load default airports
      if (_controller.text.trim().isEmpty) {
        _bloc.add( LoadAirports()); // Loads /flights/airports
        _openOverlay();
      } else if (_controller.text.isNotEmpty) {
        _openOverlay();
      }
    } else {
      _closeOverlay();
    }
  }

  // void _onSearchChanged(String query) {
  //   if (_debounce?.isActive ?? false) _debounce?.cancel();
  //
  //   if (query.trim().isEmpty) {
  //     _closeOverlay();
  //     return;
  //   }
  //
  //   setState(() => _isSearching = true);
  //
  //   if (_focusNode.hasFocus) {
  //     _openOverlay();
  //   }
  //
  //   _debounce = Timer(const Duration(milliseconds: 500), () {
  //     // Dispatch the search event to the bloc
  //     _bloc.add(LoadAirports(searchQuery: query));
  //   });
  // }
// airport_search_dropdown.dart - Update the _onSearchChanged method

  void _onSearchChanged(String query) {
    print('AirportSearchDropdown: _onSearchChanged called with query: "$query"');

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.trim().isEmpty) {
      print('Query empty, closing overlay');
      _closeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    if (_focusNode.hasFocus) {
      _openOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = query.trim();

      // Call different API based on query length
      if (trimmedQuery.length >= 2) {
        // Search API for 2+ characters
        print('Dispatching LoadAirports with searchQuery: "$trimmedQuery"');
        _bloc.add(LoadAirports(searchQuery: trimmedQuery));
      } else {
        // Normal airports API for less than 2 characters
        print('Query too short (${trimmedQuery.length}), loading default airports');
        _bloc.add( LoadAirports()); // This calls /flights/airports
      }
    });
  }

  void _selectAirport(AirportEntity airport) {
    setState(() {
      _controller.text = "${airport.cityName} (${airport.airportCode})";
      _isSearching = false;
    });
    _focusNode.unfocus();
    _closeOverlay();
    widget.onAirportSelected(airport);
  }

  void _clearSelection() {
    setState(() {
      _controller.clear();
      _isSearching = false;
    });
    _focusNode.unfocus();
    _closeOverlay();
    widget.onAirportSelected(null);
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

  // Widget _buildDropdownContent() {
  //   return BlocBuilder<AirportBloc, AirportState>(
  //     bloc: _bloc,
  //     builder: (context, state) {
  //       // Handle loading state
  //       if (state is AirportLoading) {
  //         return const Center(
  //           child: Padding(
  //             padding: EdgeInsets.all(16.0),
  //             child: CircularProgressIndicator(),
  //           ),
  //         );
  //       }
  //
  //       // Handle loaded state with airports
  //       if (state is AirportLoaded) {
  //         final airports = state.airports;
  //
  //         if (airports.isEmpty) {
  //           return Center(
  //             child: Padding(
  //               padding: EdgeInsets.all(context.wp(4)),
  //               child: Text(
  //                 'No airports found',
  //                 style: TextStyle(
  //                   color: Colors.grey.shade600,
  //                   fontSize: context.bodyMedium,
  //                 ),
  //               ),
  //             ),
  //           );
  //         }
  //
  //         return ListView.builder(
  //           padding: EdgeInsets.zero,
  //           shrinkWrap: true,
  //           itemCount: airports.length,
  //           itemBuilder: (context, index) {
  //             final airport = airports[index];
  //             return ListTile(
  //               contentPadding: EdgeInsets.symmetric(
  //                 horizontal: context.wp(3),
  //                 vertical: context.hp(0.5),
  //               ),
  //               leading: Icon(
  //                 Icons.local_airport,
  //                 size: context.iconMedium,
  //                 color: const Color(0xff0D1B3D),
  //               ),
  //               title: Text(
  //                 "${airport.cityName}, ${airport.countryCode}",
  //                 style: TextStyle(
  //                   fontSize: context.bodyMedium,
  //                   fontWeight: FontWeight.w600,
  //                   color: const Color(0xff0D1B3D),
  //                 ),
  //               ),
  //               subtitle: Text(
  //                 "${airport.airportName} (${airport.airportCode})",
  //                 style: TextStyle(
  //                   fontSize: context.bodySmall,
  //                   color: Colors.grey.shade600,
  //                 ),
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               trailing: Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 8,
  //                   vertical: 4,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xffF5F6FA),
  //                   borderRadius: BorderRadius.circular(6),
  //                 ),
  //                 child: Text(
  //                   airport.airportCode,
  //                   style: TextStyle(
  //                     fontSize: context.labelSmall,
  //                     fontWeight: FontWeight.w700,
  //                     color: const Color(0xff0D1B3D),
  //                   ),
  //                 ),
  //               ),
  //               onTap: () => _selectAirport(airport),
  //             );
  //           },
  //         );
  //       }
  //
  //       // Handle error state
  //       if (state is AirportError) {
  //         return Center(
  //           child: Padding(
  //             padding: EdgeInsets.all(context.wp(4)),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(
  //                   Icons.error_outline,
  //                   size: context.iconLarge,
  //                   color: Colors.red.shade400,
  //                 ),
  //                 SizedBox(height: context.hp(1)),
  //                 Text(
  //                   state.message,
  //                   style: TextStyle(
  //                     color: Colors.red.shade700,
  //                     fontSize: context.bodySmall,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       }
  //
  //       // Initial state - no search performed yet
  //       return Center(
  //         child: Padding(
  //           padding: EdgeInsets.all(context.wp(4)),
  //           child: Text(
  //             'Type to search airports...',
  //             style: TextStyle(
  //               color: Colors.grey.shade500,
  //               fontSize: context.bodyMedium,
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  Widget _buildDropdownContent() {
    return BlocBuilder<AirportBloc, AirportState>(
      bloc: _bloc,
      builder: (context, state) {
        print(' Dropdown building with state: ${state.runtimeType}');

        if (state is AirportLoading) {
          print(' Showing loading indicator');
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AirportLoaded) {
          final airports = state.airports;
          print(' AirportLoaded with ${airports.length} airports');

          if (airports.isEmpty) {
            // Show different message based on whether user was searching
            final String currentQuery = _controller.text.trim();
            if (currentQuery.isNotEmpty && currentQuery.length < 2) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(context.wp(4)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: context.iconLarge,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(height: context.hp(1)),
                      Text(
                        'Type at least 2 characters to search',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: context.bodyMedium,
                        ),
                        textAlign: TextAlign.center,
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
                  'No airports found',
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
            itemCount: airports.length,
            itemBuilder: (context, index) {
              final airport = airports[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(0.5),
                ),
                leading: Icon(
                  Icons.local_airport,
                  size: context.iconMedium,
                  color: const Color(0xff0D1B3D),
                ),
                title: Text(
                  "${airport.cityName}, ${airport.countryCode}",
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D1B3D),
                  ),
                ),
                subtitle: Text(
                  "${airport.airportName} (${airport.airportCode})",
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F6FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    airport.airportCode,
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff0D1B3D),
                    ),
                  ),
                ),
                onTap: () => _selectAirport(airport),
              );
            },
          );
        }

        if (state is AirportError) {
          print(' AirportError: ${state.message}');
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
                    'Unable to load airports',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: context.bodySmall,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Initial state - no search performed yet
        return Center(
          child: Padding(
            padding: EdgeInsets.all(context.wp(4)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search,
                  size: context.iconLarge,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: context.hp(1)),
                Text(
                  'Type airport name or code\n(at least 2 characters)',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: context.bodyMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
          SizedBox(height: context.hp(0)),
          Row(
            children: [
              Icon(
                widget.title == "FROM"
                    ? Icons.flight_takeoff
                    : Icons.flight_land,
                size: context.iconMedium,
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
                        height: 18,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle: TextStyle(
                              fontSize: context.titleSmall,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff0D1B3D).withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: widget.selectedAirport != null
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: context.iconSmall,
                                    ),
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
                    const SizedBox(height: 0),
                    Text(
                      widget.selectedAirport?.airportName ??
                          widget.initialSubtitle,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
