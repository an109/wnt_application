import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Hotel_Details/presentation/screens/widgets/amenities.dart';
import 'package:wander_nova/views/Hotel_Details/presentation/screens/widgets/photo_gallery_section.dart';
import 'package:wander_nova/views/Hotel_Details/presentation/screens/widgets/room&rates_section.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../common_widgets/logo.dart';
import '../../domain/entities/hotel_details_entity.dart';
import '../bloc/hotel_details_bloc.dart';
import '../bloc/hotel_details_event.dart';
import '../bloc/hotel_details_state.dart';

class HotelDetailsScreen extends StatefulWidget {
  final String hotelCode;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;

  const HotelDetailsScreen({
    super.key,
    required this.hotelCode,
    required this.checkIn,
    required this.checkOut,
    this.adults = 1,
    this.children = 0,
  });

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Rooms', 'Photos', 'Amenities', 'Map'];
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _border = Color(0xFFE2E7F0);
  static const _muted = Color(0xFF6B7280);

  Widget? _cachedMapWidget;
  LatLng? _cachedHotelPosition;
  String? _cachedAddress;

  @override
  void initState() {
    super.initState();
    print(
      'HotelDetailsScreen: Initializing with hotel code: ${widget.hotelCode}',
    );
    print(
      'HotelDetailsScreen: Check-in: ${widget.checkIn}, Check-out: ${widget.checkOut}',
    );
    print(
      'HotelDetailsScreen: Adults: ${widget.adults}, Children: ${widget.children}',
    );

    // Fetch hotel details on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelDetailsBloc>().add(
        FetchHotelDetailsEvent(
          hotelCode: widget.hotelCode,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          language: 'en',
          guestNationality: 'IN',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.h(35),
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.hotel, size: context.w(35)),
            ),
          ),
        ],
      ),
      body: BlocConsumer<HotelDetailsBloc, HotelDetailsState>(
        listener: (context, state) {
          if (state is HotelDetailsError) {
            print('HotelDetailsScreen: Error occurred - ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HotelDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HotelDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: context.w(56), color: Colors.red),
                  SizedBox(height: context.h(16)),
                  Text(
                    'Error: ${state.message}',
                    style: TextStyle(fontSize: context.sp(16)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.h(16)),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HotelDetailsBloc>().add(
                        FetchHotelDetailsEvent(
                          hotelCode: widget.hotelCode,
                          checkIn: widget.checkIn,
                          checkOut: widget.checkOut,
                        ),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is HotelDetailsLoaded &&
              state.hotelDetails.isNotEmpty) {
            final hotel = state.hotelDetails.first;
            print(
              'HotelDetailsScreen: Building UI for hotel - ${hotel.hotelName}',
            );

            if (_cachedHotelPosition != hotel.hotelLatLng) {
              _cachedHotelPosition = hotel.hotelLatLng;
              _cachedAddress = hotel.address;
              _cachedMapWidget = null; // Invalidate cache when position changes
            }

            return SingleChildScrollView(
              physics: context.scrollPhysics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoGallerySection(
                    images: hotel.images,
                    hotelName: hotel.hotelName,
                    rating: hotel.hotelRating,
                  ),
                  _buildHotelInfo(hotel),
                  _buildTabs(),
                  _buildTabContent(hotel),
                  SizedBox(height: context.h(60)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      // floatingActionButton: _selectedTabIndex == 0 ? _buildChooseRoomButton() : null,
    );
  }

  Widget _buildHotelInfo(hotel) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsivePadding.left,
        context.gapLarge,
        context.responsivePadding.right,
        context.gapMedium,
      ),
      color: _pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotel.hotelName,
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w800,
              color: _navy,
              height: 1.15,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              _buildStarRating(hotel.hotelRating),
              SizedBox(width: context.w(10)),
              // Container(
              //   padding: EdgeInsets.symmetric(
              //     horizontal: context.w(10),
              //     vertical: context.h(6),
              //   ),
              //   decoration: BoxDecoration(
              //     color: Colors.amber,
              //     borderRadius: BorderRadius.circular(context.r(10)),
              //   ),
              //   child: Text(
              //     '${hotel.hotelRating} Star',
              //     style: TextStyle(
              //       color: Colors.white,
              //       fontSize: context.fs(11),
              //       fontWeight: FontWeight.w800,
              //     ),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: context.w(16), color: _muted),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  hotel.address,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: _muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          _buildBookingInfo(),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: context.w(15),
        );
      }),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border.withValues(alpha: 0.5), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.05),
            blurRadius: context.r(16),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final items = [
            _BookingInfoItem(label: 'Check in', value: widget.checkIn),
            _BookingInfoItem(label: 'Check out', value: widget.checkOut),
            _BookingInfoItem(
              label: 'Guests',
              value:
                  '${widget.adults} Adult${widget.adults > 1 ? 's' : ''}${widget.children > 0 ? ', ${widget.children} Child${widget.children > 1 ? 'ren' : ''}' : ''}',
            ),
          ];
          if (compact) {
            return Wrap(
              spacing: context.w(10),
              runSpacing: context.h(10),
              children: items
                  .map(
                    (item) => SizedBox(
                      width: (constraints.maxWidth - context.w(10)) / 2,
                      child: item,
                    ),
                  )
                  .toList(),
            );
          }
          return Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(child: items[i]),
                if (i != items.length - 1)
                  Container(
                    width: 0.6,
                    height: context.h(34),
                    margin: EdgeInsets.symmetric(horizontal: context.w(4)),
                    color: _border.withValues(alpha: 0.5),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: _pageBg,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Padding(
              // Gap between tab pills (MMT style)
              padding: EdgeInsets.only(right: context.w(10)),
              child: GestureDetector(
                onTap: () {
                  print(
                    'HotelDetailsScreen: Tab $index selected - ${_tabs[index]}',
                  );
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(18),
                    vertical: context.h(9),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _blue : Colors.white,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(
                      color: isSelected ? _blue : _border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _blue.withValues(alpha: 0.25),
                              blurRadius: context.r(10),
                              offset: Offset(0, context.h(4)),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _muted,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(hotel) {
    switch (_selectedTabIndex) {
      case 0:
        return RoomsRatesSection(
          hotelCode: hotel.hotelCode,
          hotelName: hotel.hotelName,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          adults: widget.adults,
          children: widget.children,
          hotelFees: hotel.hotelFees,
          rooms: hotel.searchRooms,
          hotelDetails: hotel,
        );
      case 1:
        return PhotoGallerySection(
          images: hotel.images,
          hotelName: hotel.hotelName,
          rating: hotel.hotelRating,
          showMainImage: false,
        );
      case 2:
        return AmenitiesSection(
          hotelFacilities: hotel.hotelFacilities,
          attractions: hotel.attractions,
        );
      case 3:
        if (_cachedMapWidget == null && _cachedHotelPosition != null) {
          _cachedMapWidget = _buildMapSectionContent();
        }
        return _cachedMapWidget ?? const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMapSectionContent() {
    if (_cachedHotelPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: context.w(44), color: Colors.grey[400]),
            SizedBox(height: context.h(8)),
            Text(
              'Location not available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: context.responsivePadding,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              fontSize: context.titleSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.h(12)),
          Container(
            height: context.h(220),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(context.r(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: context.r(8),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.r(12)),
              child: InkWell(
                onTap: _openInGoogleMaps,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.r(12)),
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.location_on,
                          size: context.w(64),
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Icon(Icons.location_on, size: context.w(16), color: Colors.red[400]),
              SizedBox(width: context.w(4)),
              Expanded(
                child: Text(
                  _cachedAddress ?? '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: context.sp(14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInGoogleMaps(),
              icon: Icon(Icons.directions, size: context.w(16)),
              label: const Text('Get Directions'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.h(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to open in external Google Maps app
  void _openInGoogleMaps() async {
    final position = _cachedHotelPosition;
    if (position == null) return;

    final url =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }
}

class _BookingInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _BookingInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(10),
              color: _HotelDetailsScreenState._muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: context.h(3)),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(13),
              color: _HotelDetailsScreenState._navy,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
