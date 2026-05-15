class Urls {
  // static const String baseUrl = 'http://192.168.1.23:8000/api/';
  static const String baseUrl = 'https://thewandernova.com/api/';
  // static const String basesUrl = 'http://192.168.1.23:8000/api';
  static const String basesUrl = 'https://thewandernova.com/api';

  static const String airports = '$basesUrl/flights/airports';
  static const String flightSearch = '$basesUrl/tbo/Search/';
  static const String fareRule = '$basesUrl/tbo/FareRule/';
  static const String fareQuote = '$basesUrl/tbo/FareQuote/';
  static const String googleAuth = '/auth/google/';
  static const String ssr = '$basesUrl/tbo/SSR/';
  static const String hotelsByCity = '$basesUrl/tbo-hotel/hotels-by-city/';
  static const String hotelDetails = '$basesUrl/tbo-hotel/hotel-details/';
  static const String hotelPrebook = '$basesUrl/tbo-hotel/prebook/';
  static const String exclusiveDeals = '$basesUrl/exclusive-deals/';
  static const String transportSearch = '$basesUrl/transport/search/';
  static String tpollSearch(String searchId) => '$basesUrl/transport/search/$searchId/poll/';
}
