import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/views/Exchange_rate/presentation/bloc/exchange_rate_bloc.dart';
import 'package:wander_nova/views/Exchange_rate/presentation/bloc/exchange_rate_event.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import 'package:wander_nova/views/Holiday_destination/presentation/bloc/holiday_destination_bloc.dart';
import 'package:wander_nova/views/LogOut/presentation/bloc/logout_bloc.dart';
import 'package:wander_nova/views/MainApi/presentation/bloc/general_setting_bloc.dart';
import 'package:wander_nova/views/MyBookings/Hotels/bloc/BookingListBloc.dart';
import 'package:wander_nova/views/MyBookings/Transport/bloc/MyBooking_bloc.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';
import 'package:wander_nova/views/ReferCode/presentation/bloc/referral_bloc.dart';
import 'package:wander_nova/views/ReferCredit/presentation/bloc/transaction_bloc.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchBloc.dart';
import 'package:wander_nova/views/TResevation/presentation/bloc/TReservation_bloc.dart';
import 'package:wander_nova/views/TResult/presentation/bloc/TResult_bloc.dart';
import 'package:wander_nova/views/T_Search/presentation/bloc/T_SearchBloc.dart';
import 'package:wander_nova/views/T_location/presentation/bloc/T_locationBloc.dart';
import 'package:wander_nova/views/UpcomingTrips/presentation/bloc/upcomingTrip_bloc.dart';
import 'package:wander_nova/views/Verify_otp/presentation/bloc/verify_otp_bloc.dart';
import 'package:wander_nova/views/VisaDestination/presentation/bloc/visaDestin_bloc.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/presentation/bloc/visa_destination_bloc.dart';
import 'package:wander_nova/views/WalletStatus/presentation/bloc/loyalty_bloc.dart';
import 'package:wander_nova/views/flight_popularDestination/presentation/bloc/destination_bloc.dart';
import 'package:wander_nova/views/footer/presentation/bloc/footer_setting_bloc.dart';
import 'package:wander_nova/views/login/presentation/bloc/login_bloc.dart';
import 'package:wander_nova/views/signup/presentation/bloc/signup_bloc.dart';
import 'package:wander_nova/views/splash/splash_screen.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/bloc/hotel_booking_bloc.dart';
import 'package:wander_nova/views/Hotel_Details/presentation/bloc/hotel_details_bloc.dart';
import 'package:wander_nova/views/Hotel_api/presentation/bloc/hotel_bloc.dart';
import 'package:wander_nova/views/airport/presentation/bloc/airport_bloc.dart';
import 'package:wander_nova/views/auth/presentation/bloc/auth_bloc.dart';
import 'package:wander_nova/views/countries/presentation/bloc/country_bloc.dart';
import 'package:wander_nova/views/fare_quote/presentation/bloc/fare_quote_bloc.dart';
import 'package:wander_nova/views/fare_rule/presentation/bloc/fare_rule_bloc.dart';
import 'package:wander_nova/views/flight_destination/presentation/bloc/destination_bloc.dart';
import 'package:wander_nova/views/flight_search/presentation/bloc/flight_search_bloc.dart';
import 'package:wander_nova/views/flight_ssr/presentation/bloc/ssr_bloc.dart';
import 'package:wander_nova/views/travel_stories/presentation/bloc/travel_stories_bloc.dart';
import 'package:wander_nova/views/trending_route/presentation/bloc/trending_routes_bloc.dart';
import 'package:wander_nova/views/wallet/presentation/bloc/wallet_bloc.dart';

import 'core/services/exchange_rate_service.dart';
import 'views/Send_otp/presentation/bloc/send_otp_bloc.dart';
import 'core/utils/storage/shared_preference.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initializeDependencies();

  final prefs = sl<PreferencesManager>();
  await prefs.remove('exchange_rates_cache');
  await prefs.remove('exchange_rates_cache_time');
  await ExchangeRateService.initializeUserCurrency();
  if (sl.isRegistered<ExchangeRateBloc>()) {
    sl<ExchangeRateBloc>().add(const FetchExchangeRates());
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AirportBloc>()),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<FlightSearchBloc>()),
        BlocProvider(create: (_) => di.sl<FareRuleBloc>()),
        BlocProvider(create: (_) => di.sl<FareQuoteBloc>()),
        BlocProvider(create: (_) => di.sl<SsrBloc>()),
        BlocProvider(create: (_) => di.sl<CountryBloc>()),
        BlocProvider(create: (_) => di.sl<DestinationBloc>()),
        BlocProvider(create: (_) => di.sl<HotelBloc>()),
        BlocProvider(create: (_) => di.sl<HotelDetailsBloc>()),
        BlocProvider(create: (_) => di.sl<HotelBookingBloc>()),
        BlocProvider(create: (_) => di.sl<ExclusiveDealsBloc>()),
        BlocProvider(create: (_) => di.sl<T_locationBloc>()),
        BlocProvider(create: (_) => di.sl<TransportSearchBloc>()),
        BlocProvider(create: (_) => di.sl<TpollSearchBloc>()),
        BlocProvider(create: (_) => di.sl<TransportResultBloc>()),
        BlocProvider(create: (_) => di.sl<TransportReservationBloc>()),
        BlocProvider(create: (_) => di.sl<PopularDestinationBloc>()),
        BlocProvider(create: (_) => di.sl<TrendingRoutesBloc>()),
        BlocProvider(create: (_) => di.sl<TravelStoriesBloc>()),
        BlocProvider(create: (_) => di.sl<VisaPopularDestinationBloc>()),
        BlocProvider(create: (_) => di.sl<FooterSettingsBloc>()),
        BlocProvider(create: (_) => di.sl<VisaDestinationBloc>()),
        BlocProvider(create: (_) => di.sl<GeneralSettingsBloc>()),
        BlocProvider(create: (_) => di.sl<HolidayBloc>()),
        BlocProvider(create: (_) => di.sl<ExchangeRateBloc>()),
        BlocProvider(create: (_) => di.sl<SendOtpBloc>()),
        BlocProvider(create: (_) => di.sl<VerifyOtpBloc>()),
        BlocProvider(create: (_) => di.sl<SignupBloc>()),
        BlocProvider(create: (_) => di.sl<LoginBloc>()),
        BlocProvider(create: (_) => di.sl<WalletBloc>()),
        BlocProvider(create: (_) => di.sl<LogoutBloc>()),
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider(create: (_) => di.sl<MyBookingBloc>()),
        BlocProvider(create: (_) => di.sl<UpcomingTripBloc>()),
        BlocProvider(create: (_) => di.sl<ReferralBloc>()),
        BlocProvider(create: (_) => di.sl<LoyaltyBloc>()),
        BlocProvider(create: (_) => di.sl<TransactionBloc>()),
        BlocProvider(create: (_) => di.sl<HotelBookingListBloc>()),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WanderNova',
        theme: ThemeData(
          // primarySwatch: Colors.blue,
          //   textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0054A0),
            primary: const Color(0xFF0054A0),
            secondary: const Color(0xFFFF7200),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
