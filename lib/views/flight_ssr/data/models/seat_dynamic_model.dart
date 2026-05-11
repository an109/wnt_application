class SeatDynamicModel {
  final List<SegmentSeat>? segmentSeat;

  SeatDynamicModel({this.segmentSeat});

  factory SeatDynamicModel.fromJson(Map<String, dynamic> json) {
    return SeatDynamicModel(
      segmentSeat: (json['SegmentSeat'] as List?)?.map((item) =>
          SegmentSeat.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SegmentSeat': segmentSeat?.map((item) => item.toJson()).toList(),
    };
  }
}

class SegmentSeat {
  final List<RowSeats>? rowSeats;

  SegmentSeat({this.rowSeats});

  factory SegmentSeat.fromJson(Map<String, dynamic> json) {
    return SegmentSeat(
      rowSeats: (json['RowSeats'] as List?)?.map((item) =>
          RowSeats.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RowSeats': rowSeats?.map((item) => item.toJson()).toList(),
    };
  }
}

class RowSeats {
  final List<SeatGroup>? seats;

  RowSeats({this.seats});

  factory RowSeats.fromJson(Map<String, dynamic> json) {
    return RowSeats(
      seats: (json['Seats'] as List?)?.map((item) =>
          SeatGroup.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Seats': seats?.map((item) => item.toJson()).toList(),
    };
  }
}

class SeatGroup {
  final List<SeatModel>? seats;

  SeatGroup({this.seats});

  factory SeatGroup.fromJson(Map<String, dynamic> json) {
    return SeatGroup(
      seats: (json['Seats'] as List?)?.map((item) =>
          SeatModel.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Seats': seats?.map((item) => item.toJson()).toList(),
    };
  }
}

class SeatModel {
  final String? airlineCode;
  final String? flightNumber;
  final String? craftType;
  final String? origin;
  final String? destination;
  final int? availablityType;
  final int? description;
  final String? code;
  final String? rowNo;
  final String? seatNo;
  final int? seatType;
  final int? seatWayType;
  final int? compartment;
  final int? deck;
  final String? currency;
  final double? price;

  SeatModel({
    this.airlineCode,
    this.flightNumber,
    this.craftType,
    this.origin,
    this.destination,
    this.availablityType,
    this.description,
    this.code,
    this.rowNo,
    this.seatNo,
    this.seatType,
    this.seatWayType,
    this.compartment,
    this.deck,
    this.currency,
    this.price,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      airlineCode: json['AirlineCode'] as String?,
      flightNumber: json['FlightNumber'] as String?,
      craftType: json['CraftType'] as String?,
      origin: json['Origin'] as String?,
      destination: json['Destination'] as String?,
      availablityType: json['AvailablityType'] as int?,
      description: json['Description'] as int?,
      code: json['Code'] as String?,
      rowNo: json['RowNo'] as String?,
      seatNo: json['SeatNo'] as String?,
      seatType: json['SeatType'] as int?,
      seatWayType: json['SeatWayType'] as int?,
      compartment: json['Compartment'] as int?,
      deck: json['Deck'] as int?,
      currency: json['Currency'] as String?,
      price: (json['Price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AirlineCode': airlineCode,
      'FlightNumber': flightNumber,
      'CraftType': craftType,
      'Origin': origin,
      'Destination': destination,
      'AvailablityType': availablityType,
      'Description': description,
      'Code': code,
      'RowNo': rowNo,
      'SeatNo': seatNo,
      'SeatType': seatType,
      'SeatWayType': seatWayType,
      'Compartment': compartment,
      'Deck': deck,
      'Currency': currency,
      'Price': price,
    };
  }
}