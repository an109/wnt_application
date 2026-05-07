import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/views/airport/data/data_source/airport_api_service.dart';
import 'package:wander_nova/views/airport/data/repository/airport_repositories_impl.dart';
import 'package:wander_nova/views/airport/domain/repository/airport_repositories.dart';
import 'package:wander_nova/views/airport/domain/usecases/get_airport_usecase.dart';
import 'package:wander_nova/views/airport/presentation/bloc/airport_bloc.dart';
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


  // Data Layer
  sl.registerLazySingleton<AirportApiService>(
        () => AirportApiServiceImpl(sl<DioClient>().instance),
  );

  // Repository
  sl.registerLazySingleton<AirportRepository>(
        () => AirportRepositoryImpl(sl()),
  );

  // Domain Layer - UseCases
  sl.registerLazySingleton<GetAirportsUsecase>(
        () => GetAirportsUsecase(sl()),
  );

  // Presentation Layer - Bloc
  sl.registerFactory<AirportBloc>(
        () => AirportBloc(sl()),
  );

}