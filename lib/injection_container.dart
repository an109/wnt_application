import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/views/AKFlight_tui/data/data_source/akflight_Search_api_service.dart';
import 'package:wander_nova/views/AKFlight_tui/data/repository/akflight_Search_repository_impl.dart';
import 'package:wander_nova/views/AKFlight_tui/domain/repository/akflight_Search_repository.dart';
import 'package:wander_nova/views/AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import 'package:wander_nova/views/AKFlight_tui/presentation/bloc/akflight_Search_bloc.dart';
import 'package:wander_nova/views/AKFlights/data/data_source/AKFlights_api_service.dart';
import 'package:wander_nova/views/AKFlights/data/repository/AKFlights_repository_impl.dart';
import 'package:wander_nova/views/AKFlights/domain/repository/AKFlights_repository.dart';
import 'package:wander_nova/views/AKFlights/domain/usecase/AKFlights_usecase.dart';
import 'package:wander_nova/views/AKFlights/presentation/bloc/AKFlights_bloc.dart';
import 'package:wander_nova/views/AKFlightInfo/data/data_source/AKFlightInfo_api_service.dart';
import 'package:wander_nova/views/AKFlightInfo/data/repository/AKFlightInfo_repository_impl.dart';
import 'package:wander_nova/views/AKFlightInfo/domain/repository/AKFlightInfo_repository.dart';
import 'package:wander_nova/views/AKFlightInfo/domain/usecase/AKFlightInfo_usecase.dart';
import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_bloc.dart';
import 'package:wander_nova/views/AKGetSPricer/data/data_source/AKGetSPricer_api_service.dart';
import 'package:wander_nova/views/AKGetSPricer/data/repository/AKGetSPricer_repository_impl.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/repository/AKGetSPricer_repository.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/usecase/AKGetSPricer_usecase.dart';
import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_bloc.dart';
import 'package:wander_nova/views/AKSmartPricer/data/data_source/AKSmartPricer_api_service.dart';
import 'package:wander_nova/views/AKSmartPricer/data/repository/AKSmartPricer_repository_impl.dart';
import 'package:wander_nova/views/AKSmartPricer/domain/repository/AKSmartPricer_repository.dart';
import 'package:wander_nova/views/AKSmartPricer/domain/usecase/AKSmartPricer_usecase.dart';
import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_bloc.dart';
import 'package:wander_nova/views/AKFareRule/data/data_source/AKFareRule_api_service.dart';
import 'package:wander_nova/views/AKFareRule/data/repository/AKFareRule_repository_impl.dart';
import 'package:wander_nova/views/AKFareRule/domain/repository/AKFareRule_repository.dart';
import 'package:wander_nova/views/AKFareRule/domain/usecase/AKFareRule_usecase.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_bloc.dart';
import 'package:wander_nova/views/AKAcceptFareChange/data/data_source/AKAcceptFareChange_api_service.dart';
import 'package:wander_nova/views/AKAcceptFareChange/data/repository/AKAcceptFareChange_repository_impl.dart';
import 'package:wander_nova/views/AKAcceptFareChange/domain/repository/AKAcceptFareChange_repository.dart';
import 'package:wander_nova/views/AKAcceptFareChange/domain/usecase/AKAcceptFareChange_usecase.dart';
import 'package:wander_nova/views/AKTravelCheckList/data/data_source/AKTravelCheckList_api_service.dart';
import 'package:wander_nova/views/AKTravelCheckList/data/repository/AKTravelCheckList_repository_impl.dart';
import 'package:wander_nova/views/AKTravelCheckList/domain/repository/AKTravelCheckList_repository.dart';
import 'package:wander_nova/views/AKTravelCheckList/domain/usecase/AKTravelCheckList_usecase.dart';
import 'package:wander_nova/views/AKTravelCheckList/presentation/bloc/AKTravelCheckList_bloc.dart';
import 'package:wander_nova/views/AKCreateItinerary/data/data_source/AKCreateItinerary_api_service.dart';
import 'package:wander_nova/views/AKCreateItinerary/data/repository/AKCreateItinerary_repository_impl.dart';
import 'package:wander_nova/views/AKCreateItinerary/domain/repository/AKCreateItinerary_repository.dart';
import 'package:wander_nova/views/AKCreateItinerary/domain/usecase/AKCreateItinerary_usecase.dart';
import 'package:wander_nova/views/AKCreateItinerary/presentation/bloc/AKCreateItinerary_bloc.dart';
import 'package:wander_nova/views/AKStartPay/data/data_source/AKStartPay_api_service.dart';
import 'package:wander_nova/views/AKStartPay/data/repository/AKStartPay_repository_impl.dart';
import 'package:wander_nova/views/AKStartPay/domain/repository/AKStartPay_repository.dart';
import 'package:wander_nova/views/AKStartPay/domain/usecase/AKStartPay_usecase.dart';
import 'package:wander_nova/views/AKStartPay/presentation/bloc/AKStartPay_bloc.dart';
import 'package:wander_nova/views/AKRetrieveBooking/data/data_source/AKRetrieveBooking_api_service.dart';
import 'package:wander_nova/views/AKRetrieveBooking/data/repository/AKRetrieveBooking_repository_impl.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/repository/AKRetrieveBooking_repository.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/usecase/AKRetrieveBooking_usecase.dart';
import 'package:wander_nova/views/AKRetrieveBooking/presentation/bloc/AKRetrieveBooking_bloc.dart';
import 'package:wander_nova/views/AKInsurance/data/data_source/AKInsurance_api_service.dart';
import 'package:wander_nova/views/AKInsurance/data/repository/AKInsurance_repository_impl.dart';
import 'package:wander_nova/views/AKInsurance/domain/repository/AKInsurance_repository.dart';
import 'package:wander_nova/views/AKInsurance/domain/usecase/AKInsurance_usecase.dart';
import 'package:wander_nova/views/AKInsurance/domain/usecase/resolve_trip_destination_usecase.dart';
import 'package:wander_nova/views/AKInsurance/presentation/bloc/AKInsurance_bloc.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/data/data_source/AKHotelAutosuggest_api_service.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/data/repository/AKHotelAutosuggest_repository_impl.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/domain/repository/AKHotelAutosuggest_repository.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/domain/usecase/AKHotelAutosuggest_usecase.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/presentation/bloc/AKHotelAutosuggest_bloc.dart';
import 'package:wander_nova/views/AKHotelSearchInit/data/data_source/AKHotelSearchInit_api_service.dart';
import 'package:wander_nova/views/AKHotelSearchInit/data/repository/AKHotelSearchInit_repository_impl.dart';
import 'package:wander_nova/views/AKHotelSearchInit/domain/repository/AKHotelSearchInit_repository.dart';
import 'package:wander_nova/views/AKHotelSearchInit/domain/usecase/AKHotelSearchInit_usecase.dart';
import 'package:wander_nova/views/AKHotelResultContent/data/data_source/AKHotelResultContent_api_service.dart';
import 'package:wander_nova/views/AKHotelResultContent/data/repository/AKHotelResultContent_repository_impl.dart';
import 'package:wander_nova/views/AKHotelResultContent/domain/repository/AKHotelResultContent_repository.dart';
import 'package:wander_nova/views/AKHotelResultContent/domain/usecase/AKHotelResultContent_usecase.dart';
import 'package:wander_nova/views/AKHotelResultRate/data/data_source/AKHotelResultRate_api_service.dart';
import 'package:wander_nova/views/AKHotelResultRate/data/repository/AKHotelResultRate_repository_impl.dart';
import 'package:wander_nova/views/AKHotelResultRate/domain/repository/AKHotelResultRate_repository.dart';
import 'package:wander_nova/views/AKHotelResultRate/domain/usecase/AKHotelResultRate_usecase.dart';
import 'package:wander_nova/views/AKHotelFilterData/data/data_source/AKHotelFilterData_api_service.dart';
import 'package:wander_nova/views/AKHotelFilterData/data/repository/AKHotelFilterData_repository_impl.dart';
import 'package:wander_nova/views/AKHotelFilterData/domain/repository/AKHotelFilterData_repository.dart';
import 'package:wander_nova/views/AKHotelFilterData/domain/usecase/AKHotelFilterData_usecase.dart';
import 'package:wander_nova/views/AKHotelRooms/data/data_source/AKHotelRooms_api_service.dart';
import 'package:wander_nova/views/AKHotelRooms/data/repository/AKHotelRooms_repository_impl.dart';
import 'package:wander_nova/views/AKHotelRooms/domain/repository/AKHotelRooms_repository.dart';
import 'package:wander_nova/views/AKHotelRooms/domain/usecase/AKHotelRooms_usecase.dart';
import 'package:wander_nova/views/AKHotelDetailContent/data/data_source/AKHotelDetailContent_api_service.dart';
import 'package:wander_nova/views/AKHotelDetailContent/data/repository/AKHotelDetailContent_repository_impl.dart';
import 'package:wander_nova/views/AKHotelDetailContent/domain/repository/AKHotelDetailContent_repository.dart';
import 'package:wander_nova/views/AKHotelDetailContent/domain/usecase/AKHotelDetailContent_usecase.dart';
import 'package:wander_nova/views/AKHotelPrice/data/data_source/AKHotelPrice_api_service.dart';
import 'package:wander_nova/views/AKHotelPrice/data/repository/AKHotelPrice_repository_impl.dart';
import 'package:wander_nova/views/AKHotelPrice/domain/repository/AKHotelPrice_repository.dart';
import 'package:wander_nova/views/AKHotelPrice/domain/usecase/AKHotelPrice_usecase.dart';
import 'package:wander_nova/views/AKHotelCreateItinerary/data/data_source/AKHotelCreateItinerary_api_service.dart';
import 'package:wander_nova/views/AKHotelCreateItinerary/data/repository/AKHotelCreateItinerary_repository_impl.dart';
import 'package:wander_nova/views/AKHotelCreateItinerary/domain/repository/AKHotelCreateItinerary_repository.dart';
import 'package:wander_nova/views/AKHotelCreateItinerary/domain/usecase/AKHotelCreateItinerary_usecase.dart';
import 'package:wander_nova/views/AKHotelStartPay/data/data_source/AKHotelStartPay_api_service.dart';
import 'package:wander_nova/views/AKHotelStartPay/data/repository/AKHotelStartPay_repository_impl.dart';
import 'package:wander_nova/views/AKHotelStartPay/domain/repository/AKHotelStartPay_repository.dart';
import 'package:wander_nova/views/AKHotelStartPay/domain/usecase/AKHotelStartPay_usecase.dart';
import 'package:wander_nova/views/AKHotelRetrieveBooking/data/data_source/AKHotelRetrieveBooking_api_service.dart';
import 'package:wander_nova/views/AKHotelRetrieveBooking/data/repository/AKHotelRetrieveBooking_repository_impl.dart';
import 'package:wander_nova/views/AKHotelRetrieveBooking/domain/repository/AKHotelRetrieveBooking_repository.dart';
import 'package:wander_nova/views/AKHotelRetrieveBooking/domain/usecase/AKHotelRetrieveBooking_usecase.dart';
import 'package:wander_nova/views/AKSsr/data/data_source/AKSsr_api_service.dart';
import 'package:wander_nova/views/AKSsr/data/repository/AKSsr_repository_impl.dart';
import 'package:wander_nova/views/AKSsr/domain/repository/AKSsr_repository.dart';
import 'package:wander_nova/views/AKSsr/domain/usecase/AKSsr_usecase.dart';
import 'package:wander_nova/views/AKSsr/presentation/bloc/AKSsr_bloc.dart';
import 'package:wander_nova/views/AKSelectSsr/data/data_source/AKSelectSsr_api_service.dart';
import 'package:wander_nova/views/AKSelectSsr/data/repository/AKSelectSsr_repository_impl.dart';
import 'package:wander_nova/views/AKSelectSsr/domain/repository/AKSelectSsr_repository.dart';
import 'package:wander_nova/views/AKSelectSsr/domain/usecase/AKSelectSsr_usecase.dart';
import 'package:wander_nova/views/AKSeatLayout/data/data_source/AKSeatLayout_api_service.dart';
import 'package:wander_nova/views/AKSeatLayout/data/repository/AKSeatLayout_repository_impl.dart';
import 'package:wander_nova/views/AKSeatLayout/domain/repository/AKSeatLayout_repository.dart';
import 'package:wander_nova/views/AKSeatLayout/domain/usecase/AKSeatLayout_usecase.dart';
import 'package:wander_nova/views/AKSeatLayout/presentation/bloc/AKSeatLayout_bloc.dart';
import 'package:wander_nova/views/AKSelectSeats/data/data_source/AKSelectSeats_api_service.dart';
import 'package:wander_nova/views/AKSelectSeats/data/repository/AKSelectSeats_repository_impl.dart';
import 'package:wander_nova/views/AKSelectSeats/domain/repository/AKSelectSeats_repository.dart';
import 'package:wander_nova/views/AKSelectSeats/domain/usecase/AKSelectSeats_usecase.dart';
import 'package:wander_nova/views/DeleteAccount/data/data_source/delete_account_api_service.dart';
import 'package:wander_nova/views/DeleteAccount/data/repository/delete_account_repository_impl.dart';
import 'package:wander_nova/views/DeleteAccount/domain/repository/delete_account_repository.dart';
import 'package:wander_nova/views/DeleteAccount/domain/usecase/delete_account_usecase.dart';
import 'package:wander_nova/views/DeleteAccount/presentation/bloc/delete_account_bloc.dart';
import 'package:wander_nova/views/Dashboard/Section/data/traveller_api_service.dart';
import 'package:wander_nova/views/Document/domain/usecase/upload_document_usecase.dart';
import 'package:wander_nova/views/Exchange_rate/data/data_source/exchange_rate_api_service.dart';
import 'package:wander_nova/views/Exchange_rate/data/repository/exchange_rate_repository_impl.dart';
import 'package:wander_nova/views/Exchange_rate/domain/repository/exchange_rate_repository.dart';
import 'package:wander_nova/views/Exchange_rate/domain/usecase/convert_currency_usecase.dart';
import 'package:wander_nova/views/Exchange_rate/domain/usecase/get_exchange_rates_usecase.dart';
import 'package:wander_nova/views/Exchange_rate/presentation/bloc/exchange_rate_bloc.dart';
import 'package:wander_nova/views/ExclusiveDeals/data/data_source/exclusive_deals_api_service.dart';
import 'package:wander_nova/views/ExclusiveDeals/data/repository/exclusive_deals_repository_impl.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/repository/exclusive_deals_repository.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/usecase/get_exclusive_deals_usecase.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import 'package:wander_nova/views/Holiday_destination/data/data_source/holiday_destination_api_service.dart';
import 'package:wander_nova/views/Holiday_destination/data/repository/holiday_destination_repository_impl.dart';
import 'package:wander_nova/views/Holiday_destination/domain/repository/holiday_repository.dart';
import 'package:wander_nova/views/Holiday_destination/domain/usecase/get_detination_usecase.dart';
import 'package:wander_nova/views/Holiday_destination/presentation/bloc/holiday_destination_bloc.dart';
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
import 'package:wander_nova/views/LogOut/data/data_source/logout_api_service.dart';
import 'package:wander_nova/views/LogOut/data/repository/logout_repository_impl.dart';
import 'package:wander_nova/views/LogOut/domain/repository/logout_repository.dart';
import 'package:wander_nova/views/LogOut/domain/usecase/logout_usecase.dart';
import 'package:wander_nova/views/LogOut/presentation/bloc/logout_bloc.dart';
import 'package:wander_nova/views/MainApi/data/data_source/general_setting_api_service.dart';
import 'package:wander_nova/views/MainApi/data/respository/general_setting_repository_impl.dart';
import 'package:wander_nova/views/MainApi/domain/repository/general_setting_repository.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_faq_list_usecase.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_general_setting_usecase.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_promo_codes_usecase.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_section_heros_usecase.dart';
import 'package:wander_nova/views/MainApi/presentation/bloc/general_setting_bloc.dart';
import 'package:wander_nova/views/MyBookings/Flights/data/data_source/FlightBookApiService.dart';
import 'package:wander_nova/views/MyBookings/Flights/domain/repository/FlightBookRepository.dart';
import 'package:wander_nova/views/MyBookings/Flights/presentation/bloc/FlightBookBloc.dart';
import 'package:wander_nova/views/MyBookings/Hotels/data/data_Source/HotelApiService.dart';
import 'package:wander_nova/views/MyBookings/Hotels/data/repository/HotelRespositoryImpl.dart';
import 'package:wander_nova/views/MyBookings/Hotels/domain/repository/HotelRepository.dart';
import 'package:wander_nova/views/MyBookings/Hotels/domain/usecase/getHotelBookingUsecase.dart';
import 'package:wander_nova/views/MyBookings/Hotels/bloc/BookingListBloc.dart';
import 'package:wander_nova/views/MyBookings/Transport/data/data_source/MyBookng_api_Service.dart';
import 'package:wander_nova/views/MyBookings/Transport/data/repository/MyBooking_repository_impl.dart';
import 'package:wander_nova/views/MyBookings/Transport/domain/repository/MyBooking_repository.dart';
import 'package:wander_nova/views/MyBookings/Transport/domain/usecase/get_bookings_usecase.dart';
import 'package:wander_nova/views/MyBookings/Transport/bloc/MyBooking_bloc.dart';
import 'package:wander_nova/views/MyBookings/visa/bloc/VBloc.dart';
import 'package:wander_nova/views/MyBookings/visa/data/data_source/V_api_service.dart';
import 'package:wander_nova/views/MyBookings/visa/data/repository/VRepository_impl.dart';
import 'package:wander_nova/views/MyBookings/visa/domain/repository/VRepository.dart';
import 'package:wander_nova/views/MyBookings/visa/domain/usecase/VApp_usecase.dart';
import 'package:wander_nova/views/Profile/data/data_source/Profile_api_service.dart';
import 'package:wander_nova/views/Profile/data/repository/Profile_repository_impl.dart';
import 'package:wander_nova/views/Profile/domain/repository/Profile_repository.dart';

import 'package:wander_nova/views/Profile/domain/usecase/get_profile_usecase.dart';
import 'package:wander_nova/views/Profile/domain/usecase/patch_profile_usecase.dart';
import 'package:wander_nova/views/Profile/domain/usecase/update_profile_usecase.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';
import 'package:wander_nova/views/ReferCode/data/data_source/referral_api_service.dart';
import 'package:wander_nova/views/ReferCode/data/repository/referral_repository_impl.dart';
import 'package:wander_nova/views/ReferCode/domain/repository/referral_repository.dart';
import 'package:wander_nova/views/ReferCode/domain/usecase/get_referral_usecase.dart';
import 'package:wander_nova/views/ReferCode/presentation/bloc/referral_bloc.dart';
import 'package:wander_nova/views/ReferCredit/data/data_source/transaction_api_service.dart';
import 'package:wander_nova/views/ReferCredit/data/repository/transaction_repository_impl.dart';
import 'package:wander_nova/views/ReferCredit/domain/repository/transaction_repository.dart';
import 'package:wander_nova/views/ReferCredit/domain/usecase/get_transaction_usecase.dart';
import 'package:wander_nova/views/ReferCredit/presentation/bloc/transaction_bloc.dart';
import 'package:wander_nova/views/ResetPassword/data/data_source/reset_password_api_service.dart';
import 'package:wander_nova/views/ResetPassword/data/repository/reset_password_repository_impl.dart';
import 'package:wander_nova/views/ResetPassword/domain/repository/reset_password_repository.dart';
import 'package:wander_nova/views/ResetPassword/domain/usecase/reset_password_usecase.dart';
import 'package:wander_nova/views/ResetPassword/presentation/bloc/reset_password_bloc.dart';
import 'package:wander_nova/views/TPoll_Search/data/data_source/TPoll_Search_api-service.dart';
import 'package:wander_nova/views/TPoll_Search/data/repository/TPoll_search_repository_impl.dart';
import 'package:wander_nova/views/TPoll_Search/domain/repository/TPoll_Search_repository.dart';
import 'package:wander_nova/views/TPoll_Search/domain/usecase/TPoll_search_usecase.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchBloc.dart';
import 'package:wander_nova/views/TReservation_poll/data/data_source/poll_api_service.dart';
import 'package:wander_nova/views/TReservation_poll/data/repository/poll_repository_impl.dart';
import 'package:wander_nova/views/TReservation_poll/domain/repository/poll_repository.dart';
import 'package:wander_nova/views/TReservation_poll/domain/usecase/get_poll_usecase.dart';
import 'package:wander_nova/views/TReservation_poll/presentation/bloc/poll_bloc.dart';
import 'package:wander_nova/views/TResevation/data/data_source/TReservation_api_service.dart';
import 'package:wander_nova/views/TResevation/data/repository/TReposiotry_impl.dart';
import 'package:wander_nova/views/TResevation/domain/repository/TReservation_repository.dart';
import 'package:wander_nova/views/TResevation/domain/usecase/TReservation_usecase.dart';
import 'package:wander_nova/views/TResevation/presentation/bloc/TReservation_bloc.dart';
import 'package:wander_nova/views/TResult/data/data_source/TResult_api_service.dart';
import 'package:wander_nova/views/TResult/data/repository/TResult_repository_impl.dart';
import 'package:wander_nova/views/TResult/domain/repository/TResult_repository.dart';
import 'package:wander_nova/views/TResult/domain/usecase/get_TResult_usecase.dart';
import 'package:wander_nova/views/TResult/presentation/bloc/TResult_bloc.dart';
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
import 'package:wander_nova/views/UpcomingTrips/data/data_source/upcomingTrip_api_service.dart';
import 'package:wander_nova/views/UpcomingTrips/data/repository/upcomingTrip_repository_impl.dart';
import 'package:wander_nova/views/UpcomingTrips/domain/repository/upcomingTrip_repository.dart';
import 'package:wander_nova/views/UpcomingTrips/domain/usecase/get_upcomingTrip_usecase.dart';
import 'package:wander_nova/views/UpcomingTrips/presentation/bloc/upcomingTrip_bloc.dart';
import 'package:wander_nova/views/Verify_otp/data/data_source/verify_otp_api_service.dart';
import 'package:wander_nova/views/Verify_otp/data/repository/verify_otp_repository_impl.dart';
import 'package:wander_nova/views/Verify_otp/domain/repository/verify_otp_repository.dart';
import 'package:wander_nova/views/Verify_otp/domain/usecase/verify_otp_usecase.dart';
import 'package:wander_nova/views/Verify_otp/presentation/bloc/verify_otp_bloc.dart';
import 'package:wander_nova/views/VisaApplication/data/data_source/visa_api_service.dart';
import 'package:wander_nova/views/VisaApplication/data/repository/visaRepository_impl.dart';
import 'package:wander_nova/views/VisaApplication/domain/repository/visaRepository.dart';
import 'package:wander_nova/views/VisaApplication/domain/usecase/create_visa_application_usecase.dart';
import 'package:wander_nova/views/VisaApplication/domain/usecase/get_visaBy_id.dart';
import 'package:wander_nova/views/VisaApplication/domain/usecase/visaUsecase.dart';
import 'package:wander_nova/views/VisaApplication/presentation/bloc/visaBloc.dart';
import 'package:wander_nova/views/VisaDestination/data/data_source/visaDestin_apiService.dart';
import 'package:wander_nova/views/VisaDestination/data/repository/visaDestin_Repository_impl.dart';
import 'package:wander_nova/views/VisaDestination/domain/repository/visaDestin_Repository.dart';
import 'package:wander_nova/views/VisaDestination/domain/usecase/get_visaDestin_usecase.dart';
import 'package:wander_nova/views/VisaDestination/presentation/bloc/visaDestin_bloc.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/data/data_source/visa_destination_api_service.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/data/repository/visa_destination_repository_impl.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/domain/repository/visa_destination_repository.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/domain/usecase/get_visa_destination_usecase.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/presentation/bloc/visa_destination_bloc.dart';
import 'package:wander_nova/views/WalletStatus/data/data_source/loyality_api_service.dart';
import 'package:wander_nova/views/WalletStatus/data/repository/loyality_repository_impl.dart';
import 'package:wander_nova/views/WalletStatus/domain/repository/loyality_repository.dart';
import 'package:wander_nova/views/WalletStatus/domain/usecase/get_loyality_usecase.dart';
import 'package:wander_nova/views/WalletStatus/presentation/bloc/loyalty_bloc.dart';
import 'package:wander_nova/views/airport/data/data_source/airport_api_service.dart';
import 'package:wander_nova/views/airport/data/repository/airport_repositories_impl.dart';
import 'package:wander_nova/views/airport/domain/repository/airport_repositories.dart';
import 'package:wander_nova/views/airport/domain/usecases/get_airport_usecase.dart';
import 'package:wander_nova/views/airport/presentation/bloc/airport_bloc.dart';
import 'package:wander_nova/views/auth/data/data_source/auth_api_source.dart';
import 'package:wander_nova/views/auth/data/repository/auth_repository_impl.dart';
import 'package:wander_nova/views/auth/domain/repository/auth_repository.dart';
import 'package:wander_nova/views/auth/domain/usecase/google_auth_usecase.dart';
import 'package:wander_nova/views/auth/domain/usecase/apple_auth_usecase.dart';
import 'package:wander_nova/views/auth/presentation/bloc/auth_bloc.dart';
import 'package:wander_nova/views/auth/presentation/sdk/google_sign_in_service.dart';
import 'package:wander_nova/views/auth/presentation/sdk/apple_sign_in_service.dart';
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
import 'package:wander_nova/views/flight_booking/data/data_source/booking_api_service.dart';
import 'package:wander_nova/views/flight_booking/data/repository/booking_repository_impl.dart';
import 'package:wander_nova/views/flight_booking/domain/repository/booking_repository.dart';
import 'package:wander_nova/views/flight_booking/domain/usecase/book_flight_usecase.dart';
import 'package:wander_nova/views/flight_booking/presentation/bloc/booking_bloc.dart';
import 'package:wander_nova/views/flight_ticket/data/data_source/ticket_api_service.dart';
import 'package:wander_nova/views/flight_ticket/data/repository/ticket_repository_impl.dart';
import 'package:wander_nova/views/flight_ticket/domain/repository/ticket_repository.dart';
import 'package:wander_nova/views/flight_ticket/domain/usecase/issue_ticket_usecase.dart';
import 'package:wander_nova/views/flight_ticket/presentation/bloc/ticket_bloc.dart';
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
import 'package:wander_nova/views/flight_popularDestination/data/data_source/destination_api_service.dart';
import 'package:wander_nova/views/flight_popularDestination/data/repository/destination_repository_impl.dart';
import 'package:wander_nova/views/flight_popularDestination/domain/repository/destination_repository.dart';
import 'package:wander_nova/views/flight_popularDestination/domain/usecase/get_popular_destination_usecase.dart';
import 'package:wander_nova/views/flight_popularDestination/presentation/bloc/destination_bloc.dart';
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
import 'package:wander_nova/views/footer/data/data_source/footer_setting_api_service.dart';
import 'package:wander_nova/views/footer/data/repository/footer_repository_impl.dart';
import 'package:wander_nova/views/footer/domain/repository/footer_setting_repository.dart';
import 'package:wander_nova/views/footer/domain/usecase/get_footer_settings_usecase.dart';
import 'package:wander_nova/views/footer/presentation/bloc/footer_setting_bloc.dart';
import 'package:wander_nova/views/login/data/data_source/login_api_service.dart';
import 'package:wander_nova/views/login/data/repository/login_repository_impl.dart';
import 'package:wander_nova/views/login/domain/repository/login_repository.dart';
import 'package:wander_nova/views/login/domain/usecase/login_usecase.dart';
import 'package:wander_nova/views/login/presentation/bloc/login_bloc.dart';
import 'package:wander_nova/views/signup/data/data_source/signup_api_service.dart';
import 'package:wander_nova/views/signup/data/repository/signup_repository_impl.dart';
import 'package:wander_nova/views/signup/domain/repository/signup_repository.dart';
import 'package:wander_nova/views/signup/domain/usecase/signup_usecase.dart';
import 'package:wander_nova/views/signup/presentation/bloc/signup_bloc.dart';
import 'package:wander_nova/views/travel_stories/data/data_source/travel_stories_api_service.dart';
import 'package:wander_nova/views/travel_stories/data/repository/travel_stories_repository_impl.dart';
import 'package:wander_nova/views/travel_stories/domain/repository/travel_stories_repository.dart';
import 'package:wander_nova/views/travel_stories/domain/usecase/get_travel_stories_by_slug_usecase.dart';
import 'package:wander_nova/views/travel_stories/domain/usecase/get_travel_stories_usecase.dart';
import 'package:wander_nova/views/travel_stories/presentation/bloc/travel_stories_bloc.dart';
import 'package:wander_nova/views/trending_route/data/data_source/trending_route_api_service.dart';
import 'package:wander_nova/views/trending_route/data/repository/trending_routes_repository_impl.dart';
import 'package:wander_nova/views/trending_route/domain/repository/trending_routes_repository.dart';
import 'package:wander_nova/views/trending_route/domain/usecase/get_trending_routes_usecase.dart';
import 'package:wander_nova/views/trending_route/presentation/bloc/trending_routes_bloc.dart';
import 'package:wander_nova/views/wallet/data/data_source/wallet_api_service.dart';
import 'package:wander_nova/views/wallet/data/repository/wallet_repository_impl.dart';
import 'package:wander_nova/views/wallet/domain/repository/wallet_repository.dart';
import 'package:wander_nova/views/wallet/domain/usecase/get_wallet_balance_usecase.dart';
import 'package:wander_nova/views/wallet/presentation/bloc/wallet_bloc.dart';
import 'views/Document/data/data_source/document_api_service.dart';
import 'views/Document/data/repository/Document_repository_impl.dart';
import 'views/Document/domain/repository/document_repository.dart';
import 'views/Document/domain/usecase/document_usecase.dart';
import 'views/Document/domain/usecase/submit_payment_usecase.dart';
import 'views/Document/presentation/bloc/document_bloc.dart';
import 'views/MyBookings/Flights/data/repository/FlightBookRepo_impl.dart';
import 'views/MyBookings/Flights/domain/usecase/GetFlightBookUsecase.dart';
import 'views/Send_otp/data/data_source/send_otp_api_service.dart';
import 'views/Send_otp/data/repository/send_otp_repository_impl.dart';
import 'views/Send_otp/domain/repository/end_otp_repository.dart';
import 'views/Send_otp/domain/usecase/send_otp_usecase.dart';
import 'views/Send_otp/presentation/bloc/send_otp_bloc.dart';
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

  //   Register AppleSignInService
  sl.registerLazySingleton<AppleSignInService>(() => AppleSignInService());


  // Data Layer
  sl.registerLazySingleton<AirportApiService>(() => AirportApiServiceImpl(sl<DioClient>().instance),);
  sl.registerLazySingleton<AuthApiService>(() => AuthApiServiceImpl(sl<Dio>()),);
  sl.registerLazySingleton<FlightApiService>(() => FlightApiService(sl<DioClient>()),);
  sl.registerFactory<FareRuleApiService>(() => FareRuleApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<FareQuoteApiService>(() => FareQuoteApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<SsrApiService>(() => SsrApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<BookingApiService>(() => BookingApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<TicketApiService>(() => TicketApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<CountryApiService>(() => CountryApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<DestinationApiService>(() => DestinationApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<HotelApiService>(() => HotelApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<HotelDetailsApiService>(() => HotelDetailsApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<HotelBookingApiService>(() => HotelBookingApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<ExclusiveDealsApiService>(() => ExclusiveDealsApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<T_locationApiService>(() => T_locationApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<TransportSearchApiService>(() => TransportSearchApiServiceImpl(sl<DioClient>().instance),);
  sl.registerLazySingleton<TpollSearchApiService>(() => TpollSearchApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<TransportResultApiService>(() => TransportResultApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<TransportReservationApiService>(() => TransportReservationApiServiceImpl(sl<DioClient>().instance),);
  sl.registerLazySingleton<PopularDestinationApiService>(() => PopularDestinationApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<TrendingRoutesApiService>(() => TrendingRoutesApiServiceImpl(sl<DioClient>().instance));
  sl.registerLazySingleton<TravelStoriesApiService>(() => TravelStoriesApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<VisaPopularDestinationApiService>(() => VisaPopularDestinationApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<FooterSettingsApiService>(() => FooterSettingsApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<VisaDestinationApiService>(() => VisaDestinationApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<GeneralSettingsApiService>(() => GeneralSettingsApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<HolidayApiService>(() => HolidayApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<ExchangeRateApiService>(() => ExchangeRateApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<SendOtpApiService>(() => SendOtpApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<VerifyOtpApiService>(() => VerifyOtpApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<ResetPasswordApiService>(() => ResetPasswordApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<SignupApiService>(() => SignupApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<LoginApiService>(() => LoginApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<WalletApiService>(() => WalletApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<LogoutApiService>(() => LogoutApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<DeleteAccountApiService>(() => DeleteAccountApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<ProfileApiService>(() => ProfileApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<MyBookingApiService>(() => MyBookingApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<UpcomingTripApiService>(() => UpcomingTripApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<ReferralApiService>(() => ReferralApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<LoyaltyApiService>(() => LoyaltyApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<TransactionApiService>(() => TransactionApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<HotelListApiService>(() => HotelListApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<ReservationPollApiService>(() => ReservationPollApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<VisaApplicationApiService>(() => VisaApplicationApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<VApiService>(() => VApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<FlightBookApiService>(() => FlightBookApiServiceImpl(sl<DioClient>().instance),);
  sl.registerFactory<DocumentVisaApiService>(() => DocumentVisaApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<TravellerApiService>(() => TravellerApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkFlightSearchApiService>(() => AkFlightSearchApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkflightsApiService>(() => AkflightsApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkFlightInfoApiService>(() => AkFlightInfoApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkGetSPricerApiService>(() => AkGetSPricerApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkSmartPricerApiService>(() => AkSmartPricerApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkFareRuleApiService>(() => AkFareRuleApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkAcceptFareChangeApiService>(() => AkAcceptFareChangeApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkTravelCheckListApiService>(() => AkTravelCheckListApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkCreateItineraryApiService>(() => AkCreateItineraryApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkStartPayApiService>(() => AkStartPayApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkRetrieveBookingApiService>(() => AkRetrieveBookingApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkSsrApiService>(() => AkSsrApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkSelectSsrApiService>(() => AkSelectSsrApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkSeatLayoutApiService>(() => AkSeatLayoutApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkSelectSeatsApiService>(() => AkSelectSeatsApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelAutosuggestApiService>(() => AkHotelAutosuggestApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelSearchInitApiService>(() => AkHotelSearchInitApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelResultContentApiService>(() => AkHotelResultContentApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelResultRateApiService>(() => AkHotelResultRateApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelFilterDataApiService>(() => AkHotelFilterDataApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelRoomsApiService>(() => AkHotelRoomsApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelDetailContentApiService>(() => AkHotelDetailContentApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelPriceApiService>(() => AkHotelPriceApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelCreateItineraryApiService>(() => AkHotelCreateItineraryApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelStartPayApiService>(() => AkHotelStartPayApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkHotelRetrieveBookingApiService>(() => AkHotelRetrieveBookingApiServiceImpl(sl<DioClient>().instance));
  sl.registerFactory<AkInsuranceApiService>(() => AkInsuranceApiServiceImpl(sl<DioClient>().instance));








  // Repository
  sl.registerLazySingleton<AirportRepository>(() => AirportRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthApiService>()));
  sl.registerLazySingleton<FlightRepository>(() => FlightRepositoryImpl(sl<FlightApiService>()));
  sl.registerFactory<FareRuleRepository>(() => FareRuleRepositoryImpl(sl<FareRuleApiService>()));
  sl.registerFactory<FareQuoteRepository>(() => FareQuoteRepositoryImpl(sl<FareQuoteApiService>()));
  sl.registerFactory<SsrRepository>(() => SsrRepositoryImpl(sl<SsrApiService>()));
  sl.registerFactory<BookingRepository>(() => BookingRepositoryImpl(sl<BookingApiService>()));
  sl.registerFactory<TicketRepository>(() => TicketRepositoryImpl(sl<TicketApiService>()));
  sl.registerFactory<CountryRepository>(() => CountryRepositoryImpl(sl<CountryApiService>()),);
  sl.registerLazySingleton<DestinationRepository>(() => DestinationRepositoryImpl(sl<DestinationApiService>()));
  sl.registerLazySingleton<HotelRepository>(() => HotelRepositoryImpl(sl<HotelApiService>()));
  sl.registerLazySingleton<HotelDetailsRepository>(() => HotelDetailsRepositoryImpl(sl<HotelDetailsApiService>()));
  sl.registerLazySingleton<HotelBookingRepository>(() => HotelBookingRepositoryImpl(sl<HotelBookingApiService>()));
  sl.registerLazySingleton<ExclusiveDealsRepository>(() => ExclusiveDealsRepositoryImpl(sl<ExclusiveDealsApiService>()));
  sl.registerLazySingleton<T_locationRepository>(() => T_locationRepositoryImpl(sl<T_locationApiService>()));
  sl.registerLazySingleton<TransportSearchRepository>(() => TransportSearchRepositoryImpl(sl<TransportSearchApiService>()));
  sl.registerLazySingleton<TpollSearchRepository>(() => TpollSearchRepositoryImpl(sl<TpollSearchApiService>()));
  sl.registerLazySingleton<TransportResultRepository>(() => TransportResultRepositoryImpl(sl<TransportResultApiService>()));
  sl.registerLazySingleton<TransportReservationRepository>(() => TransportReservationRepositoryImpl(sl<TransportReservationApiService>()),);
  sl.registerLazySingleton<PopularDestinationRepository>(() => PopularDestinationRepositoryImpl(sl()));
  sl.registerLazySingleton<TrendingRoutesRepository>(() => TrendingRoutesRepositoryImpl(sl()),);
  sl.registerLazySingleton<TravelStoriesRepository>(() => TravelStoriesRepositoryImpl(sl<TravelStoriesApiService>()));
  sl.registerLazySingleton<VisaPopularDestinationRepository>(() => VisaPopularDestinationRepositoryImpl(sl<VisaPopularDestinationApiService>()),);
  sl.registerLazySingleton<FooterSettingsRepository>(() => FooterSettingsRepositoryImpl(sl<FooterSettingsApiService>()));
  sl.registerLazySingleton<VisaDestinationRepository>(() => VisaDestinationRepositoryImpl(sl<VisaDestinationApiService>()));
  sl.registerLazySingleton<GeneralSettingsRepository>(() => GeneralSettingsRepositoryImpl(sl<GeneralSettingsApiService>()));
  sl.registerLazySingleton<HolidayRepository>(() => HolidayRepositoryImpl(sl<HolidayApiService>()));
  sl.registerLazySingleton<ExchangeRateRepository>(() => ExchangeRateRepositoryImpl(sl<ExchangeRateApiService>()));
  sl.registerLazySingleton<SendOtpRepository>(() => SendOtpRepositoryImpl(sl<SendOtpApiService>()));
  sl.registerLazySingleton<VerifyOtpRepository>(() => VerifyOtpRepositoryImpl(sl<VerifyOtpApiService>()));
  sl.registerLazySingleton<ResetPasswordRepository>(() => ResetPasswordRepositoryImpl(sl<ResetPasswordApiService>()));
  sl.registerLazySingleton<SignupRepository>(() => SignupRepositoryImpl(sl<SignupApiService>()),);
  sl.registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl(sl<LoginApiService>()),);
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(sl<WalletApiService>()));
  sl.registerLazySingleton<LogoutRepository>(() => LogoutRepositoryImpl(sl<LogoutApiService>()),);
  sl.registerLazySingleton<DeleteAccountRepository>(() => DeleteAccountRepositoryImpl(sl<DeleteAccountApiService>(), sl<PreferencesManager>()),);
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl<ProfileApiService>()));
  sl.registerLazySingleton<MyBookingRepository>(() => MyBookingRepositoryImpl(sl<MyBookingApiService>(), sl<PreferencesManager>()));
  sl.registerLazySingleton<UpcomingTripRepository>(() => UpcomingTripRepositoryImpl(apiService: sl<UpcomingTripApiService>()));
  sl.registerLazySingleton<ReferralRepository>(() => ReferralRepositoryImpl(sl()),);
  sl.registerLazySingleton<LoyaltyRepository>(() => LoyaltyRepositoryImpl(sl()));
  sl.registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(sl()),);
  sl.registerLazySingleton<HotelListRepository>(() => HotelListRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<ReservationPollRepository>(() => ReservationPollRepositoryImpl(sl()),);
  sl.registerLazySingleton<VisaApplicationRepository>(() => VisaApplicationRepositoryImpl(sl()));
  sl.registerLazySingleton<VRepository>(() => VRepositoryImpl(sl<VApiService>()),);
  sl.registerLazySingleton<FlightBookRepository>(
        () => FlightBookRepositoryImpl(sl<FlightBookApiService>()));
  sl.registerLazySingleton<DocumentRepository>(() => DocumentRepositoryImpl(sl<DocumentVisaApiService>()));
  sl.registerLazySingleton<AkFlightSearchRepository>(() => AkFlightSearchRepositoryImpl(sl<AkFlightSearchApiService>()));
  sl.registerLazySingleton<AkflightsRepository>(() => AkflightsRepositoryImpl(sl()),);
  sl.registerLazySingleton<AkFlightInfoRepository>(() => AkFlightInfoRepositoryImpl(sl<AkFlightInfoApiService>()));
  sl.registerLazySingleton<AkGetSPricerRepository>(() => AkGetSPricerRepositoryImpl(sl<AkGetSPricerApiService>()));
  sl.registerLazySingleton<AkSmartPricerRepository>(() => AkSmartPricerRepositoryImpl(sl<AkSmartPricerApiService>()));
  sl.registerLazySingleton<AkFareRuleRepository>(() => AkFareRuleRepositoryImpl(sl<AkFareRuleApiService>()));
  sl.registerLazySingleton<AkAcceptFareChangeRepository>(() => AkAcceptFareChangeRepositoryImpl(sl<AkAcceptFareChangeApiService>()));
  sl.registerLazySingleton<AkTravelCheckListRepository>(() => AkTravelCheckListRepositoryImpl(sl<AkTravelCheckListApiService>()));
  sl.registerLazySingleton<AkCreateItineraryRepository>(() => AkCreateItineraryRepositoryImpl(sl<AkCreateItineraryApiService>()));
  sl.registerLazySingleton<AkStartPayRepository>(() => AkStartPayRepositoryImpl(sl<AkStartPayApiService>()));
  sl.registerLazySingleton<AkRetrieveBookingRepository>(() => AkRetrieveBookingRepositoryImpl(sl<AkRetrieveBookingApiService>()));
  sl.registerLazySingleton<AkSsrRepository>(() => AkSsrRepositoryImpl(sl<AkSsrApiService>()));
  sl.registerLazySingleton<AkSelectSsrRepository>(() => AkSelectSsrRepositoryImpl(sl<AkSelectSsrApiService>()));
  sl.registerLazySingleton<AkSeatLayoutRepository>(() => AkSeatLayoutRepositoryImpl(sl<AkSeatLayoutApiService>()));
  sl.registerLazySingleton<AkSelectSeatsRepository>(() => AkSelectSeatsRepositoryImpl(sl<AkSelectSeatsApiService>()));
  sl.registerLazySingleton<AkHotelAutosuggestRepository>(() => AkHotelAutosuggestRepositoryImpl(sl<AkHotelAutosuggestApiService>()));
  sl.registerLazySingleton<AkHotelSearchInitRepository>(() => AkHotelSearchInitRepositoryImpl(sl<AkHotelSearchInitApiService>()));
  sl.registerLazySingleton<AkHotelResultContentRepository>(() => AkHotelResultContentRepositoryImpl(sl<AkHotelResultContentApiService>()));
  sl.registerLazySingleton<AkHotelResultRateRepository>(() => AkHotelResultRateRepositoryImpl(sl<AkHotelResultRateApiService>()));
  sl.registerLazySingleton<AkHotelFilterDataRepository>(() => AkHotelFilterDataRepositoryImpl(sl<AkHotelFilterDataApiService>()));
  sl.registerLazySingleton<AkHotelRoomsRepository>(() => AkHotelRoomsRepositoryImpl(sl<AkHotelRoomsApiService>()));
  sl.registerLazySingleton<AkHotelDetailContentRepository>(() => AkHotelDetailContentRepositoryImpl(sl<AkHotelDetailContentApiService>()));
  sl.registerLazySingleton<AkHotelPriceRepository>(() => AkHotelPriceRepositoryImpl(sl<AkHotelPriceApiService>()));
  sl.registerLazySingleton<AkHotelCreateItineraryRepository>(() => AkHotelCreateItineraryRepositoryImpl(sl<AkHotelCreateItineraryApiService>()));
  sl.registerLazySingleton<AkHotelStartPayRepository>(() => AkHotelStartPayRepositoryImpl(sl<AkHotelStartPayApiService>()));
  sl.registerLazySingleton<AkHotelRetrieveBookingRepository>(() => AkHotelRetrieveBookingRepositoryImpl(sl<AkHotelRetrieveBookingApiService>()));
  sl.registerLazySingleton<AkInsuranceRepository>(() => AkInsuranceRepositoryImpl(sl<AkInsuranceApiService>()));







  // Domain Layer - UseCases
  sl.registerLazySingleton<GetAirportsUsecase>(() => GetAirportsUsecase(sl()));
  sl.registerLazySingleton<GoogleLoginUseCase>(() => GoogleLoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<AppleLoginUseCase>(() => AppleLoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<SearchFlightsUseCase>(() => SearchFlightsUseCase(sl<FlightRepository>()));
  sl.registerLazySingleton<GetFareRulesUsecase>(() => GetFareRulesUsecase(sl<FareRuleRepository>()));
  sl.registerLazySingleton<FareQuoteUsecase>(() => FareQuoteUsecase(sl<FareQuoteRepository>()));
  sl.registerLazySingleton<GetSsrUsecase>(() => GetSsrUsecase(sl<SsrRepository>()));
  sl.registerLazySingleton<BookFlightUsecase>(() => BookFlightUsecase(sl<BookingRepository>()));
  sl.registerLazySingleton<IssueTicketUsecase>(() => IssueTicketUsecase(sl<TicketRepository>()));
  sl.registerLazySingleton<GetCountriesUseCase>(() => GetCountriesUseCase(sl()));
  sl.registerLazySingleton<SearchDestinationsUseCase>(() => SearchDestinationsUseCase(sl()),);
  sl.registerLazySingleton<GetHotelsByCityUseCase>(() => GetHotelsByCityUseCase(sl()));
  sl.registerLazySingleton<GetHotelDetailsUsecase>(() => GetHotelDetailsUsecase(sl()));
  sl.registerLazySingleton<GetHotelBookingDetailsUseCase>(() => GetHotelBookingDetailsUseCase(sl<HotelBookingRepository>()),);
  sl.registerLazySingleton<GetExclusiveDealsUseCase>(() => GetExclusiveDealsUseCase(sl()));
  sl.registerLazySingleton<GetT_locationsUseCase>(() => GetT_locationsUseCase(sl<T_locationRepository>()));
  sl.registerLazySingleton<TransportSearchUsecase>(() => TransportSearchUsecase(sl()));
  sl.registerLazySingleton<TpollSearchUseCase>(() => TpollSearchUseCase(sl<TpollSearchRepository>()));
  sl.registerLazySingleton<GetTransportResultUseCase>(() => GetTransportResultUseCase(sl<TransportResultRepository>()));
  sl.registerLazySingleton(() => CreateTransportReservationUseCase(sl<TransportReservationRepository>()));
  sl.registerLazySingleton<GetPopularDestinationsUseCase>(() => GetPopularDestinationsUseCase(sl()));
  sl.registerLazySingleton<GetTrendingRoutesUseCase>(() => GetTrendingRoutesUseCase(sl()));
  sl.registerLazySingleton<GetTravelStoriesUseCase>(() => GetTravelStoriesUseCase(sl<TravelStoriesRepository>()));
  sl.registerLazySingleton<GetTravelStoryBySlugUseCase>(() => GetTravelStoryBySlugUseCase(sl<TravelStoriesRepository>()));
  sl.registerLazySingleton<GetVisaPopularDestinationsUsecase>(() => GetVisaPopularDestinationsUsecase(sl<VisaPopularDestinationRepository>()));
  sl.registerLazySingleton<GetFooterSettingsUseCase>(() => GetFooterSettingsUseCase(sl<FooterSettingsRepository>()));
  sl.registerLazySingleton<GetVisaDestinationsUseCase>(() => GetVisaDestinationsUseCase(sl<VisaDestinationRepository>()));
  sl.registerLazySingleton<GetGeneralSettingsUsecase>(() => GetGeneralSettingsUsecase(sl<GeneralSettingsRepository>()));
  sl.registerLazySingleton<GetPromoCodesUsecase>(() => GetPromoCodesUsecase(sl<GeneralSettingsRepository>()));
  sl.registerLazySingleton<GetFaqListUsecase>(() => GetFaqListUsecase(sl<GeneralSettingsRepository>()));
  sl.registerLazySingleton<GetSectionHeroesUsecase>(() => GetSectionHeroesUsecase(sl<GeneralSettingsRepository>()));
  sl.registerLazySingleton<GetDestinationsUseCase>(() => GetDestinationsUseCase(sl<HolidayRepository>()));
  sl.registerLazySingleton<GetExchangeRatesUseCase>(() => GetExchangeRatesUseCase(sl<ExchangeRateRepository>()));
  sl.registerLazySingleton<ConvertCurrencyUseCase>(() => ConvertCurrencyUseCase(sl<ExchangeRateRepository>()));
  sl.registerLazySingleton<SendOtpUseCase>(() => SendOtpUseCase(sl<SendOtpRepository>()));
  sl.registerLazySingleton<VerifyOtpUseCase>(() => VerifyOtpUseCase(sl<VerifyOtpRepository>()));
  sl.registerLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(sl<ResetPasswordRepository>()));
  sl.registerLazySingleton<SignupUseCase>(() => SignupUseCase(sl<SignupRepository>()));
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl<LoginRepository>()));
  sl.registerLazySingleton<GetWalletBalanceUseCase>(() => GetWalletBalanceUseCase(sl<WalletRepository>()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl<LogoutRepository>()));
  sl.registerLazySingleton<DeleteAccountUseCase>(() => DeleteAccountUseCase(sl<DeleteAccountRepository>()));
  sl.registerLazySingleton<GetProfileUseCase>(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton<UpdateProfileUseCase>(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton<PatchProfileUseCase>(() => PatchProfileUseCase(sl()));
  sl.registerLazySingleton<GetBookingsUseCase>(() => GetBookingsUseCase(sl<MyBookingRepository>()));
  sl.registerLazySingleton<GetUpcomingTripsUseCase>(() => GetUpcomingTripsUseCase(sl<UpcomingTripRepository>()));
  sl.registerLazySingleton<GetReferralUseCase>(() => GetReferralUseCase(sl()));
  sl.registerLazySingleton<GetUserLoyaltyUseCase>(() => GetUserLoyaltyUseCase(sl()));
  sl.registerLazySingleton<GetTransactionsUseCase>(() => GetTransactionsUseCase(sl<TransactionRepository>()));
  sl.registerLazySingleton<GetHotelBookingsUseCase>(() => GetHotelBookingsUseCase(sl<HotelListRepository>()));
  sl.registerLazySingleton<GetReservationPollUseCase>(() => GetReservationPollUseCase(sl<ReservationPollRepository>()),);
  sl.registerLazySingleton<GetVisaApplicationsUseCase>(() => GetVisaApplicationsUseCase(sl<VisaApplicationRepository>()));
  sl.registerLazySingleton<GetVisaApplicationByIdUseCase>(() => GetVisaApplicationByIdUseCase(sl<VisaApplicationRepository>()));
  sl.registerLazySingleton<CreateVisaApplicationUseCase>(() => CreateVisaApplicationUseCase(sl<VisaApplicationRepository>()));
  // sl.registerLazySingleton<UploadVisaDocumentsUseCase>(() => UploadVisaDocumentsUseCase(sl<VisaApplicationRepository>()));
  sl.registerLazySingleton(() => GetVApplicationsUseCase(sl<VRepository>()));
  sl.registerLazySingleton(() => GetBookUseCase(sl<FlightBookRepository>()));
  sl.registerLazySingleton(() => GetDocumentVisaUseCase(sl()));
  sl.registerLazySingleton(() => SubmitDocumentPaymentUseCase(sl()));
  sl.registerLazySingleton(() => UploadDocumentsUseCase(sl()));
  sl.registerLazySingleton<AkFlightSearchUseCase>(() => AkFlightSearchUseCase(sl<AkFlightSearchRepository>()));
  sl.registerLazySingleton<GetAkflightsUseCase>(() => GetAkflightsUseCase(sl()));
  sl.registerLazySingleton<AkFlightInfoUseCase>(() => AkFlightInfoUseCase(sl<AkFlightInfoRepository>()));
  sl.registerLazySingleton<AkGetSPricerUseCase>(() => AkGetSPricerUseCase(sl<AkGetSPricerRepository>()));
  sl.registerLazySingleton<AkSmartPricerUseCase>(() => AkSmartPricerUseCase(sl<AkSmartPricerRepository>()));
  sl.registerLazySingleton<AkFareRuleUseCase>(() => AkFareRuleUseCase(sl<AkFareRuleRepository>()));
  sl.registerLazySingleton<AkAcceptFareChangeUseCase>(() => AkAcceptFareChangeUseCase(sl<AkAcceptFareChangeRepository>()));
  sl.registerLazySingleton<AkTravelCheckListUseCase>(() => AkTravelCheckListUseCase(sl<AkTravelCheckListRepository>()));
  sl.registerLazySingleton<AkCreateItineraryUseCase>(() => AkCreateItineraryUseCase(sl<AkCreateItineraryRepository>()));
  sl.registerLazySingleton<AkStartPayUseCase>(() => AkStartPayUseCase(sl<AkStartPayRepository>()));
  sl.registerLazySingleton<AkRetrieveBookingUseCase>(() => AkRetrieveBookingUseCase(sl<AkRetrieveBookingRepository>()));
  sl.registerLazySingleton<AkSsrUseCase>(() => AkSsrUseCase(sl<AkSsrRepository>()));
  sl.registerLazySingleton<AkSelectSsrUseCase>(() => AkSelectSsrUseCase(sl<AkSelectSsrRepository>()));
  sl.registerLazySingleton<AkSeatLayoutUseCase>(() => AkSeatLayoutUseCase(sl<AkSeatLayoutRepository>()));
  sl.registerLazySingleton<AkSelectSeatsUseCase>(() => AkSelectSeatsUseCase(sl<AkSelectSeatsRepository>()));
  sl.registerLazySingleton<AkHotelAutosuggestUseCase>(() => AkHotelAutosuggestUseCase(sl<AkHotelAutosuggestRepository>()));
  sl.registerLazySingleton<AkHotelSearchInitUseCase>(() => AkHotelSearchInitUseCase(sl<AkHotelSearchInitRepository>()));
  sl.registerLazySingleton<AkHotelResultContentUseCase>(() => AkHotelResultContentUseCase(sl<AkHotelResultContentRepository>()));
  sl.registerLazySingleton<AkHotelResultRateUseCase>(() => AkHotelResultRateUseCase(sl<AkHotelResultRateRepository>()));
  sl.registerLazySingleton<AkHotelFilterDataUseCase>(() => AkHotelFilterDataUseCase(sl<AkHotelFilterDataRepository>()));
  sl.registerLazySingleton<AkHotelRoomsUseCase>(() => AkHotelRoomsUseCase(sl<AkHotelRoomsRepository>()));
  sl.registerLazySingleton<AkHotelDetailContentUseCase>(() => AkHotelDetailContentUseCase(sl<AkHotelDetailContentRepository>()));
  sl.registerLazySingleton<AkHotelPriceUseCase>(() => AkHotelPriceUseCase(sl<AkHotelPriceRepository>()));
  sl.registerLazySingleton<AkHotelCreateItineraryUseCase>(() => AkHotelCreateItineraryUseCase(sl<AkHotelCreateItineraryRepository>()));
  sl.registerLazySingleton<AkHotelStartPayUseCase>(() => AkHotelStartPayUseCase(sl<AkHotelStartPayRepository>()));
  sl.registerLazySingleton<AkHotelRetrieveBookingUseCase>(() => AkHotelRetrieveBookingUseCase(sl<AkHotelRetrieveBookingRepository>()));
  sl.registerLazySingleton<AkInsuranceSignatureUseCase>(() => AkInsuranceSignatureUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<AkInsuranceProviderChecklistUseCase>(() => AkInsuranceProviderChecklistUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<AkInsuranceQuotesUseCase>(() => AkInsuranceQuotesUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<AkInsurancePlanDetailsUseCase>(() => AkInsurancePlanDetailsUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<AkInsuranceValidateKycUseCase>(() => AkInsuranceValidateKycUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<AkInsuranceStartPayUseCase>(() => AkInsuranceStartPayUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<AkInsuranceGetItineraryUseCase>(() => AkInsuranceGetItineraryUseCase(sl<AkInsuranceRepository>()));
  sl.registerLazySingleton<ResolveTripDestinationUseCase>(() => ResolveTripDestinationUseCase(
    getAirportsUsecase: sl<GetAirportsUsecase>(),
  ));






  // Presentation Layer - Bloc
  sl.registerFactory<AirportBloc>(() => AirportBloc(sl()));
  sl.registerFactory<AuthBloc>(() => AuthBloc(googleLoginUseCase: sl(), appleLoginUseCase: sl(), preferencesManager: sl()));
  sl.registerFactory<FlightSearchBloc>(() => FlightSearchBloc(sl<SearchFlightsUseCase>()));
  sl.registerFactory<FareRuleBloc>(() => FareRuleBloc(getFareRulesUsecase: sl<GetFareRulesUsecase>()));
  sl.registerFactory<FareQuoteBloc>(() => FareQuoteBloc(fareQuoteUsecase: sl<FareQuoteUsecase>()));
  sl.registerFactory<SsrBloc>(() => SsrBloc(getSsrUsecase: sl<GetSsrUsecase>()));
  sl.registerFactory<BookingBloc>(() => BookingBloc(bookFlightUsecase: sl<BookFlightUsecase>()));
  sl.registerFactory<TicketBloc>(() => TicketBloc(issueTicketUsecase: sl<IssueTicketUsecase>()));
  sl.registerFactory<CountryBloc>(() => CountryBloc(sl()));
  sl.registerFactory<DestinationBloc>(() => DestinationBloc(searchDestinationsUseCase: sl()));
  sl.registerFactory<HotelBloc>(() => HotelBloc(getHotelsByCityUseCase: sl()));
  sl.registerFactory<HotelDetailsBloc>(() => HotelDetailsBloc(getHotelDetailsUsecase: sl()));
  sl.registerFactory<HotelBookingBloc>(() => HotelBookingBloc(
      getHotelBookingDetailsUseCase: sl<GetHotelBookingDetailsUseCase>()));
  sl.registerFactory<ExclusiveDealsBloc>(() => ExclusiveDealsBloc(getExclusiveDealsUseCase: sl()));
  sl.registerFactory<T_locationBloc>(() => T_locationBloc(getT_locationsUseCase: sl()));
  sl.registerFactory<TransportSearchBloc>(() => TransportSearchBloc(transportSearchUsecase: sl()));
  sl.registerFactory<TpollSearchBloc>(() => TpollSearchBloc(tpollSearchUseCase: sl<TpollSearchUseCase>()));
  sl.registerFactory<TransportResultBloc>(() => TransportResultBloc(getTransportResultUseCase: sl()));
  sl.registerFactory<TransportReservationBloc>(() => TransportReservationBloc(createTransportReservationUseCase: sl<CreateTransportReservationUseCase>()));
  sl.registerFactory<PopularDestinationBloc>(() => PopularDestinationBloc(getPopularDestinationsUseCase: sl(),),);
  sl.registerFactory<TrendingRoutesBloc>(() => TrendingRoutesBloc(getTrendingRoutesUseCase: sl()));
  sl.registerFactory<TravelStoriesBloc>(() => TravelStoriesBloc(
      getTravelStoriesUseCase: sl<GetTravelStoriesUseCase>(),
      getTravelStoryBySlugUseCase: sl<GetTravelStoryBySlugUseCase>()));
  sl.registerFactory<VisaPopularDestinationBloc>(() => VisaPopularDestinationBloc(getVisaPopularDestinationsUsecase: sl<GetVisaPopularDestinationsUsecase>()));
  sl.registerFactory<FooterSettingsBloc>(() => FooterSettingsBloc(sl<GetFooterSettingsUseCase>()));
  sl.registerFactory<VisaDestinationBloc>(() => VisaDestinationBloc(getVisaDestinationsUseCase: sl<GetVisaDestinationsUseCase>()));
  sl.registerFactory<GeneralSettingsBloc>(() => GeneralSettingsBloc(getGeneralSettingsUsecase: sl<GetGeneralSettingsUsecase>(),
      getSectionHeroesUsecase: sl<GetSectionHeroesUsecase>(),
      getFaqListUsecase: sl<GetFaqListUsecase>(),
      getPromoCodesUsecase: sl<GetPromoCodesUsecase>(),
  ));
  sl.registerFactory<HolidayBloc>(() => HolidayBloc(getPopularDestinationsUseCase: sl<GetDestinationsUseCase>()));
  sl.registerFactory<ExchangeRateBloc>(() => ExchangeRateBloc(
      getExchangeRatesUseCase: sl<GetExchangeRatesUseCase>(), convertCurrencyUseCase: sl<ConvertCurrencyUseCase>()));
  sl.registerFactory<SendOtpBloc>(() => SendOtpBloc(sendOtpUseCase: sl()));
  sl.registerFactory<VerifyOtpBloc>(() => VerifyOtpBloc(verifyOtpUseCase: sl()));
  sl.registerFactory<ResetPasswordBloc>(() => ResetPasswordBloc(resetPasswordUseCase: sl()));
  sl.registerFactory<SignupBloc>(() => SignupBloc(signupUseCase: sl<SignupUseCase>()));
  sl.registerFactory<LoginBloc>(() => LoginBloc(loginUseCase: sl()),);
  sl.registerFactory<WalletBloc>(() => WalletBloc(getWalletBalanceUseCase: sl()));
  sl.registerFactory<LogoutBloc>(() => LogoutBloc(logoutUseCase: sl<LogoutUseCase>()));
  sl.registerFactory<DeleteAccountBloc>(() => DeleteAccountBloc(deleteAccountUseCase: sl<DeleteAccountUseCase>()));
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(
      getProfileUseCase: sl<GetProfileUseCase>(),
      updateProfileUseCase: sl<UpdateProfileUseCase>(),
      patchProfileUseCase: sl<PatchProfileUseCase>()));
  sl.registerFactory(() => MyBookingBloc(sl<GetBookingsUseCase>()));
  sl.registerFactory<UpcomingTripBloc>(() => UpcomingTripBloc(getUpcomingTripsUseCase: sl<GetUpcomingTripsUseCase>()));
  sl.registerFactory<ReferralBloc>(() => ReferralBloc(sl()));
  sl.registerFactory<LoyaltyBloc>(() => LoyaltyBloc(sl()));
  sl.registerFactory<TransactionBloc>(() => TransactionBloc(getTransactionsUseCase: sl()));
  sl.registerFactory<HotelBookingListBloc>(() => HotelBookingListBloc(sl()));
  sl.registerFactory<ReservationPollBloc>(() => ReservationPollBloc(sl()),);
  sl.registerFactory<VisaApplicationBloc>(() => VisaApplicationBloc(
      getVisaApplicationsUseCase: sl<GetVisaApplicationsUseCase>(),
      getVisaApplicationByIdUseCase: sl<GetVisaApplicationByIdUseCase>(),
      createVisaApplicationUseCase: sl<CreateVisaApplicationUseCase>(),
    ),
  );
  sl.registerFactory(() => VApplicationBloc(getVApplicationsUseCase: sl()));
  sl.registerFactory(() => FlightBookBloc(sl<GetBookUseCase>()));
  sl.registerFactory(() => DocumentBloc(
    getDocumentVisaUseCase: sl(),
    submitDocumentPaymentUseCase: sl(),
    uploadDocumentsUseCase: sl()
  ));
  sl.registerFactory<AkFlightSearchBloc>(() => AkFlightSearchBloc(sl<AkFlightSearchUseCase>()));
  sl.registerFactory<AkflightsBloc>(() => AkflightsBloc(getAkflightsUseCase: sl()));
  sl.registerFactory<AkFlightInfoBloc>(() => AkFlightInfoBloc(sl<AkFlightInfoUseCase>()));
  sl.registerFactory<AkGetSPricerBloc>(() => AkGetSPricerBloc(sl<AkGetSPricerUseCase>()));
  sl.registerFactory<AkSmartPricerBloc>(() => AkSmartPricerBloc(sl<AkSmartPricerUseCase>()));
  sl.registerFactory<AkFareRuleBloc>(() => AkFareRuleBloc(sl<AkFareRuleUseCase>()));
  sl.registerFactory<AkTravelCheckListBloc>(() => AkTravelCheckListBloc(sl<AkTravelCheckListUseCase>()));
  sl.registerFactory<AkCreateItineraryBloc>(() => AkCreateItineraryBloc(sl<AkCreateItineraryUseCase>()));
  sl.registerFactory<AkStartPayBloc>(() => AkStartPayBloc(sl<AkStartPayUseCase>()));
  sl.registerFactory<AkRetrieveBookingBloc>(() => AkRetrieveBookingBloc(sl<AkRetrieveBookingUseCase>()));
  sl.registerFactory<AkSsrBloc>(() => AkSsrBloc(sl<AkSsrUseCase>()));
  sl.registerFactory<AkSeatLayoutBloc>(() => AkSeatLayoutBloc(sl<AkSeatLayoutUseCase>()));
  sl.registerFactory<AkHotelAutosuggestBloc>(() => AkHotelAutosuggestBloc(sl<AkHotelAutosuggestUseCase>()));
  sl.registerFactory<AkInsuranceBloc>(() => AkInsuranceBloc(
    signatureUseCase: sl<AkInsuranceSignatureUseCase>(),
    providerChecklistUseCase: sl<AkInsuranceProviderChecklistUseCase>(),
    quotesUseCase: sl<AkInsuranceQuotesUseCase>(),
    planDetailsUseCase: sl<AkInsurancePlanDetailsUseCase>(),
    validateKycUseCase: sl<AkInsuranceValidateKycUseCase>(),
  ));



}