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
import 'package:wander_nova/views/Hotel_Payment/hotel_payment_screen.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/hotel_booking_entity.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/services/hotel_session_service.dart';
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
  State<HotelBookingReviewScreen> createState() =>
      _HotelBookingReviewScreenState();
}

class _HotelBookingReviewScreenState extends State<HotelBookingReviewScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  double _scrollThreshold = 300;
  static const _pageBg = Color(0xFFF3F6FC);
  HotelResultEntity? _hotelResult;

  final GlobalKey<TravellerDetailsSectionState> _travellerKey =
  GlobalKey<TravellerDetailsSectionState>();
  final GlobalKey<ContactInfoSectionState> _contactKey =
  GlobalKey<ContactInfoSectionState>();

  double? _inrBasePrice;
  double? _inrTax;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _scrollThreshold = context.h(300);
        });
      }
    });

    print(
      'HotelBookingReviewScreen: Initializing with booking code: ${widget.bookingCode}',
    );
    print(
      'HotelBookingReviewScreen: Hotel facilities count: ${widget.hotelFacilities?.length ?? 0}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelBookingBloc>().add(
        GetHotelBookingDetailsEvent(
          bookingCode: widget.bookingCode,
          paymentMode: 'Limit',
        ),
      );
    });

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted) return;

    if (_scrollController.offset > _scrollThreshold && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= _scrollThreshold && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _convertPrices(RoomEntity room, String currency) async {
    if (!mounted) return;

    setState(() {
      _inrBasePrice = room.basePrice;
      _inrTax = room.totalTax;
      _isConverting = false;
    });
  }

  Future<void> _navigateToPayment(
      RoomEntity room,
      String originalCurrency,
      ) async {
    final expired = await HotelSessionService.instance.isSessionExpired();

    if (expired && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'Your hotel search session has expired (15-minute limit). '
                'Please go back and search again to get fresh pricing.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
      return;
    }

    // Get traveller details - NO HARDCODED VALUES
    final travellerData = _travellerKey.currentState?.getFirstAdultData() ?? ['', '', ''];
    final phone = _contactKey.currentState?.phone ?? '';
    final email = _contactKey.currentState?.email ?? widget.userEmail;

    // --- VALIDATION CHECKS ---

    // Check phone number
    if (phone.isEmpty) {
      _scrollToSection(_contactKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check traveller details - using actual values from the form
    final String title = travellerData[0];
    final String firstName = travellerData[1];
    final String lastName = travellerData[2];

    // Title validation - empty string means user hasn't selected anything
    if (title.isEmpty) {
      _scrollToSection(_travellerKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a title for the traveller'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (firstName.isEmpty) {
      _scrollToSection(_travellerKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the first name for the traveller'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (lastName.isEmpty) {
      _scrollToSection(_travellerKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the last name for the traveller'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check Date of Birth
    final dobController = _travellerKey.currentState?.getDobController();
    if (dobController == null || dobController.text.isEmpty) {
      _scrollToSection(_travellerKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the date of birth for the traveller'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // --- END VALIDATION ---

    final prefs = di.sl<PreferencesManager>();
    final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';

    final totalOriginal =
        (_inrBasePrice ?? room.basePrice) + (_inrTax ?? room.totalTax);

    print('Original amount: $totalOriginal $originalCurrency');

    double finalAmount = totalOriginal;
    String finalCurrency = originalCurrency;

    if (preferredCurrency.toUpperCase() != originalCurrency.toUpperCase()) {
      try {
        finalAmount = await CurrencyConverter.convert(
          amount: totalOriginal,
          fromCurrency: originalCurrency,
          toCurrency: preferredCurrency,
        );
        finalCurrency = preferredCurrency;
        print(
          'Converted: $totalOriginal $originalCurrency -> $finalAmount $finalCurrency',
        );
      } catch (e) {
        print('Conversion failed: $e');
      }
    } else {
      print('No conversion needed: $totalOriginal $originalCurrency');
    }

    final hotelCode = _hotelResult?.hotelCode ?? '';
    final hotelCity = '';
    final hotelCountry = '';
    final hotelAddress = widget.address;
    final hotelStars = widget.hotelRating;
    final hotelImage = widget.hotelImage;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelPaymentScreen(
          bookingCode: widget.bookingCode,
          hotelName: widget.hotelName,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          roomName: room.name.isNotEmpty ? room.name.first : '',
          totalFare: finalAmount,
          currency: finalCurrency,
          email: email,
          phone: phone,
          guestTitle: title, // Now using actual selected title
          guestFirstName: firstName,
          guestLastName: lastName,
          hotelCode: hotelCode,
          hotelAddress: hotelAddress,
          hotelCity: hotelCity,
          hotelCountry: hotelCountry,
          hotelStars: hotelStars,
          hotelImage: hotelImage,
        ),
      ),
    );
  }

// Helper method to scroll to a specific section
  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
      body: BlocConsumer<HotelBookingBloc, HotelBookingState>(
        listener: (context, state) {
          if (state is HotelBookingLoaded) {
            final result = state.hotelBooking.hotelResult.isNotEmpty
                ? state.hotelBooking.hotelResult.first
                : null;
            _hotelResult = result;
            if (result != null && result.rooms.isNotEmpty) {
              _convertPrices(result.rooms.first, result.currency);
            }
          }
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
                  Icon(Icons.error_outline, size: context.w(64), color: Colors.red),
                  SizedBox(height: context.h(16)),
                  Text(
                    'Error: ${state.errorMessage}',
                    style: TextStyle(fontSize: context.fs(16)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.h(16)),
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
              return const Center(child: Text('No booking data available'));
            }

            final room = hotelResult.rooms.first;

            final prefs = di.sl<PreferencesManager>();
            final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: context.scrollPhysics,
                  child: Padding(
                    padding: EdgeInsets.all(context.w(12)),
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
                        SizedBox(height: context.h(16)),
                        TravellerDetailsSection(
                          key: _travellerKey,
                          userEmail: widget.userEmail,
                          adults: widget.adults,
                        ),
                        SizedBox(height: context.h(16)),
                        ContactInfoSection(
                          key: _contactKey,
                          userEmail: widget.userEmail,
                        ),
                        SizedBox(height: context.h(16)),
                        RoomInfoSection(
                          room: room,
                          currency: hotelResult.currency,
                        ),
                        SizedBox(height: context.h(16)),
                        PoliciesSection(
                          cancelPolicies: room.cancelPolicies,
                          rateConditions: hotelResult.rateConditions,
                        ),
                        SizedBox(height: context.h(16)),
                        RoomAmenitiesSection(amenities: room.amenities),
                        SizedBox(height: context.h(16)),
                        if (widget.hotelFacilities != null &&
                            widget.hotelFacilities!.isNotEmpty) ...[
                          HotelFacilitiesSection(
                            facilities: widget.hotelFacilities!,
                          ),
                          SizedBox(height: context.h(16)),
                        ],
                        if (widget.hotelDescription != null &&
                            widget.hotelDescription!.isNotEmpty) ...[
                          AboutHotelSection(
                            description: widget.hotelDescription!,
                            hotelName: widget.hotelName,
                          ),
                          SizedBox(height: context.h(16)),
                        ],
                        SizedBox(height: context.h(15)),

                        FareDetailsSection(
                          baseFare: _inrBasePrice ?? room.basePrice,
                          taxes: _inrTax ?? room.totalTax,
                          originalCurrency: hotelResult.currency,
                          preferredCurrency: preferredCurrency,
                          bookingCode: widget.bookingCode,
                          isConverting: _isConverting,
                          onContinueToPayment: () =>
                              _navigateToPayment(room, hotelResult.currency),
                        ),
                        SizedBox(height: context.h(20)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: context.w(16),
                  bottom: context.h(100),
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
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
