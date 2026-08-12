class Urls {
  // static const String baseUrl = 'http://167.71.233.208:8032/api/';
  static const String baseUrl = 'https://thewandernova.com/api/';
  // static const String basesUrl = 'http://167.71.233.208:8032/api';
  static const String basesUrl = 'https://thewandernova.com/api';

  static const String airports = '$basesUrl/flights/airports';
  static const String flightSearch = '$basesUrl/akbar/ExpressSearch/';
  static const String getExpSearch = '$basesUrl/akbar/GetExpSearch/';
  static const String flightInfo = '$basesUrl/akbar/FlightInfo/';
  static const String smartPricer = '$basesUrl/akbar/SmartPricer/';
  static const String getSPricer = '$basesUrl/akbar/GetSPricer/';
  static const String akFareRule = '$basesUrl/akbar/FareRule/';
  static const String acceptFareChange = '$basesUrl/akbar/AcceptFareChange/';
  static const String getTravelCheckList = '$basesUrl/akbar/GetTravelCheckList/';
  static const String createItinerary = '$basesUrl/akbar/CreateItinerary/';
  static const String startPay = '$basesUrl/akbar/StartPay/';
  static const String retrieveBooking = '$basesUrl/akbar/RetrieveBooking/';
  static const String akSsr = '$basesUrl/akbar/SSR/';
  static const String akSelectSsr = '$basesUrl/akbar/SelectSSR/';
  static const String akSeatLayout = '$basesUrl/akbar/SeatLayout/';
  static const String akSelectSeats = '$basesUrl/akbar/SelectSeats/';
  static const String tboflightSearch = '$basesUrl/tbo/Search/';
  static const String fareRule = '$basesUrl/tbo/FareRule/';
  static const String fareQuote = '$basesUrl/tbo/FareQuote/';
  static const String googleAuth = '$basesUrl/auth/google/';
  static const String googleLogin = '$basesUrl/auth/google_login/';
  static const String appleAuth = '$basesUrl/auth/apple/';
  static const String resetPassword = '$basesUrl/auth/reset-password/';
  static const String ssr = '$basesUrl/tbo/SSR/';
  static const String book = '$basesUrl/tbo/Book/';
  static const String ticket = '$basesUrl/tbo/Ticket/';
  static const String getBookingDetails = '$basesUrl/tbo/GetBookingDetails/';
  static const String razorpayCreateOrder =
      '${baseUrl}payments/razorpay/create-order/';
  static const String razorpayVerify = '${baseUrl}payments/razorpay/verify/';

  // ----- CCAvenue (hosted checkout) -----
  static const String ccavenueCreateCheckout =
      '${baseUrl}payments/ccavenue/create-checkout/';
  static String ccavenueStatus(String orderId) =>
      '${baseUrl}payments/ccavenue/status/$orderId/';

  // ----- Server-side ticketing (payment-safe) -----
  static const String prepareTicket = '${basesUrl}/flights/prepare-ticket/';
  static const String finalizeTicket = '${basesUrl}/flights/finalize/';

  static const String ccavenueSuccessUrl =
      'https://wandernova.com/payment/success';
  static const String ccavenueFailureUrl =
      'https://wandernova.com/payment/failed';
  static const String hotelsByCity = '$basesUrl/tbo-hotel/hotels-by-city/';
  static const String hotelDetails = '$basesUrl/tbo-hotel/hotel-details/';
  static const String hotelPrebook = '$basesUrl/tbo-hotel/prebook/';
  static const String hotelBook = '$basesUrl/tbo-hotel/book/';
  static const String hotelBookingDetail =
      '$basesUrl/tbo-hotel/booking-detail/';
  static const String hotelCancel = '$basesUrl/tbo-hotel/cancel/';
  static const String hotelHcnStatus = '$basesUrl/tbo-hotel/hcn-status/';
  static const String hotelBookings = '$basesUrl/tbo-hotel/bookings/';

  static const String hotelDestinationSearch =
      '$basesUrl/tbo-hotel/destination-search/';
  static const String hotelCachedCountries =
      '$basesUrl/tbo-hotel/cached-countries/';

  // ----- Akbar Hotels (new provider, replacing tbo-hotel search above) -----

  static const String akHotelAutosuggest =
      '$basesUrl/akbar-hotels/autosuggest/';
  static const String akHotelSearchInit =
      '$basesUrl/akbar-hotels/search/init/';
  static String akHotelResultContent(String searchId) =>
      '$basesUrl/akbar-hotels/search/result/$searchId/content/';
  static String akHotelResultRate(String searchId) =>
      '$basesUrl/akbar-hotels/search/result/$searchId/rate/';
  static String akHotelFilterData(String searchId) =>
      '$basesUrl/akbar-hotels/search/result/$searchId/filterdata/';
  static String akHotelRooms(String searchId, String hotelId) =>
      '$basesUrl/akbar-hotels/search/result/$searchId/$hotelId/rooms/';
  static String akHotelContent(String searchId, String hotelId) =>
      '$basesUrl/akbar-hotels/hotels/$searchId/$hotelId/content/';
  static String akHotelPrice(
    String searchId,
    String hotelId,
    String priceProvider,
    String recommendationId,
  ) =>
      '$basesUrl/akbar-hotels/search/$searchId/$hotelId/price/$priceProvider/$recommendationId/';
  static const String akHotelCreateItinerary =
      '$basesUrl/akbar-hotels/create-itinerary/';
  static const String akHotelStartPay = '$basesUrl/akbar-hotels/start-pay/';
  static const String akHotelRetrieveBooking =
      '$basesUrl/akbar-hotels/retrieve-booking/';

  /// ----- Akbar Insurance (Trip Secure add-on on the flight booking flow) -----
  // Signature is the only JWT-protected call — it mints the Bearer token the
  // backend uses for every other insurance call. The provider credentials live
  // server-side in .env, so the client never sends them. The remaining three
  // are public (no auth), which is why guests can price a plan too.

  static const String insuranceSignature = '$basesUrl/akbar-insurance/Signature/';
  static const String insuranceProviderChecklist =
      '$basesUrl/akbar-insurance/ProviderChecklist/';
  static const String insuranceQuotesListing =
      '$basesUrl/akbar-insurance/QuotesListing/';
  static const String insurancePlanDetails =
      '$basesUrl/akbar-insurance/PlanDetails/';
  // Step 5/7 — JWT required (WanderNova user token, attached automatically by
  // DioClient). Validates the traveller's ID document before a plan can be
  // paid for.
  static const String insuranceValidateKyc =
      '$basesUrl/akbar-insurance/ValidateKYC/';
  // Step 6/7 — payment-gated: issues a real policy against WanderNova's
  // Akbar/Benzy agent balance. Never live-tested, same reason flight
  // Book/Ticket never is.
  static const String insuranceStartPay = '$basesUrl/akbar-insurance/StartPay/';
  // Step 7/7 — JWT required. Read-only lookup of a booked policy.
  static const String insuranceGetItinerary =
      '$basesUrl/akbar-insurance/GetItinerary/';

  // ------------------------------------------------------------------------------

  static const String exclusiveDeals = '$basesUrl/exclusive-deals/';
  static const String transportSearch = '$basesUrl/transport/search/';
  static String tpollSearch(String searchId) =>
      '$basesUrl/transport/search/$searchId/poll/';
  static String transportSearchResult(String searchId, String resultId) {
    return '$basesUrl/transport/search/$searchId/$resultId/';
  }

  static const String transportReservations =
      '$basesUrl/transport/reservations/';

  static const String popularsDestinations =
      '$basesUrl/flights-popular-destinations/';
  static const String trendingRoutes = '$basesUrl/trending-routes/live/';
  static const String travelStories = '$basesUrl/travel-stories/';
  static const String footerSettings = '${baseUrl}settings/footer/';

  // ----- VISA -----
  static const String visaPopularDestinations =
      '$basesUrl/visa-popular-destinations/';
  static const String visaDestinations =
      '${baseUrl}visa-destination-page-content/';

  // ----- Main API -----
  static const String popularDestinations =
      '$basesUrl/flights-popular-destinations/';

  // ----- Holidays -----
  static const String holidaysPopularDestinations =
      '$basesUrl/holidays-popular-destinations/';
  // Saves a holiday package booking after a successful CCAvenue/wallet payment.
  static const String holidayBookings = '$basesUrl/holidays/bookings/';

  // Exchange Rate API endpoints
  // static const String exchangeRatePrimary = 'https://v6.exchangerate-api.com/v6/5dff9de8575af8e0fcbeb0c5/latest/USD';
  static const String exchangeRatePrimary =
      'https://open.er-api.com/v6/latest/USD';
  static const String exchangeRateFallback =
      'https://open.er-api.com/v6/latest/USD';

  static const String sendOtp = '$basesUrl/auth/send-otp/';
  static const String verifyOtp = '$basesUrl/auth/verify-otp/';
  static const String signup = '$basesUrl/auth/signup/';
  static const String login = '$basesUrl/auth/login/';
  static const String walletBalance = '$basesUrl/wallet/balance/';
  static const String logout = '$basesUrl/auth/logout/';
  static const String tokenRefresh = '$basesUrl/auth/token/refresh/';
  static const String deleteAccount = '$basesUrl/auth/delete-account/';
  static const String userProfile = '$basesUrl/user/profile/';
  static const String updateUserProfile = '$basesUrl/user/profile/';
  // My Bookings ----
  static const String transportBookings = '$basesUrl/transport/bookings/';
  static const String hotelBookingsList = '$basesUrl/tbo-hotel/bookings/list/';
  static const String bookings = '$basesUrl/flights/bookings';

  // Visa Applications / Upcoming Trips
  static const String visaApplications = '$basesUrl/visa-applications/';
  static const String visaApplicationDetail = '$basesUrl/visa-applications/';
  // Marks a visa application as paid after a successful CCAvenue/wallet payment.
  static String visaCompletePayment(dynamic applicationId) =>
      '$basesUrl/visa-applications/$applicationId/complete-payment/';
  // Referral endpoint
  static const String userReferral = '$basesUrl/user/referral/';
  // New Loyalty Endpoint
  static const String userLoyalty = '$basesUrl/user/loyalty/';
  // Wallet Transactions endpoint
  static const String walletTransactions = '$basesUrl/wallet/transactions/';
  // Wallet add-money (creates pending wallet transaction + returns CCAvenue checkout URL)
  static const String walletAddMoney = '$basesUrl/wallet/add-money/';
  // Wallet verify payment (credits the wallet after a successful CCAvenue top-up)
  static const String walletVerifyPayment = '$basesUrl/wallet/verify-payment/';

  static String reservationPoll(String searchId) =>
      '$basesUrl/transport/reservations/$searchId/poll/';
  static const String holidayDestinations =
      '$basesUrl/holidays-popular-destinations';

  // Saved travellers (Profile > Add Traveller)
  static const String travellers = '$basesUrl/travellers/';
  static String travellersByEmail(String email) =>
      '$travellers?user_email=$email';
}
