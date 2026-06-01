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
  final List<String> _tabs = ['ROOM & RATES', 'PHOTOS', 'HOTEL AMENITIES', 'MAP'];
  GoogleMapController? _mapController;
  bool _isMapLoading = false;
  bool _hasMapError = false;

  Widget? _cachedMapWidget;
  LatLng? _cachedHotelPosition;
  String? _cachedHotelName;
  String? _cachedAddress;

  @override
  void initState() {
    super.initState();
    print('HotelDetailsScreen: Initializing with hotel code: ${widget.hotelCode}');
    print('HotelDetailsScreen: Check-in: ${widget.checkIn}, Check-out: ${widget.checkOut}');
    print('HotelDetailsScreen: Adults: ${widget.adults}, Children: ${widget.children}');

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: 35,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.hotel, size: 35),
            ),
          )
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: TextStyle(fontSize: context.sp(16)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
          } else if (state is HotelDetailsLoaded && state.hotelDetails.isNotEmpty) {
            final hotel = state.hotelDetails.first;
            print('HotelDetailsScreen: Building UI for hotel - ${hotel.hotelName}');

            if (_cachedHotelPosition != hotel.hotelLatLng) {
              _cachedHotelPosition = hotel.hotelLatLng;
              _cachedHotelName = hotel.hotelName;
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
                  const SizedBox(height: 80),
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
      padding: context.responsivePadding,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotel.hotelName,
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStarRating(hotel.hotelRating),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${hotel.hotelRating} Star',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: context.sp(16), color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hotel.address,
                  style: TextStyle(
                    fontSize: context.sp(14),
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          size: context.sp(16),
        );
      }),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECK IN',
                  style: TextStyle(
                    fontSize: context.sp(10),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.checkIn,
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECK OUT',
                  style: TextStyle(
                    fontSize: context.sp(10),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.checkOut,
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROOMS & GUESTS',
                  style: TextStyle(
                    fontSize: context.sp(10),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.adults} Adult${widget.adults > 1 ? 's' : ''}${widget.children > 0 ? ', ${widget.children} Child${widget.children > 1 ? 'ren' : 'ren'}' : ''}',
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return GestureDetector(
              onTap: () {
                print('HotelDetailsScreen: Tab $index selected - ${_tabs[index]}');
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 16 : 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: context.sp(14),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.grey[600],
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
            Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Location not available', style: TextStyle(color: Colors.grey[600])),
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
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                key: const ValueKey('hotel_map'),
                initialCameraPosition: CameraPosition(
                  target: _cachedHotelPosition!,
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('hotel_location'),
                    position: _cachedHotelPosition!,
                    infoWindow: InfoWindow(
                      title: _cachedHotelName,
                      snippet: _cachedAddress,
                    ),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                onTap: (LatLng latLng) {
                  print('Map tapped at: $latLng');
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.red[400]),
              const SizedBox(width: 4),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInGoogleMaps(),
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Get Directions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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

    final url = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }
}