class Urls {
  static const String baseUrl = 'http://192.168.1.23:8000/api/';
  static const String basesUrl = 'http://192.168.1.23:8000/api';

  static const String airports = '$basesUrl/flights/airports';

  // static const String airports = 'flights/airports';

  // Flight Search endpoints
  static const String flightSearch = '$basesUrl/tbo/Search/';

  // FareRule endpoint
  static const String fareRule = '$basesUrl/tbo/FareRule/';

  // FareQuote endpoint
  static const String fareQuote = '$basesUrl/tbo/FareQuote/';

  static const String googleAuth = '/auth/google/';

  // SSR Endpoint
  static const String ssr = '$basesUrl/tbo/SSR/';
}
