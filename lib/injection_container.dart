import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/views/airport/data/data_source/airport_api_service.dart';
import 'package:wander_nova/views/airport/data/repository/airport_repositories_impl.dart';
import 'package:wander_nova/views/airport/domain/repository/airport_repositories.dart';
import 'package:wander_nova/views/airport/domain/usecases/get_airport_usecase.dart';
import 'package:wander_nova/views/airport/presentation/bloc/airport_bloc.dart';
import 'package:wander_nova/views/auth/data/data_source/auth_api_source.dart';
import 'package:wander_nova/views/auth/data/repository/auth_repository_impl.dart';
import 'package:wander_nova/views/auth/domain/repository/auth_repository.dart';
import 'package:wander_nova/views/auth/domain/usecase/google_auth_usecase.dart';
import 'package:wander_nova/views/auth/presentation/bloc/auth_bloc.dart';
import 'package:wander_nova/views/auth/presentation/sdk/google_sign_in_service.dart';
import 'package:wander_nova/views/flight_search/data/data_source/flight_api_service.dart';
import 'package:wander_nova/views/flight_search/data/repository/flight_repository_impl.dart';
import 'package:wander_nova/views/flight_search/domain/repository/flight_repository.dart';
import 'package:wander_nova/views/flight_search/domain/usecase/flight_search_usecase.dart';
import 'package:wander_nova/views/flight_search/presentation/bloc/flight_search_bloc.dart';
import 'core/network/dio_client.dart';
import 'core/utils/storage/shared_preference.dart';
import 'core/constants/urls.dart';


final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // 1. Register SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<PreferencesManager>(
    await PreferencesManager.create(sharedPreferences),
  );

  // 2. Register DioClient
  sl.registerSingleton<DioClient>(DioClient(Urls.baseUrl));

  sl.registerLazySingleton<Dio>(
        () => sl<DioClient>().instance,
  );



  //   Register GoogleSignInService
  sl.registerLazySingleton<GoogleSignInService>(
        () => GoogleSignInService(
      scopes: ['email', 'profile'],
      serverClientId: '99880015098-o585d840371c4j01vc2alcrqa74mevdh.apps.googleusercontent.com',
    ),
  );


  // Data Layer
  sl.registerLazySingleton<AirportApiService>(
        () => AirportApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerLazySingleton<AuthApiService>(
        () => AuthApiServiceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<FlightApiService>(
        () => FlightApiService(sl<DioClient>()),
  );



  // Repository
  sl.registerLazySingleton<AirportRepository>(
        () => AirportRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<AuthApiService>()),
  );

  sl.registerLazySingleton<FlightRepository>(
        () => FlightRepositoryImpl(sl<FlightApiService>()),
  );




  // Domain Layer - UseCases
  sl.registerLazySingleton<GetAirportsUsecase>(
        () => GetAirportsUsecase(sl()),
  );
  sl.registerLazySingleton<GoogleLoginUseCase>(
        () => GoogleLoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SearchFlightsUseCase>(
        () => SearchFlightsUseCase(sl<FlightRepository>()),
  );



  // Presentation Layer - Bloc
  sl.registerFactory<AirportBloc>(() => AirportBloc(sl()),
  );
  sl.registerFactory<AuthBloc>(
        () => AuthBloc(googleLoginUseCase: sl<GoogleLoginUseCase>()),
  );

  sl.registerFactory<FlightSearchBloc>(
        () => FlightSearchBloc(sl<SearchFlightsUseCase>()),
  );

}