import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Hotel_Details/presentation/screens/widgets/room_card.dart';
import '../../../../../injection_container.dart';
import '../../../../Hotel_Booking/presentation/bloc/hotel_booking_bloc.dart';
import '../../../../Hotel_Booking/presentation/screen/hotel_booking_review_screen.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../domain/entities/hotel_details_entity.dart';
import '../../../domain/entities/rooms_entity.dart';
import 'hotel_fees_section.dart';

class RoomsRatesSection extends StatefulWidget {
  final String hotelCode;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final HotelFeesEntity? hotelFees;
  final List<RoomEntity> rooms;
  final HotelDetailsEntity? hotelDetails;
  final String? hotelDescription;

  const RoomsRatesSection({
    super.key,
    required this.hotelCode,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    this.hotelFees,
    required this.rooms,
    this.hotelDetails,
    this.hotelDescription,
  });

  @override
  State<RoomsRatesSection> createState() => _RoomsRatesSectionState();
}

class _RoomsRatesSectionState extends State<RoomsRatesSection> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Room Only', 'Breakfast', 'Half Board', 'Full Board'];
  final TextEditingController _searchController = TextEditingController();
  List<RoomEntity> _filteredRooms = [];

  @override
  void initState() {
    super.initState();
    print('RoomsRatesSection: Initialized for hotel ${widget.hotelName}');
    print('RoomsRatesSection: Received ${widget.rooms.length} rooms from API');
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoomsRatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rooms != widget.rooms) {
      print('RoomsRatesSection: Rooms updated, reapplying filters');
      _applyFilters();
    }
  }

  void _applyFilters() {
    print('RoomsRatesSection: Applying filter: $_selectedFilter, search: "${_searchController.text}"');

    List<RoomEntity> filtered = List.from(widget.rooms);

    // Apply meal type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((room) {
        final mealType = room.mealType.toLowerCase();
        switch (_selectedFilter.toLowerCase()) {
          case 'room only':
            return mealType == 'room_only';
          case 'breakfast':
            return mealType == 'breakfast' || mealType == 'breakfast_for_2' || mealType == 'break_fast';
          case 'half board':
            return mealType == 'half_board';
          case 'full board':
            return mealType == 'full_board';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((room) {
        final roomName = room.name.join(' ').toLowerCase();
        final inclusion = room.inclusion.toLowerCase();
        return roomName.contains(searchQuery) || inclusion.contains(searchQuery);
      }).toList();
    }

    setState(() {
      _filteredRooms = filtered;
    });

    print('RoomsRatesSection: Filtered to ${_filteredRooms.length} rooms');
  }

  @override
  Widget build(BuildContext context) {
    print('RoomsRatesSection: Building with ${_filteredRooms.length} visible rooms');

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          // _buildSearchBar(),
          _buildRoomCount(),
          _buildRoomList(),
          if (widget.hotelFees != null)
            HotelFeesWidget(hotelFees: widget.hotelFees!),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rooms & Rates',
            style: TextStyle(
              fontSize: context.headlineMedium,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from ${widget.rooms.length} available room options',
            style: TextStyle(
              fontSize: context.sp(14),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCount() {
    if (_filteredRooms.isEmpty && widget.rooms.isNotEmpty) {
      return Container(
        padding: context.horizontalPadding.copyWith(bottom: context.gapMedium),
        child: Text(
          'No rooms match your filters',
          style: TextStyle(
            fontSize: context.sp(14),
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      // padding: context.horizontalPadding.copyWith(bottom: context.gapSmall),
      // child: Text(
      //   'Showing ${_filteredRooms.length} of ${widget.rooms.length} rooms',
      //   style: TextStyle(
      //     fontSize: context.sp(12),
      //     color: Colors.grey[500],
      //   ),
      // ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.responsivePadding.left),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        child: Row(
          children: [
            Text(
              'Filter by:',
              style: TextStyle(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            ..._filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    print('RoomsRatesSection: Filter changed to - $filter');
                    setState(() {
                      _selectedFilter = filter;
                    });
                    _applyFilters();
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.blue[50],
                  checkmarkColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Widget _buildSearchBar() {
  //   return Container(
  //     padding: context.responsivePadding,
  //     child: TextField(
  //       controller: _searchController,
  //       decoration: InputDecoration(
  //         hintText: 'Search rooms...',
  //         prefixIcon: const Icon(Icons.search),
  //         suffixIcon: _searchController.text.isNotEmpty
  //             ? IconButton(
  //           icon: const Icon(Icons.clear),
  //           onPressed: () {
  //             print('RoomsRatesSection: Search cleared');
  //             _searchController.clear();
  //             _applyFilters();
  //           },
  //         )
  //             : null,
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: BorderSide(color: Colors.grey[300]!),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: BorderSide(color: Colors.grey[300]!),
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: const BorderSide(color: Colors.blue, width: 2),
  //         ),
  //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //         isDense: true,
  //       ),
  //       onChanged: (value) {
  //         print('RoomsRatesSection: Search query - "$value"');
  //         _applyFilters();
  //       },
  //       onSubmitted: (value) {
  //         print('RoomsRatesSection: Search submitted - "$value"');
  //         _applyFilters();
  //       },
  //     ),
  //   );
  // }

  Widget _buildRoomList() {
    if (_filteredRooms.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: context.responsivePadding,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredRooms.length,
        separatorBuilder: (context, index) => SizedBox(height: context.gapMedium),
        itemBuilder: (context, index) {
          final room = _filteredRooms[index];
          return RoomCard(
            room: room,
            adults: widget.adults,
            children: widget.children,
            onSelect: () {
              print('RoomsRatesSection: Room selected - ${room.bookingCode}');

              // Get user email from AuthBloc
              final authState = context.read<AuthBloc>().state;
              String userEmail = '';
              if (authState is AuthAuthenticated) {
                userEmail = authState.user.email;
              }

              // Safe values with null checks and type conversion
              final String hotelImage = widget.hotelDetails?.image ?? '';
              final String hotelName = widget.hotelName;
              final int hotelRating = (widget.hotelDetails?.hotelRating ?? 0).toInt();
              final String address = widget.hotelDetails?.address ?? '';
              final List<String>? hotelFacilities = widget.hotelDetails?.hotelFacilities;
              final String? hotelDescription = widget.hotelDetails?.description;

              print('Hotel image is : ${widget.hotelDetails?.image}');
              print('Hotel name is : ${widget.hotelDetails?.hotelName}');
              print('Hotel rating is : ${widget.hotelDetails?.hotelRating}');
              print('Hotel address is : ${widget.hotelDetails?.address}');


              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<HotelBookingBloc>(),
                    child: HotelBookingReviewScreen(
                      bookingCode: room.bookingCode,
                      hotelImage: hotelImage,
                      hotelName: hotelName,
                      hotelRating: hotelRating,
                      address: address,
                      checkIn: widget.checkIn,
                      checkOut: widget.checkOut,
                      adults: widget.adults,
                      children: widget.children,
                      userEmail: userEmail,
                      hotelFacilities: hotelFacilities,
                      hotelDescription: hotelDescription,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: context.responsivePadding.copyWith(top: context.gapLarge, bottom: context.gapLarge),
      child: Column(
        children: [
          Icon(
            Icons.hotel_outlined,
            size: context.iconLarge * 2,
            color: Colors.grey[400],
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'No rooms found',
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Try adjusting your filters or search terms',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey[500],
            ),
          ),
          if (_selectedFilter != 'All' || _searchController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: context.gapMedium),
              child: TextButton(
                onPressed: () {
                  print('RoomsRatesSection: Clearing filters');
                  setState(() {
                    _selectedFilter = 'All';
                    _searchController.clear();
                  });
                  _applyFilters();
                },
                child: Text(
                  'Clear all filters',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}