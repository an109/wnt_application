import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/views/ExclusiveDeals/data/data_source/exclusive_deals_api_service.dart';
import 'package:wander_nova/views/ExclusiveDeals/data/repository/exclusive_deals_repository_impl.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/repository/exclusive_deals_repository.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/usecase/get_exclusive_deals_usecase.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import 'package:wander_nova/views/Hotel_Booking/data/data_source/hotel_booking_api_service.dart';
import 'package:wander_nova/views/Hotel_Booking/data/repository/hotel_booking_repository_impl.dart';
import 'package:wander_nova/views/Hotel_Booking/domain/repository/hotel_booking_repository.dart';
import 'package:wander_nova/views/Hotel_Booking/domain/usecase/get_hotel_booking_details_usecase.dart';
import 'package:wander_nova/views/Hotel_Booking/presentation/bloc/hotel_booking_bloc.dart';
import 'package:wander_nova/views/Hotel_Details/data/data_source/hotel_details_api_service.dart';
import 'package:wander_nova/views/Hotel_Details/data/repository/hotel_details_repository_impl.dart';
import 'package:wander_nova/views/Hotel_Details/domain/repository/hotel_details_entity.dart';
import 'package:wander_nova/views/Hotel_Details/domain/usecase/get_hotel_details_usecase.dart';
import 'package:wander_nova/views/Hotel_Details/presentation/bloc/hotel_details_bloc.dart';
import 'package:wander_nova/views/Hotel_api/data/data_source/hotel_api_service.dart';
import 'package:wander_nova/views/Hotel_api/data/repository/hotel_repository_impl.dart';
import 'package:wander_nova/views/Hotel_api/domain/repository/hotel_repository.dart';
import 'package:wander_nova/views/Hotel_api/domain/usecase/get_hotels_by_city_usecase.dart';
import 'package:wander_nova/views/Hotel_api/presentation/bloc/hotel_bloc.dart';
import 'package:wander_nova/views/TPoll_Search/data/data_source/TPoll_Search_api-service.dart';
import 'package:wander_nova/views/TPoll_Search/data/repository/TPoll_search_repository_impl.dart';
import 'package:wander_nova/views/TPoll_Search/domain/repository/TPoll_Search_repository.dart';
import 'package:wander_nova/views/TPoll_Search/domain/usecase/TPoll_search_usecase.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchBloc.dart';
import 'package:wander_nova/views/T_Search/data/data_source/T_Search_api_service.dart';
import 'package:wander_nova/views/T_Search/data/repository/T_SearchRepository_impl.dart';
import 'package:wander_nova/views/T_Search/domain/repository/T_SearchRepository.dart';
import 'package:wander_nova/views/T_Search/domain/usecase/T_SearchUsecase.dart';
import 'package:wander_nova/views/T_Search/presentation/bloc/T_SearchBloc.dart';
import 'package:wander_nova/views/T_location/data/data_source/T_loaction_api_service.dart';
import 'package:wander_nova/views/T_location/data/repository/T_location_repository_impl.dart';
import 'package:wander_nova/views/T_location/domain/repository/T_location_repository.dart';
import 'package:wander_nova/views/T_location/domain/usecase/get_location_usecase.dart';
import 'package:wander_nova/views/T_location/presentation/bloc/T_locationBloc.dart';
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
import 'package:wander_nova/views/countries/data/data_source/country_api_service.dart';
import 'package:wander_nova/views/countries/data/repository/country_repository_impl.dart';
import 'package:wander_nova/views/countries/domain/repository/country_repository.dart';
import 'package:wander_nova/views/countries/domain/usecase/get_countries_usecase.dart';
import 'package:wander_nova/views/countries/presentation/bloc/country_bloc.dart';
import 'package:wander_nova/views/fare_quote/data/data_source/fare_quote_api_service.dart';
import 'package:wander_nova/views/fare_quote/data/repository/fare_quote_repository_impl.dart';
import 'package:wander_nova/views/fare_quote/domain/repository/fare_quote_repository.dart';
import 'package:wander_nova/views/fare_quote/domain/usecase/fare_quote_usecase.dart';
import 'package:wander_nova/views/fare_quote/presentation/bloc/fare_quote_bloc.dart';
import 'package:wander_nova/views/fare_rule/data/data_sorce/fare_rule_api_service.dart';
import 'package:wander_nova/views/fare_rule/data/repository/fare_rule_repository_impl.dart';
import 'package:wander_nova/views/fare_rule/domain/repository/fare_rule_repository.dart';
import 'package:wander_nova/views/fare_rule/domain/usecase/fare_rule_usecase.dart';
import 'package:wander_nova/views/fare_rule/presentation/bloc/fare_rule_bloc.dart';
import 'package:wander_nova/views/flight_destination/data/data_source/destination_api_service.dart';
import 'package:wander_nova/views/flight_destination/data/repository/destination_repository_impl.dart';
import 'package:wander_nova/views/flight_destination/domain/repository/destination_repository.dart';
import 'package:wander_nova/views/flight_destination/domain/usecase/search_destination_usecase.dart';
import 'package:wander_nova/views/flight_destination/presentation/bloc/destination_bloc.dart';
import 'package:wander_nova/views/flight_search/data/data_source/flight_api_service.dart';
import 'package:wander_nova/views/flight_search/data/repository/flight_repository_impl.dart';
import 'package:wander_nova/views/flight_search/domain/repository/flight_repository.dart';
import 'package:wander_nova/views/flight_search/domain/usecase/flight_search_usecase.dart';
import 'package:wander_nova/views/flight_search/presentation/bloc/flight_search_bloc.dart';
import 'package:wander_nova/views/flight_ssr/data/data_source/ssr_api_service.dart';
import 'package:wander_nova/views/flight_ssr/data/repository/ssr_repository_impl.dart';
import 'package:wander_nova/views/flight_ssr/domain/repository/ssr_repository.dart';
import 'package:wander_nova/views/flight_ssr/domain/usecase/get_ssr_usecase.dart';
import 'package:wander_nova/views/flight_ssr/presentation/bloc/ssr_bloc.dart';
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
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().instance,);


  //   Register GoogleSignInService
  sl.registerLazySingleton<GoogleSignInService>(
        () => GoogleSignInService(
      scopes: ['email', 'profile'],
      serverClientId: '99880015098-o585d840371c4j01vc2alcrqa74mevdh.apps.googleusercontent.com',
    ),
  );


  // Data Layer
  sl.registerLazySingleton<AirportApiService>(
        () => AirportApiServiceImpl(sl<DioClient>().instance),);
  sl.registerLazySingleton<AuthApiService>(
        () => AuthApiServiceImpl(sl<Dio>()),);
  sl.registerLazySingleton<FlightApiService>(
        () => FlightApiService(sl<DioClient>()),);
  sl.registerFactory<FareRuleApiService>(
        () => FareRuleApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<FareQuoteApiService>(
        () => FareQuoteApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<SsrApiService>(
          () => SsrApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<CountryApiService>(
        () => CountryApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<DestinationApiService>(
        () => DestinationApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerLazySingleton<HotelApiService>(
        () => HotelApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerLazySingleton<HotelDetailsApiService>(
        () => HotelDetailsApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerFactory<HotelBookingApiService>(
        () => HotelBookingApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerLazySingleton<ExclusiveDealsApiService>(
        () => ExclusiveDealsApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerLazySingleton<T_locationApiService>(
        () => T_locationApiServiceImpl(sl<DioClient>().instance),
  );
  sl.registerLazySingleton<TransportSearchApiService>(() => TransportSearchApiServiceImpl(sl<DioClient>().instance),);
  sl.registerLazySingleton<TpollSearchApiService>(() => TpollSearchApiServiceImpl(sl<DioClient>().instance),);




  // Repository
  sl.registerLazySingleton<AirportRepository>(
        () => AirportRepositoryImpl(sl()),);
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<AuthApiService>()),);
  sl.registerLazySingleton<FlightRepository>(
        () => FlightRepositoryImpl(sl<FlightApiService>()),);
  sl.registerFactory<FareRuleRepository>(
        () => FareRuleRepositoryImpl(sl<FareRuleApiService>()),);
  sl.registerFactory<FareQuoteRepository>(
        () => FareQuoteRepositoryImpl(sl<FareQuoteApiService>()));
  sl.registerFactory<SsrRepository>(
          () => SsrRepositoryImpl(sl<SsrApiService>()));
  sl.registerFactory<CountryRepository>(
        () => CountryRepositoryImpl(sl<CountryApiService>()),);
  sl.registerLazySingleton<DestinationRepository>(
        () => DestinationRepositoryImpl(sl<DestinationApiService>()));
  sl.registerLazySingleton<HotelRepository>(
        () => HotelRepositoryImpl(sl<HotelApiService>()),
  );
  sl.registerLazySingleton<HotelDetailsRepository>(
        () => HotelDetailsRepositoryImpl(sl<HotelDetailsApiService>()),
  );
  sl.registerLazySingleton<HotelBookingRepository>(
        () => HotelBookingRepositoryImpl(sl<HotelBookingApiService>()),
  );

  sl.registerLazySingleton<ExclusiveDealsRepository>(
        () => ExclusiveDealsRepositoryImpl(sl<ExclusiveDealsApiService>()),
  );
  sl.registerLazySingleton<T_locationRepository>(
        () => T_locationRepositoryImpl(sl<T_locationApiService>()),
  );
  sl.registerLazySingleton<TransportSearchRepository>(
        () => TransportSearchRepositoryImpl(sl<TransportSearchApiService>()),
  );
  sl.registerLazySingleton<TpollSearchRepository>(() => TpollSearchRepositoryImpl(sl<TpollSearchApiService>()));





  // Domain Layer - UseCases
  sl.registerLazySingleton<GetAirportsUsecase>(
        () => GetAirportsUsecase(sl()),);
  sl.registerLazySingleton<GoogleLoginUseCase>(
        () => GoogleLoginUseCase(sl<AuthRepository>()),);
  sl.registerLazySingleton<SearchFlightsUseCase>(
        () => SearchFlightsUseCase(sl<FlightRepository>()),);
  sl.registerLazySingleton<GetFareRulesUsecase>(
          () => GetFareRulesUsecase(sl<FareRuleRepository>()));
  sl.registerLazySingleton<FareQuoteUsecase>(
        () => FareQuoteUsecase(sl<FareQuoteRepository>()),);
  sl.registerLazySingleton<GetSsrUsecase>(
          () => GetSsrUsecase(sl<SsrRepository>()));
  sl.registerLazySingleton<GetCountriesUseCase>(() => GetCountriesUseCase(sl()));
  sl.registerLazySingleton<SearchDestinationsUseCase>(
        () => SearchDestinationsUseCase(sl()),);
  sl.registerLazySingleton<GetHotelsByCityUseCase>(() => GetHotelsByCityUseCase(sl()));
  sl.registerLazySingleton<GetHotelDetailsUsecase>(() => GetHotelDetailsUsecase(sl()));
  sl.registerLazySingleton<GetHotelBookingDetailsUseCase>(() => GetHotelBookingDetailsUseCase(sl<HotelBookingRepository>()),);
  sl.registerLazySingleton<GetExclusiveDealsUseCase>(() => GetExclusiveDealsUseCase(sl()));
  sl.registerLazySingleton<GetT_locationsUseCase>(() => GetT_locationsUseCase(sl<T_locationRepository>()));
  sl.registerLazySingleton<TransportSearchUsecase>(() => TransportSearchUsecase(sl()));
  sl.registerLazySingleton<TpollSearchUseCase>(
        () => TpollSearchUseCase(sl<TpollSearchRepository>()),
  );








  // Presentation Layer - Bloc
  sl.registerFactory<AirportBloc>(() => AirportBloc(sl()),);
  sl.registerFactory<AuthBloc>(
        () => AuthBloc(googleLoginUseCase: sl<GoogleLoginUseCase>()),);
  sl.registerFactory<FlightSearchBloc>(
        () => FlightSearchBloc(sl<SearchFlightsUseCase>()),);
  sl.registerFactory<FareRuleBloc>(
        () => FareRuleBloc(getFareRulesUsecase: sl<GetFareRulesUsecase>()),);
  sl.registerFactory<FareQuoteBloc>(
        () => FareQuoteBloc(fareQuoteUsecase: sl<FareQuoteUsecase>()),);
  sl.registerFactory<SsrBloc>(
          () => SsrBloc(getSsrUsecase: sl<GetSsrUsecase>()));
  sl.registerFactory<CountryBloc>(() => CountryBloc(sl()));
  sl.registerFactory<DestinationBloc>(
        () => DestinationBloc(searchDestinationsUseCase: sl()),
  );
  sl.registerFactory<HotelBloc>(() => HotelBloc(getHotelsByCityUseCase: sl()));
  sl.registerFactory<HotelDetailsBloc>(() => HotelDetailsBloc(getHotelDetailsUsecase: sl()));
  sl.registerFactory<HotelBookingBloc>(() => HotelBookingBloc(
      getHotelBookingDetailsUseCase: sl<GetHotelBookingDetailsUseCase>()));
  sl.registerFactory<ExclusiveDealsBloc>(() => ExclusiveDealsBloc(getExclusiveDealsUseCase: sl()));
  sl.registerFactory<T_locationBloc>(() => T_locationBloc(getT_locationsUseCase: sl()));
  sl.registerFactory<TransportSearchBloc>(() => TransportSearchBloc(transportSearchUsecase: sl()));
  sl.registerFactory<TpollSearchBloc>(() => TpollSearchBloc(tpollSearchUseCase: sl<TpollSearchUseCase>()),);



}