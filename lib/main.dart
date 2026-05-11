import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/splash/splash_screen.dart';
import 'package:wander_nova/views/airport/presentation/bloc/airport_bloc.dart';
import 'package:wander_nova/views/auth/presentation/bloc/auth_bloc.dart';
import 'package:wander_nova/views/fare_quote/presentation/bloc/fare_quote_bloc.dart';
import 'package:wander_nova/views/fare_rule/presentation/bloc/fare_rule_bloc.dart';
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
