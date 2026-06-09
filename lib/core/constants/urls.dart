class Urls {
  static const String baseUrl = 'http://192.168.29.79:8001/api/';
  // static const String baseUrl = 'https://thewandernova.com/api/';
  static const String basesUrl = 'http://192.168.29.79:8001/api';
  // static const String basesUrl = 'https://thewandernova.com/api';

  static const String airports = '$basesUrl/flights/airports';
  static const String flightSearch = '$basesUrl/tbo/Search/';
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
  static const String razorpayCreateOrder = '${baseUrl}payments/razorpay/create-order/';
  static const String razorpayVerify = '${baseUrl}payments/razorpay/verify/';

  // ----- CCAvenue (hosted checkout) -----
  static const String ccavenueCreateCheckout = '${baseUrl}payments/ccavenue/create-checkout/';
  static String ccavenueStatus(String orderId) => '${baseUrl}payments/ccavenue/status/$orderId/';

  static const String ccavenueSuccessUrl = 'https://wandernova.com/payment/success';
  static const String ccavenueFailureUrl = 'https://wandernova.com/payment/failed';
  static const String hotelsByCity = '$basesUrl/tbo-hotel/hotels-by-city/';
  static const String hotelDetails = '$basesUrl/tbo-hotel/hotel-details/';
  static const String hotelPrebook = '$basesUrl/tbo-hotel/prebook/';
  static const String hotelBook = '$basesUrl/tbo-hotel/book/';
  static const String hotelBookingDetail = '$basesUrl/tbo-hotel/booking-detail/';
  static const String hotelCancel = '$basesUrl/tbo-hotel/cancel/';
  static const String hotelHcnStatus = '$basesUrl/tbo-hotel/hcn-status/';
  static const String hotelBookings = '$basesUrl/tbo-hotel/bookings/';
  static const String hotelBookingsList = '$basesUrl/tbo-hotel/bookings/list/';
  static const String hotelDestinationSearch = '$basesUrl/tbo-hotel/destination-search/';
  static const String hotelCachedCountries = '$basesUrl/tbo-hotel/cached-countries/';
  static const String exclusiveDeals = '$basesUrl/exclusive-deals/';
  static const String transportSearch = '$basesUrl/transport/search/';
  static String tpollSearch(String searchId) => '$basesUrl/transport/search/$searchId/poll/';
  static String transportSearchResult(String searchId, String resultId) {
    return '$basesUrl/transport/search/$searchId/$resultId/';}
  static const String transportReservations = '$basesUrl/transport/reservations/';

  static const String popularsDestinations = '$basesUrl/flights-popular-destinations/';
  static const String trendingRoutes = '$basesUrl/trending-routes/live/';
  static const String travelStories = '$basesUrl/travel-stories/';
  static const String footerSettings = '${baseUrl}settings/footer/';

  // ----- VISA -----
  static const String visaPopularDestinations = '$basesUrl/visa-popular-destinations/';
  static const String visaDestinations = '${baseUrl}visa-destination-page-content/';

  // ----- Main API -----
  static const String popularDestinations = '$basesUrl/flights-popular-destinations/';

  // ----- Holidays -----
  static const String holidaysPopularDestinations = '$basesUrl/holidays-popular-destinations/';

  // Exchange Rate API endpoints
  // static const String exchangeRatePrimary = 'https://v6.exchangerate-api.com/v6/5dff9de8575af8e0fcbeb0c5/latest/USD';
  static const String exchangeRatePrimary = 'https://open.er-api.com/v6/latest/USD';
  static const String exchangeRateFallback = 'https://open.er-api.com/v6/latest/USD';

  static const String sendOtp = '$basesUrl/auth/send-otp/';
  static const String verifyOtp = '$basesUrl/auth/verify-otp/';
  static const String signup = '$basesUrl/auth/signup/';
  static const String login = '$basesUrl/auth/login/';
  static const String walletBalance = '$basesUrl/wallet/balance/';
  static const String logout = '$basesUrl/auth/logout/';
  static const String userProfile = '$basesUrl/user/profile/';
  static const String updateUserProfile = '$basesUrl/user/profile/';
  static const String transportBookings = '$basesUrl/transport/bookings/';
  // Visa Applications / Upcoming Trips
  static const String visaApplications = '$basesUrl/visa-applications/';

}
