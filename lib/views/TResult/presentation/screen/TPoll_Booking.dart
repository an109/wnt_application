import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/TResevation/presentation/screen/payment_screen.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../TPoll_Search/domain/entities/TPollSearchEntity.dart';
import '../../../TResevation/domain/entities/TReservation-entity.dart';
import '../../../TResevation/presentation/bloc/TReservation_bloc.dart';
import '../../../TResevation/presentation/bloc/TReservation_event.dart';
import '../../../TResevation/presentation/bloc/TReservation_state.dart';
import '../../../auth/domain/entity/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class TPollBookingScreen extends StatefulWidget {
  final SearchResultEntity result;
  final SearchDataEntity searchData;
  final String startAddress;
  final String endAddress;
  final DateTime pickupDate;
  final String searchId;
  final String resultId;

  const TPollBookingScreen({
    super.key,
    required this.result,
    required this.searchData,
    required this.startAddress,
    required this.endAddress,
    required this.pickupDate,
    required this.searchId,
    required this.resultId,
  });

  @override
  State<TPollBookingScreen> createState() => _TPollBookingScreenState();
}

class _TPollBookingScreenState extends State<TPollBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flightNumberController = TextEditingController();
  final _airlineCodeController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  final _promoCodeController = TextEditingController();

  bool _meetAndGreetSelected = false;
  bool _smsNotificationsSelected = false;
  double _baseFare = 0;
  double _meetAndGreetPrice = 0;
  double _smsPrice = 0;
  bool _promoCodeApplied = false;
  String _appliedPromoCode = '';
  final Set<String> _selectedAmenities = {};

  // Track which fields have errors
  bool _firstNameError = false;
  bool _lastNameError = false;
  bool _emailError = false;
  bool _phoneError = false;
  bool _flightNumberError = false;

  int? _userId;
  static UserEntity? _cachedUser;

  // Color constants
  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _successGreen = Color(0xff10B981);
  static const _errorRed = Color(0xffDC2626);

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$dayName, $monthName $day, $year, $hour:$minute';
  }

  // Add this method to get user's preferred currency
  String _getPreferredCurrency() {
    final prefs = sl<PreferencesManager>();
    return prefs.getPreferredCurrency() ?? 'USD';
  }

// Add this method to get converted price
  double _getConvertedPrice(double amountInUSD) {
    final prefs = sl<PreferencesManager>();
    final preferredCurrency = _getPreferredCurrency();

    if (preferredCurrency == 'USD') {
      return amountInUSD;
    }

    final rates = prefs.getCachedExchangeRates();
    if (rates == null) return amountInUSD;

    final targetRate = rates[preferredCurrency];
    if (targetRate == null) return amountInUSD;

    // Convert USD to preferred currency
    return amountInUSD * targetRate;
  }

// Add this method to get formatted price string
  String _getFormattedPrice(double amountInUSD) {
    final prefs = sl<PreferencesManager>();
    final preferredCurrency = _getPreferredCurrency();

    if (preferredCurrency == 'USD') {
      final symbol = CurrencyConverter.getSymbol('USD');
      return '$symbol${amountInUSD.toStringAsFixed(2)}';
    }

    final converted = _getConvertedPrice(amountInUSD);
    return CurrencyConverter.format(converted, preferredCurrency);
  }

// Add this method to get currency symbol for display
  String _getDisplayCurrencySymbol() {
    final prefs = sl<PreferencesManager>();
    final preferredCurrency = _getPreferredCurrency();
    return CurrencyConverter.getSymbol(preferredCurrency);
  }

  @override
  void initState() {
    super.initState();
    _initializePrices();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });

    print('========================================');
    print('BOOKING SCREEN LOADED');
    print('Search ID: ${widget.searchId}');
    print('Result ID: ${widget.resultId}');
    print('========================================');
  }

  void _loadUserData() async {
    print(' LOADING USER DATA FROM STORAGE...');

    try {
      final prefs = sl<PreferencesManager>();
      final isLoggedIn = prefs.isLoggedIn();
      final userData = prefs.getUserData();

      if (isLoggedIn && userData != null) {
        print(' User found in local storage');
        final user = UserEntity.fromJson(userData);
        _applyUserData(user);
        return;
      }
    } catch (e) {
      print('Error reading from storage: $e');
    }

    // Fallback to AuthBloc state
    final authState = sl<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      print(' User found in AuthBloc state');
      _applyUserData(authState.user);
      return;
    }

    // Listen for auth changes
    print(' Waiting for login to complete...');
    final authBloc = sl<AuthBloc>();
    authBloc.stream.listen((state) {
      if (mounted && state is AuthAuthenticated) {
        print(' User data received via stream!');
        _applyUserData(state.user);
      }
    });
  }

  void _applyUserData(UserEntity user) {
    if (!mounted) return;

    setState(() {
      _firstNameController.text = user.firstname ?? '';
      _lastNameController.text = user.lastname ?? '';
      _emailController.text = user.email;
      _userId = int.tryParse(user.id) ?? 0;
    });

    print('------- PREFILLED SUCCESSFULLY ------');
    print('Name: ${user.firstname} ${user.lastname}');
    print('Email: ${user.email}');
    print('User ID: $_userId');
  }

  void _proceedToPayment() {
    print('=== CONTINUE TO PAYMENT TAPPED ===');

    final displaySymbol = _getDisplayCurrencySymbol();
    final convertedTotal = _totalPrice;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          searchId: widget.searchId,
          resultId: widget.resultId,
          vehicleType: widget.result.vehicleType,
          vehicleName: widget.result.vehicleName,
          providerName: widget.result.providerName,
          pickupLocation: widget.startAddress.isNotEmpty
              ? widget.startAddress
              : widget.searchData.startLocation.city,
          dropoffLocation: widget.endAddress.isNotEmpty
              ? widget.endAddress
              : widget.searchData.endLocation.city,
          pickupDate: widget.pickupDate,
          passengers: 1,
          baseFare: _baseFare,
          totalAmount: convertedTotal,  // Pass converted amount
          passengerName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          passengerEmail: _emailController.text.trim(),
          passengerPhone: '91${_phoneController.text.trim()}',
          userId: _userId,
        ),
      ),
    );
  }

  void _initializePrices() {
    final originalAmount = double.tryParse(widget.result.totalPriceAmount) ?? 0;

    // Store converted prices
    _baseFare = _getConvertedPrice(originalAmount);

    for (var amenity in widget.result.amenities) {
      final amenityPriceUSD = double.tryParse(amenity.price?.value ?? '0') ?? 0;

      if (amenity.key == 'meet_and_greet') {
        _meetAndGreetPrice = _getConvertedPrice(amenityPriceUSD);
      } else if (amenity.key == 'sms_notifications') {
        _smsPrice = _getConvertedPrice(amenityPriceUSD);
      }
    }

    print('💰 Booking Screen - Prices converted:');
    print('   Original: $originalAmount USD');
    print('   Converted: $_baseFare ${_getPreferredCurrency()}');
  }

  // double get _totalPrice {
  //   double total = _baseFare;
  //
  //   for (var amenity in widget.result.amenities) {
  //     if (_selectedAmenities.contains(amenity.key)) {
  //       total += double.tryParse(amenity.price?.value ?? '0') ?? 0;
  //     }
  //   }
  //
  //   return total;
  // }

  double get _totalPrice {
    double total = _baseFare;

    for (var amenity in widget.result.amenities) {
      if (_selectedAmenities.contains(amenity.key)) {
        final amenityPriceUSD = double.tryParse(amenity.price?.value ?? '0') ?? 0;
        total += _getConvertedPrice(amenityPriceUSD);
      }
    }

    return total;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flightNumberController.dispose();
    _airlineCodeController.dispose();
    _specialRequestsController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: WanderNovaLogo(
          scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset(
              "assets/images/wander_nova_logo.png",
              height: context.hp(4.5),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTripDetailsHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeadPassengerSection(),
                  const SizedBox(height: 16),
                  _buildFlightInformationSection(),
                  const SizedBox(height: 16),
                  _buildAmenitiesSection(),
                  const SizedBox(height: 16),
                  _buildSpecialRequestsSection(),
                  const SizedBox(height: 16),
                  _buildPromoCodeSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildPriceSummaryBar(),
    );
  }

  Widget _buildTripDetailsHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(context.wp(4)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FROM',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.startAddress.isNotEmpty
                      ? widget.startAddress
                      : widget.searchData.startLocation.city.isNotEmpty
                      ? widget.searchData.startLocation.city
                      : widget.searchData.startLocation.iataCode,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w700,
                    color: _darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
            child: Icon(
              Icons.arrow_forward,
              color: _primaryOrange,
              size: context.iconMedium,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TO',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.endAddress.isNotEmpty
                      ? widget.endAddress
                      : widget.searchData.endLocation.city.isNotEmpty
                      ? widget.searchData.endLocation.city
                      : widget.searchData.endLocation.iataCode,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w700,
                    color: _darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a promo code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _promoCodeApplied = true;
      _appliedPromoCode = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promo code "$code" applied successfully!'),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLeadPassengerSection() {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
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
          Row(
            children: [
              Icon(Icons.person_outline, size: context.iconMedium, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Lead Passenger',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name*',
                  hintText: 'First Name',
                  hasError: _firstNameError,
                ),
              ),
              SizedBox(width: context.wp(4)),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name*',
                  hintText: 'Last Name',
                  hasError: _lastNameError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Email Address*',
                  hintText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  hasError: _emailError,
                ),
              ),
              SizedBox(width: context.wp(4)),
              Expanded(
                child: _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number*',
                  hintText: '98765 43210',
                  keyboardType: TextInputType.phone,
                  hasError: _phoneError,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightInformationSection() {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
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
          Row(
            children: [
              Icon(Icons.flight_takeoff, size: context.iconMedium, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Flight Information',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Required for this ride',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share your flight details so the driver can track delays and arrival gates.',
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _flightNumberController,
                  label: 'Flight Number*',
                  hintText: 'AI 101',
                  hasError: _flightNumberError,
                ),
              ),
              SizedBox(width: context.wp(4)),
              Expanded(
                child: _buildTextField(
                  controller: _airlineCodeController,
                  label: 'Airline Code',
                  hintText: 'AI',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final amenities = widget.result.amenities;
    final currencySymbol = widget.searchData.currencyInfo.prefixSymbol;

    // Separate amenities into two lists
    final upgrades = amenities.where((a) => a.chargeable && !a.included).toList();
    final included = amenities.where((a) => a.included && !a.chargeable).toList();

    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
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
          Row(
            children: [
              Icon(Icons.add_shopping_cart_outlined, size: context.iconMedium, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Amenities & Add-ons',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── OPTIONAL UPGRADES SECTION ──
          if (upgrades.isNotEmpty) ...[
            Text(
              'OPTIONAL UPGRADES',
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildAmenityGrid(
              amenities: upgrades,
              // currencySymbol: currencySymbol,
              isIncludedSection: false,
            ),
            const SizedBox(height: 20),
          ],

          // ── INCLUDED SECTION ──
          if (included.isNotEmpty) ...[
            Text(
              'INCLUDED WITH YOUR RIDE',
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w700,
                color: _successGreen,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildAmenityGrid(
              amenities: included,
              // currencySymbol: currencySymbol,
              isIncludedSection: true,
            ),
            const SizedBox(height: 12),
          ],

          Text(
            'One of each amenity can be added online. For more than one seat or special quantity, mention it in Special Requests.',
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  bool _getAmenitySelection(String key) {
    return _selectedAmenities.contains(key);
  }


  void _toggleAmenity(String key) {
    setState(() {
      if (_selectedAmenities.contains(key)) {
        _selectedAmenities.remove(key);
      } else {
        _selectedAmenities.add(key);
      }
    });
  }

// Helper to get amenity price in preferred currency
  double _getAmenityPrice(AmenityEntity amenity) {
    final priceUSD = double.tryParse(amenity.price?.value ?? '0') ?? 0;
    return _getConvertedPrice(priceUSD);
  }

// Helper to get formatted amenity price
  String _getFormattedAmenityPrice(AmenityEntity amenity) {
    final priceUSD = double.tryParse(amenity.price?.value ?? '0') ?? 0;
    return _getFormattedPrice(priceUSD);
  }

  Widget _buildAmenityGrid({
    required List<AmenityEntity> amenities,
    required bool isIncludedSection,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: amenities.map((amenity) {
            return SizedBox(
              width: cardWidth,
              child: _buildAmenityCard(
                title: amenity.name,
                price: _getFormattedAmenityPrice(amenity),  // Use converted price
                description: amenity.description,
                isSelected: _getAmenitySelection(amenity.key),
                isIncluded: amenity.included,
                onTap: () => _toggleAmenity(amenity.key),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAmenityCard({
    required String title,
    required String price,
    required String description,
    required bool isSelected,
    required bool isIncluded,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isIncluded ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(context.wp(3)),
          decoration: BoxDecoration(
            color: isIncluded
                ? _successGreen.withOpacity(0.08)
                : (isSelected ? _primaryBlue.withOpacity(0.05) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isIncluded
                  ? _successGreen
                  : (isSelected ? _primaryBlue : Colors.grey.shade200),
              width: isIncluded ? 2 : (isSelected ? 2 : 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: isIncluded
                            ? _successGreen
                            : (isSelected ? _primaryBlue : _darkNavy),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isIncluded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _successGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'INCLUDED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Text(
                      price,  // Now shows converted price (e.g., ₹3,500)
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? _primaryBlue : _primaryOrange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPromoCodeSection() {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
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
          Row(
            children: [
              Icon(Icons.local_offer_outlined, size: context.iconMedium, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Promo Code',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _promoCodeController,
                  decoration: InputDecoration(
                    hintText: 'ENTER PROMO CODE',
                    hintStyle: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _primaryBlue, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(context.wp(3)),
                  ),
                  enabled: !_promoCodeApplied,
                ),
              ),
              SizedBox(width: context.wp(1.5)),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: context.formFieldHeight,
                  child: ElevatedButton(
                    onPressed: _promoCodeApplied ? null : _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _promoCodeApplied ? Colors.grey.shade300 : _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _promoCodeApplied ? 'Applied' : 'Apply',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSpecialRequestsSection() {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
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
          Row(
            children: [
              Icon(Icons.info_outline, size: context.iconMedium, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Special Requests',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specialRequestsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Child seat, wheelchair access, special pickup note, or anything else the provider should know.',
              hintStyle: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryBlue, width: 2),
              ),
              contentPadding: EdgeInsets.all(context.wp(3)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPriceSummaryBar() {
    final displaySymbol = _getDisplayCurrencySymbol();
    final preferredCurrency = _getPreferredCurrency();

    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Base fare',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$displaySymbol${_baseFare.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            // Show original price for reference (optional)
            // if (preferredCurrency != 'USD')
            //   Padding(
            //     padding: const EdgeInsets.only(top: 4),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Text(
            //           'Original (USD)',
            //           style: TextStyle(
            //             fontSize: context.labelSmall,
            //             color: Colors.grey.shade400,
            //           ),
            //         ),
            //         Text(
            //           '\$${widget.result.totalPriceAmount}',
            //           style: TextStyle(
            //             fontSize: context.labelSmall,
            //             color: Colors.grey.shade400,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),

            // Show selected amenities in price breakdown
            ..._selectedAmenities.map((amenityKey) {
              final amenity = widget.result.amenities.firstWhere(
                    (a) => a.key == amenityKey,
                orElse: () => widget.result.amenities.first,
              );
              final amenityPrice = _getAmenityPrice(amenity);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      amenity.name,
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '+ $displaySymbol${amenityPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: _darkNavy,
                  ),
                ),
                Text(
                  '$displaySymbol${_totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w800,
                    color: _darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(context.wp(3)),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Final payable on payment page',
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$displaySymbol${_totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      fontWeight: FontWeight.w800,
                      color: _primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: ElevatedButton(
                onPressed: _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.credit_card, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pay $displaySymbol${_totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By proceeding, you agree to our terms and conditions. We will keep your booking synced in My Bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.bodySmall,
                fontWeight: FontWeight.w600,
                color: hasError ? _errorRed : _darkNavy,
              ),
            ),
            if (label.contains('*'))
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '*',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    fontWeight: FontWeight.w700,
                    color: hasError ? _errorRed : _primaryOrange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => _clearFieldError(label),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? _errorRed : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? _errorRed : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? _errorRed : _primaryBlue,
                width: 2,
              ),
            ),
            errorText: hasError ? 'This field is required' : null,
            contentPadding: EdgeInsets.all(context.wp(3)),
          ),
        ),
      ],
    );
  }

  void _clearFieldError(String label) {
    setState(() {
      if (label.contains('First Name')) _firstNameError = false;
      if (label.contains('Last Name')) _lastNameError = false;
      if (label.contains('Email')) _emailError = false;
      if (label.contains('Phone')) _phoneError = false;
      if (label.contains('Flight Number')) _flightNumberError = false;
    });
  }

  void _validateAndProceed() {
    bool hasError = false;

    // Validate and set errors
    if (_firstNameController.text.trim().isEmpty) {
      _firstNameError = true;
      hasError = true;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _lastNameError = true;
      hasError = true;
    }
    if (_emailController.text.trim().isEmpty) {
      _emailError = true;
      hasError = true;
    }
    if (_phoneController.text.trim().isEmpty) {
      _phoneError = true;
      hasError = true;
    }
    if (_flightNumberController.text.trim().isEmpty) {
      _flightNumberError = true;
      hasError = true;
    }

    if (hasError) {
      setState(() {}); // Refresh UI to show red borders
      return;
    }

    // All valid - proceed to payment
    _proceedToPayment();
  }

}