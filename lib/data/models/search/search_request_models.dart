/// Models for Search Request API

/// District model
class DistrictModel {
  final int id;
  final String name;
  final int? cityId;

  DistrictModel({
    required this.id,
    required this.name,
    this.cityId,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] as int,
      name: json['name'] as String,
      cityId: json['cityId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cityId': cityId,
    };
  }
}

/// Service/Condition Dictionary Item
class DictionaryItem {
  final int id;
  final String key;
  final String value;

  DictionaryItem({
    required this.id,
    required this.key,
    required this.value,
  });

  factory DictionaryItem.fromJson(Map<String, dynamic> json) {
    return DictionaryItem(
      id: json['id'] as int,
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }
}

/// Search Request Create/Update Request Model
class SearchRequestCreate {
  final String checkInDate;       // "2025-12-01"
  final String checkOutDate;      // "2025-12-05"
  final bool oneNight;
  final int price;
  final int countOfPeople;
  final int? fromRating;          // nullable
  final int? toRating;            // nullable
  final List<String> unitTypes;   // ["HOTEL_ROOM", "APARTMENT"]
  final List<int> districtIds;    // [1, 2, 3]
  final List<int>? serviceDictionaryIds;    // optional
  final List<int>? conditionDictionaryIds;  // optional

  SearchRequestCreate({
    required this.checkInDate,
    required this.checkOutDate,
    required this.oneNight,
    required this.price,
    required this.countOfPeople,
    this.fromRating,
    this.toRating,
    required this.unitTypes,
    required this.districtIds,
    this.serviceDictionaryIds,
    this.conditionDictionaryIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'oneNight': oneNight,
      'price': price,
      'countOfPeople': countOfPeople,
      if (fromRating != null) 'fromRating': fromRating,
      if (toRating != null) 'toRating': toRating,
      'unitTypes': unitTypes,
      'districtIds': districtIds,
      if (serviceDictionaryIds != null && serviceDictionaryIds!.isNotEmpty)
        'serviceDictionaryIds': serviceDictionaryIds,
      if (conditionDictionaryIds != null && conditionDictionaryIds!.isNotEmpty)
        'conditionDictionaryIds': conditionDictionaryIds,
    };
  }
}

/// Search Request Response Model (full data)
class SearchRequest {
  final int id;
  final int authorId;
  final String authorName;
  final double? fromRating;
  final double? toRating;
  final String checkInDate;
  final String checkOutDate;
  final bool oneNight;
  final int price;
  final int countOfPeople;
  final String status; // "OPEN_TO_PRICE_REQUEST", etc.
  final List<String> unitTypes;
  final List<DistrictModel> districts;
  final List<DictionaryItem> services;
  final List<DictionaryItem> conditions;
  final String createdAt;

  SearchRequest({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.fromRating,
    this.toRating,
    required this.checkInDate,
    required this.checkOutDate,
    required this.oneNight,
    required this.price,
    required this.countOfPeople,
    required this.status,
    required this.unitTypes,
    required this.districts,
    required this.services,
    required this.conditions,
    required this.createdAt,
  });

  factory SearchRequest.fromJson(Map<String, dynamic> json) {
    return SearchRequest(
      id: json['id'] as int,
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String,
      fromRating: json['fromRating'] != null ? (json['fromRating'] as num).toDouble() : null,
      toRating: json['toRating'] != null ? (json['toRating'] as num).toDouble() : null,
      checkInDate: json['checkInDate'] as String,
      checkOutDate: json['checkOutDate'] as String,
      oneNight: json['oneNight'] as bool,
      price: json['price'] as int,
      countOfPeople: json['countOfPeople'] as int,
      status: json['status'] as String,
      unitTypes: (json['unitTypes'] as List<dynamic>).map((e) => e as String).toList(),
      districts: (json['districts'] as List<dynamic>)
          .map((e) => DistrictModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List<dynamic>)
          .map((e) => DictionaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => DictionaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'fromRating': fromRating,
      'toRating': toRating,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'oneNight': oneNight,
      'price': price,
      'countOfPeople': countOfPeople,
      'status': status,
      'unitTypes': unitTypes,
      'districts': districts.map((e) => e.toJson()).toList(),
      'services': services.map((e) => e.toJson()).toList(),
      'conditions': conditions.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  /// Get human-readable status
  String get statusText {
    switch (status) {
      case 'OPEN_TO_PRICE_REQUEST':
        return 'Открыта для предложений';
      case 'CLOSED':
        return 'Закрыта';
      case 'CANCELLED':
        return 'Отменена';
      default:
        return status;
    }
  }

  /// Get unit types as readable text
  String get unitTypesText {
    final types = unitTypes.map((type) {
      switch (type) {
        case 'HOTEL_ROOM':
          return 'Отель';
        case 'APARTMENT':
          return 'Квартира';
        default:
          return type;
      }
    }).toList();
    return types.join(', ');
  }
}

/// Update price request model
class UpdatePriceRequest {
  final int price;

  UpdatePriceRequest({required this.price});

  Map<String, dynamic> toJson() {
    return {'price': price};
  }
}