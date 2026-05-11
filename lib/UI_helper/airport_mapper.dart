// lib/core/utils/mappings.dart

/// Airline code to name mapping
class AirlineMapper {
  static const Map<String, String> codeToName = {
    '6E': 'IndiGo',
    'AI': 'Air India',
    'SG': 'SpiceJet',
    'UK': 'Vistara',
    'I5': 'AirAsia India',
    'G8': 'Go First',
    'EK': 'Emirates',
    'QR': 'Qatar Airways',
    'EY': 'Etihad Airways',
    'BA': 'British Airways',
    'LH': 'Lufthansa',
    'AF': 'Air France',
    'SQ': 'Singapore Airlines',
    'TG': 'Thai Airways',
    'MH': 'Malaysia Airlines',
    // Add more as needed
  };

  static String getName(String? code) {
    if (code == null || code.isEmpty) return 'Unknown';
    return codeToName[code] ?? code;
  }
}

/// Airport code to city name mapping
class AirportMapper {
  static const Map<String, String> codeToCity = {
    'DEL': 'New Delhi',
    'BOM': 'Mumbai',
    'BLR': 'Bangalore',
    'HYD': 'Hyderabad',
    'MAA': 'Chennai',
    'CCU': 'Kolkata',
    'DXB': 'Dubai',
    'AUH': 'Abu Dhabi',
    'DOH': 'Doha',
    'LHR': 'London',
    'JFK': 'New York',
    'SIN': 'Singapore',
    'BKK': 'Bangkok',
    'KUL': 'Kuala Lumpur',
    'SYD': 'Sydney',
    'MEL': 'Melbourne',
    // Add more as needed
  };

  static String getCity(String? code) {
    if (code == null || code.isEmpty) return 'Unknown';
    return codeToCity[code] ?? code;
  }
}