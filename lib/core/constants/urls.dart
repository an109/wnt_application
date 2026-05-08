class Urls {
  static const String baseUrl = 'http://192.168.1.23:8000/api/';
  static const String basesUrl = 'http://192.168.1.23:8000/api';

  static const String airports = '$basesUrl/flights/airports';

  // static const String airports = 'flights/airports';

  // Flight Search endpoints
  static const String flightSearch = '$basesUrl/tbo/Search/';

  static const String googleAuth = '/auth/google/';
}
