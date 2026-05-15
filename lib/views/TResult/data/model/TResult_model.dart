
import '../../domain/entity/TResult_entity.dart';

class TransportResultModel extends TransportResultEntity {
  const TransportResultModel({
    required super.success,
    required super.search,
    required super.results,
    super.local,
    super.currencyInfo,
    super.startLocation,
    super.endLocation,
  });

  factory TransportResultModel.fromJson(Map<String, dynamic> json) {
    return TransportResultModel(
      success: json['success'] ?? false,
      search: SearchModel.fromJson(json['search'] ?? {}),
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => TransportResultItemModel.fromJson(e))
          .toList() ??
          [],
      local: json['local'] != null
          ? LocalSearchModel.fromJson(json['local'])
          : null,
      currencyInfo: json['currency_info'] != null
          ? CurrencyInfoModel.fromJson(json['currency_info'])
          : null,
      startLocation: json['start_location'] != null
          ? LocationModel.fromJson(json['start_location'])
          : null,
      endLocation: json['end_location'] != null
          ? LocationModel.fromJson(json['end_location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'search': (search as SearchModel).toJson(),
      'results': results.map((e) => (e as TransportResultItemModel).toJson()).toList(),
      if (local != null) 'local': (local as LocalSearchModel).toJson(),
      if (currencyInfo != null)
        'currency_info': (currencyInfo as CurrencyInfoModel).toJson(),
      if (startLocation != null)
        'start_location': (startLocation as LocationModel).toJson(),
      if (endLocation != null)
        'end_location': (endLocation as LocationModel).toJson(),
    };
  }
}

class SearchModel extends SearchEntity {
  const SearchModel({
    required super.numPassengers,
    required super.pickupDatetime,
    super.flightDatetime,
    required super.includePlatformFee,
    required super.includeTargetPricing,
    super.goCorpId,
    required super.searchId,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) {
    return SearchModel(
      numPassengers: json['num_passengers'] ?? 1,
      pickupDatetime: json['pickup_datetime'] ?? '',
      flightDatetime: json['flight_datetime'],
      includePlatformFee: json['include_platform_fee'] ?? false,
      includeTargetPricing: json['include_target_pricing'] ?? false,
      goCorpId: json['go_corp_id'],
      searchId: json['search_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'num_passengers': numPassengers,
      'pickup_datetime': pickupDatetime,
      'flight_datetime': flightDatetime,
      'include_platform_fee': includePlatformFee,
      'include_target_pricing': includeTargetPricing,
      'go_corp_id': goCorpId,
      'search_id': searchId,
    };
  }
}

class TransportResultItemModel extends TransportResultItemEntity {
  const TransportResultItemModel({
    required super.resultId,
    required super.vehicleId,
    required super.totalPrice,
    required super.tags,
    required super.steps,
    required super.bookable,
    super.providerName,
    super.vehicleName,
    super.vehicleType,
  });

  factory TransportResultItemModel.fromJson(Map<String, dynamic> json) {
    return TransportResultItemModel(
      resultId: json['result_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      totalPrice: TotalPriceModel.fromJson(json['total_price'] ?? {}),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => StepModel.fromJson(e))
          .toList() ??
          [],
      bookable: json['bookable'] ?? false,
      providerName: json['provider_name'],
      vehicleName: json['vehicle_name'],
      vehicleType: json['vehicle_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result_id': resultId,
      'vehicle_id': vehicleId,
      'total_price': (totalPrice as TotalPriceModel).toJson(),
      'tags': tags,
      'steps': steps.map((e) => (e as StepModel).toJson()).toList(),
      'bookable': bookable,
      'provider_name': providerName,
      'vehicle_name': vehicleName,
      'vehicle_type': vehicleType,
    };
  }
}

class TotalPriceModel extends TotalPriceEntity {
  const TotalPriceModel({
    required super.totalPrice,
    super.totalPriceWithoutPlatformFee,
    super.platformFee,
    super.totalPriceWithoutPartnerFee,
    super.partnerFee,
    super.slashedPrice,
  });

  factory TotalPriceModel.fromJson(Map<String, dynamic> json) {
    return TotalPriceModel(
      totalPrice: PriceDetailsModel.fromJson(json['total_price'] ?? {}),
      totalPriceWithoutPlatformFee: json['total_price_without_platform_fee'],
      platformFee: json['platform_fee'],
      totalPriceWithoutPartnerFee: json['total_price_without_partner_fee'],
      partnerFee: json['partner_fee'],
      slashedPrice: json['slashed_price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_price': (totalPrice as PriceDetailsModel).toJson(),
      'total_price_without_platform_fee': totalPriceWithoutPlatformFee,
      'platform_fee': platformFee,
      'total_price_without_partner_fee': totalPriceWithoutPartnerFee,
      'partner_fee': partnerFee,
      'slashed_price': slashedPrice,
    };
  }
}

class PriceDetailsModel extends PriceDetailsEntity {
  const PriceDetailsModel({
    required super.value,
    required super.display,
    required super.compact,
    required super.currency,
  });

  factory PriceDetailsModel.fromJson(Map<String, dynamic> json) {
    return PriceDetailsModel(
      value: json['value'] ?? '',
      display: json['display'] ?? '',
      compact: json['compact'] ?? '',
      currency: json['currency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'display': display,
      'compact': compact,
      'currency': currency,
    };
  }
}

class StepModel extends StepEntity {
  const StepModel({
    required super.main,
    required super.stepType,
    required super.details,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      main: json['main'] ?? false,
      stepType: json['step_type'] ?? '',
      details: StepDetailsModel.fromJson(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main': main,
      'step_type': stepType,
      'details': (details as StepDetailsModel).toJson(),
    };
  }
}

class StepDetailsModel extends StepDetailsEntity {
  const StepDetailsModel({
    required super.description,
    required super.vehicle,
    required super.maximumPickupTimeBuffer,
    required super.time,
    required super.provider,
    required super.providerName,
    required super.price,
    required super.departureDatetime,
    required super.cancellation,
    required super.waitTime,
    required super.amenities,
    required super.bookable,
    required super.flightInfoRequired,
    required super.extraPaxRequired,
  });

  factory StepDetailsModel.fromJson(Map<String, dynamic> json) {
    return StepDetailsModel(
      description: json['description'] ?? '',
      vehicle: VehicleModel.fromJson(json['vehicle'] ?? {}),
      maximumPickupTimeBuffer: json['maximum_pickup_time_buffer'] ?? 0,
      time: json['time'] ?? 0,
      provider: ProviderModel.fromJson(json['provider'] ?? {}),
      providerName: json['provider_name'] ?? '',
      price: PriceModel.fromJson(json['price'] ?? {}),
      departureDatetime: json['departure_datetime'] ?? '',
      cancellation: CancellationModel.fromJson(json['cancellation'] ?? {}),
      waitTime: WaitTimeModel.fromJson(json['wait_time'] ?? {}),
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => AmenityModel.fromJson(e))
          .toList() ??
          [],
      bookable: json['bookable'] ?? false,
      flightInfoRequired: json['flight_info_required'] ?? false,
      extraPaxRequired: json['extra_pax_required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'vehicle': (vehicle as VehicleModel).toJson(),
      'maximum_pickup_time_buffer': maximumPickupTimeBuffer,
      'time': time,
      'provider': (provider as ProviderModel).toJson(),
      'provider_name': providerName,
      'price': (price as PriceModel).toJson(),
      'departure_datetime': departureDatetime,
      'cancellation': (cancellation as CancellationModel).toJson(),
      'wait_time': (waitTime as WaitTimeModel).toJson(),
      'amenities': amenities.map((e) => (e as AmenityModel).toJson()).toList(),
      'bookable': bookable,
      'flight_info_required': flightInfoRequired,
      'extra_pax_required': extraPaxRequired,
    };
  }
}

class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.image,
    required super.vehicleType,
    required super.maxBags,
    required super.isMaxBagsPerPerson,
    required super.maxPassengers,
    required super.category,
    required super.numVehicles,
    required super.totalBags,
    super.model,
    super.make,
    required super.vehicleClass,
    super.vehicleClassDetail,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      image: json['image'] ?? '',
      vehicleType: VehicleTypeModel.fromJson(json['vehicle_type'] ?? {}),
      maxBags: json['max_bags'] ?? 0,
      isMaxBagsPerPerson: json['is_max_bags_per_person'] ?? false,
      maxPassengers: json['max_passengers'] ?? 0,
      category: VehicleCategoryModel.fromJson(json['category'] ?? {}),
      numVehicles: json['num_vehicles'] ?? 1,
      totalBags: json['total_bags'] ?? 0,
      model: json['model'],
      make: json['make'],
      vehicleClass: json['vehicle_class'] ?? 0,
      vehicleClassDetail: json['vehicle_class_detail'] != null
          ? VehicleClassDetailModel.fromJson(json['vehicle_class_detail'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'vehicle_type': (vehicleType as VehicleTypeModel).toJson(),
      'max_bags': maxBags,
      'is_max_bags_per_person': isMaxBagsPerPerson,
      'max_passengers': maxPassengers,
      'category': (category as VehicleCategoryModel).toJson(),
      'num_vehicles': numVehicles,
      'total_bags': totalBags,
      'model': model,
      'make': make,
      'vehicle_class': vehicleClass,
      if (vehicleClassDetail != null)
        'vehicle_class_detail': (vehicleClassDetail as VehicleClassDetailModel).toJson(),
    };
  }
}

class VehicleTypeModel extends VehicleTypeEntity {
  const VehicleTypeModel({
    required super.key,
    required super.name,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      key: json['key'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
    };
  }
}

class VehicleCategoryModel extends VehicleCategoryEntity {
  const VehicleCategoryModel({
    required super.id,
    required super.name,
  });

  factory VehicleCategoryModel.fromJson(Map<String, dynamic> json) {
    return VehicleCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class VehicleClassDetailModel extends VehicleClassDetailEntity {
  const VehicleClassDetailModel({
    required super.displayName,
    required super.vehicleClassId,
  });

  factory VehicleClassDetailModel.fromJson(Map<String, dynamic> json) {
    return VehicleClassDetailModel(
      displayName: json['display_name'] ?? '',
      vehicleClassId: json['vehicle_class_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'vehicle_class_id': vehicleClassId,
    };
  }
}

class ProviderModel extends ProviderEntity {
  const ProviderModel({
    required super.name,
    required super.displayName,
    required super.logoUrl,
    required super.rating,
    required super.ratingCount,
    required super.ratingWithDecimals,
    required super.supplierScore,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      rating: json['rating'] ?? 0,
      ratingCount: json['rating_count'] ?? 0,
      ratingWithDecimals: json['rating_with_decimals'] ?? '',
      supplierScore: (json['supplier_score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      'logo_url': logoUrl,
      'rating': rating,
      'rating_count': ratingCount,
      'rating_with_decimals': ratingWithDecimals,
      'supplier_score': supplierScore,
    };
  }
}

class PriceModel extends PriceEntity {
  const PriceModel({
    required super.price,
    required super.tollsIncluded,
    required super.gratuityIncluded,
    required super.gratuityAccepted,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      price: PriceDetailsModel.fromJson(json['price'] ?? {}),
      tollsIncluded: json['tolls_included'] ?? false,
      gratuityIncluded: json['gratuity_included'] ?? false,
      gratuityAccepted: json['gratuity_accepted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': (price as PriceDetailsModel).toJson(),
      'tolls_included': tollsIncluded,
      'gratuity_included': gratuityIncluded,
      'gratuity_accepted': gratuityAccepted,
    };
  }
}

class CancellationModel extends CancellationEntity {
  const CancellationModel({
    required super.cancellableOnline,
    required super.cancellableOffline,
    required super.amendable,
    required super.policy,
  });

  factory CancellationModel.fromJson(Map<String, dynamic> json) {
    return CancellationModel(
      cancellableOnline: json['cancellable_online'] ?? false,
      cancellableOffline: json['cancellable_offline'] ?? false,
      amendable: json['amendable'] ?? false,
      policy: (json['policy'] as List<dynamic>?)
          ?.map((e) => CancellationPolicyModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cancellable_online': cancellableOnline,
      'cancellable_offline': cancellableOffline,
      'amendable': amendable,
      'policy': policy.map((e) => (e as CancellationPolicyModel).toJson()).toList(),
    };
  }
}

class CancellationPolicyModel extends CancellationPolicyEntity {
  const CancellationPolicyModel({
    required super.notice,
    required super.refundPercent,
  });

  factory CancellationPolicyModel.fromJson(Map<String, dynamic> json) {
    return CancellationPolicyModel(
      notice: json['notice'] ?? 0,
      refundPercent: json['refund_percent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notice': notice,
      'refund_percent': refundPercent,
    };
  }
}

class WaitTimeModel extends WaitTimeEntity {
  const WaitTimeModel({
    required super.minutesIncluded,
    super.waitingMinutePrice,
  });

  factory WaitTimeModel.fromJson(Map<String, dynamic> json) {
    return WaitTimeModel(
      minutesIncluded: json['minutes_included'] ?? 0,
      waitingMinutePrice: json['waiting_minute_price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minutes_included': minutesIncluded,
      'waiting_minute_price': waitingMinutePrice,
    };
  }
}

class AmenityModel extends AmenityEntity {
  const AmenityModel({
    required super.key,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.pngImageUrl,
    required super.inputType,
    required super.included,
    required super.selected,
    super.price,
    required super.internal,
    super.priceAmount,
    required super.currency,
    required super.chargeable,
    required super.quantity,
    required super.maxQuantity,
    required super.requiresSpecialInstructionForMultiple,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      pngImageUrl: json['png_image_url'] ?? '',
      inputType: json['input_type'] ?? '',
      included: json['included'] ?? false,
      selected: json['selected'] ?? false,
      price: json['price'] != null
          ? PriceDetailsModel.fromJson(json['price'])
          : null,
      internal: json['internal'] ?? false,
      priceAmount: json['price_amount'],
      currency: json['currency'] ?? '',
      chargeable: json['chargeable'] ?? false,
      quantity: json['quantity'] ?? 1,
      maxQuantity: json['max_quantity'] ?? 1,
      requiresSpecialInstructionForMultiple:
      json['requires_special_instruction_for_multiple'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'png_image_url': pngImageUrl,
      'input_type': inputType,
      'included': included,
      'selected': selected,
      if (price != null) 'price': (price as PriceDetailsModel).toJson(),
      'internal': internal,
      'price_amount': priceAmount,
      'currency': currency,
      'chargeable': chargeable,
      'quantity': quantity,
      'max_quantity': maxQuantity,
      'requires_special_instruction_for_multiple':
      requiresSpecialInstructionForMultiple,
    };
  }
}

class LocalSearchModel extends LocalSearchEntity {
  const LocalSearchModel({
    required super.id,
    super.reseller,
    super.user,
    required super.guestReference,
    required super.searchId,
    required super.status,
    required super.startAddress,
    required super.endAddress,
    required super.pickupDatetime,
    super.flightDatetime,
    required super.numPassengers,
    required super.currency,
    required super.moreComing,
    required super.expiresAt,
    required super.selectedResultId,
  });

  factory LocalSearchModel.fromJson(Map<String, dynamic> json) {
    return LocalSearchModel(
      id: json['id'] ?? 0,
      reseller: json['reseller'],
      user: json['user'],
      guestReference: json['guest_reference'] ?? '',
      searchId: json['search_id'] ?? '',
      status: json['status'] ?? '',
      startAddress: json['start_address'] ?? '',
      endAddress: json['end_address'] ?? '',
      pickupDatetime: json['pickup_datetime'] ?? '',
      flightDatetime: json['flight_datetime'],
      numPassengers: json['num_passengers'] ?? 1,
      currency: json['currency'] ?? '',
      moreComing: json['more_coming'] ?? false,
      expiresAt: json['expires_at'] ?? '',
      selectedResultId: json['selected_result_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reseller': reseller,
      'user': user,
      'guest_reference': guestReference,
      'search_id': searchId,
      'status': status,
      'start_address': startAddress,
      'end_address': endAddress,
      'pickup_datetime': pickupDatetime,
      'flight_datetime': flightDatetime,
      'num_passengers': numPassengers,
      'currency': currency,
      'more_coming': moreComing,
      'expires_at': expiresAt,
      'selected_result_id': selectedResultId,
    };
  }
}

class CurrencyInfoModel extends CurrencyInfoEntity {
  const CurrencyInfoModel({
    required super.code,
    required super.prefixSymbol,
    required super.suffixSymbol,
  });

  factory CurrencyInfoModel.fromJson(Map<String, dynamic> json) {
    return CurrencyInfoModel(
      code: json['code'] ?? '',
      prefixSymbol: json['prefix_symbol'] ?? '',
      suffixSymbol: json['suffix_symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'prefix_symbol': prefixSymbol,
      'suffix_symbol': suffixSymbol,
    };
  }
}

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.fullAddress,
    required super.formattedAddress,
    required super.lat,
    required super.lng,
    required super.timezone,
    required super.iataCode,
    required super.icaoCode,
    required super.railIataCode,
    required super.uicCode,
    required super.metrolinxCode,
    required super.placeId,
    required super.type,
    required super.city,
    required super.isCruisePort,
    required super.isTrainStation,
    required super.isTransitStation,
    required super.isIncomplete,
    super.favoriteId,
    super.favoriteSource,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      fullAddress: json['full_address'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      timezone: json['timezone'] ?? '',
      iataCode: json['iata_code'] ?? '',
      icaoCode: json['icao_code'] ?? '',
      railIataCode: json['rail_iata_code'] ?? '',
      uicCode: json['uic_code'] ?? '',
      metrolinxCode: json['metrolinx_code'] ?? '',
      placeId: json['place_id'] ?? '',
      type: json['type'] ?? '',
      city: json['city'] ?? '',
      isCruisePort: json['is_cruise_port'] ?? false,
      isTrainStation: json['is_train_station'] ?? false,
      isTransitStation: json['is_transit_station'] ?? false,
      isIncomplete: json['is_incomplete'] ?? false,
      favoriteId: json['favorite_id'],
      favoriteSource: json['favorite_source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_address': fullAddress,
      'formatted_address': formattedAddress,
      'lat': lat,
      'lng': lng,
      'timezone': timezone,
      'iata_code': iataCode,
      'icao_code': icaoCode,
      'rail_iata_code': railIataCode,
      'uic_code': uicCode,
      'metrolinx_code': metrolinxCode,
      'place_id': placeId,
      'type': type,
      'city': city,
      'is_cruise_port': isCruisePort,
      'is_train_station': isTrainStation,
      'is_transit_station': isTransitStation,
      'is_incomplete': isIncomplete,
      'favorite_id': favoriteId,
      'favorite_source': favoriteSource,
    };
  }
}