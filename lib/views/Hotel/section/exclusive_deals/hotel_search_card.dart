import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../injection_container.dart';
import '../../../Hotel_Details/presentation/screens/widgets/room_config.dart';
import '../../../Hotel_api/presentation/bloc/hotel_bloc.dart';
import '../../../flight_destination/domain/entities/destination_entity.dart';
import '../../../flight_destination/presentation/widget/destination_search_field.dart';
import '../../Listing/hotel_listing.dart';


class HotelSearchCard extends StatefulWidget {
  const HotelSearchCard({super.key});

  @override
  State<HotelSearchCard> createState() => _HotelSearchCardState();
}

class _HotelSearchCardState extends State<HotelSearchCard> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  DestinationEntity? _selectedDestination;
  String _guestNationality = 'India';

  List<RoomConfig> _rooms = [RoomConfig()];


  final FocusNode _destinationFocusNode = FocusNode();
  final FocusNode _nationalityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Auto-select dates on initialization
    _checkInDate = DateTime.now();
    _checkOutDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _destinationFocusNode.dispose();
    _nationalityFocusNode.dispose();
    super.dispose();
  }

  String _getRoomSummary() {
    int totalAdults = _rooms.fold(0, (sum, room) => sum + room.adults);
    int totalChildren = _rooms.fold(0, (sum, room) => sum + room.children);
    int totalGuests = totalAdults + totalChildren;

    if (_rooms.length == 1) {
      return '${_rooms.length} Room, $totalGuests Guest${totalGuests > 1 ? 's' : ''}';
    }
    return '${_rooms.length} Rooms, $totalGuests Guests';
  }

  void _showRoomSelectionModal() {
    List<RoomConfig> tempRooms = _rooms.map((room) => room.copy()).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.wp(5),
                vertical: context.hp(2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: context.hp(60),
                ),
                child: Column(
                  children: [
                    _buildModalHeader(() {
                      setState(() {
                        _rooms = tempRooms;
                      });
                      Navigator.pop(context);
                    }),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: tempRooms.length,
                        itemBuilder: (context, index) {
                          return _buildRoomConfigCard(
                            tempRooms,
                            index,
                            setModalState,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(context.gapMedium),
                      child: TextButton.icon(
                        onPressed: tempRooms.length < 5
                            ? () {
                          setModalState(() {
                            tempRooms.add(RoomConfig());
                          });
                        }
                            : null,
                        icon: Icon(Icons.add_circle_outline),
                        label: Text('Add another room'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    ),
                    SizedBox(height: context.gapMedium),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalHeader(VoidCallback onApply) {
    return Container(
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Text(
            'Rooms & Guests',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomConfigCard(
      List<RoomConfig> rooms,
      int index,
      StateSetter setModalState,
      ) {
    RoomConfig room = rooms[index];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapSmall,
      ),
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Room ${index + 1}',
                style: TextStyle(
                  fontSize: context.titleSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (rooms.length > 1)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setModalState(() {
                      rooms.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          _buildCounterRow(
            title: 'Adults',
            subtitle: 'Above 12 years',
            count: room.adults,
            onIncrement: () => setModalState(() => room.adults++),
            onDecrement: () {
              if (room.adults > 1) setModalState(() => room.adults--);
            },
          ),
          SizedBox(height: context.gapMedium),

          _buildCounterRow(
            title: 'Children',
            subtitle: 'Ages 1-12 years',
            count: room.children,
            onIncrement: () {
              if (room.children < 4) {
                setModalState(() {
                  room.addChild(8);
                });
              }
            },
            onDecrement: () {
              setModalState(() => room.removeChild());
            },
          ),

          if (room.children > 0) ...[
            SizedBox(height: context.gapMedium),
            Divider(color: Colors.grey.shade200),
            SizedBox(height: context.gapSmall),
            Text(
              'Children Ages',
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.gapSmall),
            ...List.generate(room.children, (childIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: context.gapSmall),
                child: Row(
                  children: [
                    Text(
                      'Child ${childIndex + 1}',
                      style: TextStyle(fontSize: context.bodySmall),
                    ),
                    SizedBox(width: context.gapMedium),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: room.childAges[childIndex],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.gapSmall,
                            vertical: context.gapXSmall,
                          ),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map((age) => DropdownMenuItem(
                          value: age,
                          child: Text('$age years'),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              room.updateChildAge(childIndex, value);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: context.wp(8),
                height: context.wp(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.remove, size: context.iconSmall),
              ),
            ),
            SizedBox(width: context.gapMedium),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: context.gapMedium),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: context.wp(8),
                height: context.wp(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  size: context.iconSmall,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(
      BuildContext context,
      bool isCheckIn,
      ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? DateTime.now())
          : (_checkOutDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          if (_checkInDate != null && picked.isBefore(_checkInDate!)) {
            _checkOutDate = _checkInDate!.add(const Duration(days: 1));
          } else {
            _checkOutDate = picked;
          }
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat("d MMM'yy").format(date);
  }

  String _formatDay(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE').format(date);
  }

  void _onSearchPressed() {
    // Validation
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('SEARCH CLICKED');
    print('Destination: ${_selectedDestination?.displayName}');
    print('Destination Type: ${_selectedDestination?.type}');
    print('Check-in: $_checkInDate');
    print('Check-out: $_checkOutDate');
    // print('Guests: $_room adults, $_children children');
    int totalAdults = _rooms.fold(0, (sum, room) => sum + room.adults);
    int totalChildren = _rooms.fold(0, (sum, room) => sum + room.children);
    print('Guests: $totalAdults adults, $totalChildren children');
    print('Rooms: ${_rooms.length}');
    print('Rooms: $_rooms');

    final checkInFormatted = DateFormat('yyyy-MM-dd').format(_checkInDate!);
    final checkOutFormatted = DateFormat('yyyy-MM-dd').format(_checkOutDate!);

    // Get the city code based on destination type
    String cityCode;
    if (_selectedDestination!.type == DestinationType.hotel) {

      cityCode = _selectedDestination!.cityCode ?? '';
      print('Hotel selected - using cityCode: $cityCode');
    } else {
      cityCode = _selectedDestination!.id;
      print('City selected - using id: $cityCode');
    }

    final paxRooms = List.generate(_rooms.length, (index) {
      final room = _rooms[index];
      return {
        'Adults': room.adults,
        'Children': room.children,
        'ChildrenAges': List.generate(room.children, (childIndex) => room.childAges[childIndex]),
      };
    });

    // Navigate with BlocProvider
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => sl<HotelBloc>(),
          child: HotelListingScreen(
            cityCode: cityCode,  // Now this will have the correct city code
            checkIn: checkInFormatted,
            checkOut: checkOutFormatted,
            guestNationality: 'IN',
            paxRooms: paxRooms,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TOP TWO FIELDS
          Row(
            children: [
              Expanded(
                child: _buildNationalityField(context),
              ),
              Container(
                width: 1,
                height: context.hp(12),
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildDestinationField(context),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          /// DATE SECTION
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  title: 'Check-In',
                  date: _formatDate(_checkInDate),
                  day: _formatDay(_checkInDate),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: _buildDateField(
                  context,
                  title: 'Check-Out',
                  date: _formatDate(_checkOutDate),
                  day: _formatDay(_checkOutDate),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          /// ROOM + BUTTON
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showRoomSelectionModal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROOMS & GUESTS',
                        style: TextStyle(
                          fontSize: context.labelMedium,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: context.gapSmall),
                      Text(
                        _getRoomSummary(),
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.gapSmall),
                      Text(
                        'Tap to configure',
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: SizedBox(
                  height: context.buttonHeight + 10,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.borderRadius),
                      ),
                    ),
                    onPressed: _onSearchPressed,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SEARCH',
                          style: TextStyle(
                            fontSize: context.labelLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: context.gapSmall),
                        const Icon(Icons.search, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNationalityField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'GUEST NATIONALITY'.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.labelMedium,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: context.iconMedium,
                color: Colors.grey.shade600,
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          GestureDetector(
            onTap: () => _showNationalityPicker(context),
            child: Text(
              _guestNationality,
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'For rates & pricing',
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ENTER YOUR DESTINATION'.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.labelMedium,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: context.iconMedium,
                color: Colors.grey.shade600,
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          DestinationSearchField(
            label: 'Enter destination',
            hint: 'Select Destination...',
            onDestinationSelected: (destination) {
              setState(() {
                _selectedDestination = destination;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      BuildContext context, {
        required String title,
        required String date,
        required String day,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: context.iconSmall,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: context.gapSmall),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: context.labelMedium,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          Text(
            date,
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
              color: date == 'Select Date' ? Colors.grey.shade400 : Colors.black,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            day,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showNationalityPicker(BuildContext context) {
    final List<String> nationalities = [
      'India',
      'United States',
      'United Kingdom',
      'United Arab Emirates',
      'Australia',
      'Canada',
      'Germany',
      'France',
      'Singapore',
      'Malaysia',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(context.gapMedium),
                child: Text(
                  'Select Nationality',
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: nationalities.length,
                  itemBuilder: (context, index) {
                    final nationality = nationalities[index];
                    return ListTile(
                      title: Text(nationality),
                      trailing: _guestNationality == nationality
                          ? Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          _guestNationality = nationality;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}