import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
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
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
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

  bool _promoCodeApplied = false;
  String _appliedPromoCode = '';
  double _promoDiscountAmount = 0.0;
  final TextEditingController _promoCodeController = TextEditingController();

  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _successGreen = Color(0xff10B981);
  static const _errorRed = Color(0xffDC2626);

  String _getDisplayCurrencySymbol() {
    final prefs = di.sl<PreferencesManager>();
    final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';
    return CurrencyConverter.getSymbol(preferredCurrency);
  }

  void _removePromoCode() {
    setState(() {
      _promoCodeApplied = false;
      _appliedPromoCode = '';
      _promoDiscountAmount = 0.0;
      _promoCodeController.clear();
    });
  }

  void _showCelebrationDialog(double discountAmount, String promoCode) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16), // Using fixed padding for simplicity
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie Animation
                Container(
                  height: 200, // Fixed height for simplicity
                  width: double.infinity,
                  child: Lottie.asset(
                    'assets/animation/celebrate.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                // Success Message
                Text(
                  '🎉 Promo Applied!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _darkNavy,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'You saved ${_getDisplayCurrencySymbol()}${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _successGreen,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Code: $_appliedPromoCode',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Great!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
      final promoBloc = context.read<GeneralSettingsBloc>();
      if (promoBloc.state is! PromoCodesLoaded) {
        promoBloc.add(const LoadPromoCodes());
      }
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
    if (_promoDiscountAmount > 0) {
      finalAmount = finalAmount - _promoDiscountAmount;
      if (finalAmount < 0) finalAmount = 0; // Prevent negative total
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

  Widget _buildPromoCodeSection(RoomEntity room, String currency) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        final filtered = state is PromoCodesLoaded
            ? state.promoCodes
                .where((p) =>
                    p.category == 'hotel_booking' || p.category == 'payment')
                .toList()
            : <PromoCodeEntity>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded,
                        size: 20, color: _primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'Coupons & Offers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _darkNavy,
                      ),
                    ),
                    if (filtered.isNotEmpty && !_promoCodeApplied) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filtered.length} offer${filtered.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _promoCodeApplied
                    ? _buildHotelPromoAppliedBanner()
                    : _buildHotelPromoInputRow(room, currency),
              ),
              if (!_promoCodeApplied && filtered.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    'AVAILABLE OFFERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...filtered.asMap().entries.map(
                  (e) => _buildHotelCouponCard(
                      e.value, room, currency,
                      showTopDivider: e.key > 0),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotelPromoAppliedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: _successGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_appliedPromoCode applied',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _successGreen,
                  ),
                ),
                Text(
                  'You saved ${_getDisplayCurrencySymbol()}${_promoDiscountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: _successGreen),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _removePromoCode,
            child: const Text(
              'Remove',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelPromoInputRow(RoomEntity room, String currency) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _promoCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'ENTER COUPON CODE',
              hintStyle:
                  TextStyle(fontSize: 12, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: _primaryBlue, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _applyPromoCode(room, currency),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('APPLY',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildHotelCouponCard(
      PromoCodeEntity promo, RoomEntity room, String currency,
      {bool showTopDivider = false}) {
    final discountLabel = promo.discountType == 'percent'
        ? 'Get ${double.tryParse(promo.discountValue)?.toStringAsFixed(0) ?? promo.discountValue}% off on this booking'
        : 'Get ${_getDisplayCurrencySymbol()}${promo.discountValue} off on this booking';

    return Column(
      children: [
        if (showTopDivider)
          Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16),
        InkWell(
          onTap: () {
            _promoCodeController.text = promo.code;
            _applyPromoCode(room, currency);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined,
                      color: _primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _primaryBlue.withOpacity(0.2)),
                        ),
                        child: Text(
                          promo.code,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _primaryBlue,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _darkNavy,
                        ),
                      ),
                      if (promo.description.isNotEmpty)
                        Text(
                          promo.description,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _promoCodeController.text = promo.code;
                    _applyPromoCode(room, currency);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryBlue,
                    side: const BorderSide(color: _primaryBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('APPLY',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _applyPromoCode(RoomEntity room, String currency) async {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a promo code'),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // 1. Get Promo Codes from BLoC
    final bloc = context.read<GeneralSettingsBloc>();
    List<PromoCodeEntity> promoCodes = [];

    // Handle both possible states depending on your BLoC implementation
    if (bloc.state is PromoCodesLoaded) {
      promoCodes = (bloc.state as PromoCodesLoaded).promoCodes;
    }

    // 2. Find matching promo code
    final matchedPromo = promoCodes.firstWhere(
          (p) => p.code.toUpperCase() == code,
      orElse: () => const PromoCodeEntity(
          code: '', category: '', discountType: '', discountValue: '0', description: ''),
    );

    if (matchedPromo.code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid promo code. Please try again.'),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // 3. Calculate Discount
    double discount = 0;
    final discountValue = double.tryParse(matchedPromo.discountValue) ?? 0;

    // Calculate base total in ORIGINAL currency first
    double baseTotalOriginal = room.basePrice + room.totalTax;

    if (matchedPromo.discountType == 'percent') {
      // Percent discounts are usually applied to the base amount before conversion
      double discountOriginal = (baseTotalOriginal * discountValue) / 100;

      // Convert the discount amount to preferred currency
      final prefs = di.sl<PreferencesManager>();
      final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';

      if (currency.toUpperCase() != preferredCurrency.toUpperCase()) {
        try {
          discount = await CurrencyConverter.convert(
            amount: discountOriginal,
            fromCurrency: currency,
            toCurrency: preferredCurrency,
          );
        } catch (e) {
          discount = discountOriginal; // Fallback
        }
      } else {
        discount = discountOriginal;
      }

    } else {
      // Fixed amount discount
      // Assume the fixed value in DB is in the same currency as the booking (originalCurrency)
      // Or if your DB stores fixed discounts in USD, adjust accordingly.
      // Here assuming it's in the booking's original currency:

      final prefs = di.sl<PreferencesManager>();
      final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';

      if (currency.toUpperCase() != preferredCurrency.toUpperCase()) {
        try {
          discount = await CurrencyConverter.convert(
            amount: discountValue,
            fromCurrency: currency,
            toCurrency: preferredCurrency,
          );
        } catch (e) {
          discount = discountValue;
        }
      } else {
        discount = discountValue;
      }
    }

    // 4. Apply State
    setState(() {
      _promoCodeApplied = true;
      _appliedPromoCode = matchedPromo.code;
      _promoDiscountAmount = discount;
    });

    // 5. Show Celebration Dialog
    _showCelebrationDialog(discount, matchedPromo.code);
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
                        _buildPromoCodeSection(room, hotelResult.currency),
                        SizedBox(height: context.h(12)),

                        FareDetailsSection(
                          baseFare: _inrBasePrice ?? room.basePrice,
                          taxes: _inrTax ?? room.totalTax,
                          originalCurrency: hotelResult.currency,
                          preferredCurrency: preferredCurrency,
                          bookingCode: widget.bookingCode,
                          isConverting: _isConverting,
                          promoDiscount: _promoDiscountAmount,
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
