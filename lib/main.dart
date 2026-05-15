import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchBloc.dart';
import 'package:wander_nova/views/TResevation/presentation/bloc/TReservation_bloc.dart';
import 'package:wander_nova/views/TResult/presentation/bloc/TResult_bloc.dart';
import 'package:wander_nova/views/T_Search/presentation/bloc/T_SearchBloc.dart';
import 'package:wander_nova/views/T_location/presentation/bloc/T_locationBloc.dart';
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

import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initializeDependencies();
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
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WanderNova',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
