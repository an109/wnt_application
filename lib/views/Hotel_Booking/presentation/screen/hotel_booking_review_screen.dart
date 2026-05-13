import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/about_hotel_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/booking_header_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/contact_info_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/fare_details_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/hotel_facilities_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/policies_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/room_amenities_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/room_info_section.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/screen/widgets/traveller_details_section.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../bloc/hotel_booking_bloc.dart';
import '../bloc/hotel_booking_event.dart';
import '../bloc/hotel_booking_state.dart';


class HotelBookingReviewScreen extends StatefulWidget {
  final String bookingCode;
  final String hotelImage;
  final String hotelName;
  final int hotelRating;
  final String address;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final String userEmail;
  final List<String>? hotelFacilities;
  final String? hotelDescription;

  const HotelBookingReviewScreen({
    super.key,
    required this.bookingCode,
    required this.hotelImage,
    required this.hotelName,
    required this.hotelRating,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.userEmail,
    this.hotelFacilities,
    this.hotelDescription,
  });

  @override
  State<HotelBookingReviewScreen> createState() => _HotelBookingReviewScreenState();
}

class _HotelBookingReviewScreenState extends State<HotelBookingReviewScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    print('HotelBookingReviewScreen: Initializing with booking code: ${widget.bookingCode}');
    print('HotelBookingReviewScreen: Hotel facilities count: ${widget.hotelFacilities?.length ?? 0}');

    // Fetch hotel booking details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelBookingBloc>().add(
        GetHotelBookingDetailsEvent(
          bookingCode: widget.bookingCode,
          paymentMode: 'Limit',
        ),
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      body: BlocConsumer<HotelBookingBloc, HotelBookingState>(
        listener: (context, state) {
          if (state is HotelBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HotelBookingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HotelBookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.errorMessage}',
                    style: TextStyle(fontSize: context.sp(16)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HotelBookingBloc>().add(
                        GetHotelBookingDetailsEvent(
                          bookingCode: widget.bookingCode,
                          paymentMode: 'Limit',
                        ),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is HotelBookingLoaded) {
            final bookingData = state.hotelBooking;
            final hotelResult = bookingData.hotelResult.isNotEmpty
                ? bookingData.hotelResult.first
                : null;

            if (hotelResult == null || hotelResult.rooms.isEmpty) {
              return const Center(
                child: Text('No booking data available'),
              );
            }

            final room = hotelResult.rooms.first;

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: context.scrollPhysics,
                  child: Padding(
                    padding: context.responsivePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookingHeaderSection(
                          hotelImage: widget.hotelImage,
                          hotelName: widget.hotelName,
                          hotelRating: widget.hotelRating,
                          address: widget.address,
                          checkIn: widget.checkIn,
                          checkOut: widget.checkOut,
                          adults: widget.adults,
                          children: widget.children,
                          roomName: room.name.isNotEmpty ? room.name.first : '',
                          isRefundable: room.isRefundable,
                        ),
                        const SizedBox(height: 16),
                        TravellerDetailsSection(
                          userEmail: widget.userEmail,
                          adults: widget.adults,
                        ),
                        const SizedBox(height: 16),
                        ContactInfoSection(
                          userEmail: widget.userEmail,
                        ),
                        const SizedBox(height: 16),
                        RoomInfoSection(
                          room: room,
                          currency: hotelResult.currency,
                        ),
                        const SizedBox(height: 16),
                        PoliciesSection(
                          cancelPolicies: room.cancelPolicies,
                          rateConditions: hotelResult.rateConditions,
                        ),
                        const SizedBox(height: 16),
                        RoomAmenitiesSection(
                          amenities: room.amenities,
                        ),
                        const SizedBox(height: 16),
                        if (widget.hotelFacilities != null && widget.hotelFacilities!.isNotEmpty) ...[
                          HotelFacilitiesSection(
                            facilities: widget.hotelFacilities!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (widget.hotelDescription != null && widget.hotelDescription!.isNotEmpty) ...[
                          AboutHotelSection(
                            description: widget.hotelDescription!,
                            hotelName: widget.hotelName,
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 16),
                        FareDetailsSection(
                          room: room,
                          currency: hotelResult.currency,
                          bookingCode: widget.bookingCode,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: AnimatedOpacity(
                    opacity: _showScrollToTop ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ),
                ),
                // Positioned(
                //   left: 0,
                //   right: 0,
                //   bottom: 0,
                //   child: FareDetailsSection(
                //     room: room,
                //     currency: hotelResult.currency,
                //     bookingCode: widget.bookingCode,
                //   ),
                // ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}