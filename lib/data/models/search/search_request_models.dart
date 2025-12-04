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
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      cityId: json['cityId'] != null ? (json['cityId'] as num).toInt() : null,
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
      id: (json['id'] as num).toInt(),
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
  final String checkInDate;
  final String checkOutDate;
  final bool oneNight;
  final int price;
  final int countOfPeople;
  final int? fromRating;
  final int? toRating;
  final List<String> unitTypes;
  final List<int> districtIds;
  final List<int>? serviceDictionaryIds;
  final List<int>? conditionDictionaryIds;

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
      'serviceDictionaryIds': serviceDictionaryIds ?? [],
      'conditionDictionaryIds': conditionDictionaryIds ?? [],
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
  final String status;
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

  /// Локальное копирование с изменением отдельных полей
  SearchRequest copyWith({
    int? id,
    int? authorId,
    String? authorName,
    double? fromRating,
    double? toRating,
    String? checkInDate,
    String? checkOutDate,
    bool? oneNight,
    int? price,
    int? countOfPeople,
    String? status,
    List<String>? unitTypes,
    List<DistrictModel>? districts,
    List<DictionaryItem>? services,
    List<DictionaryItem>? conditions,
    String? createdAt,
  }) {
    return SearchRequest(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      fromRating: fromRating ?? this.fromRating,
      toRating: toRating ?? this.toRating,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      oneNight: oneNight ?? this.oneNight,
      price: price ?? this.price,
      countOfPeople: countOfPeople ?? this.countOfPeople,
      status: status ?? this.status,
      unitTypes: unitTypes ?? this.unitTypes,
      districts: districts ?? this.districts,
      services: services ?? this.services,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SearchRequest.fromJson(Map<String, dynamic> json) {
    return SearchRequest(
      id: (json['id'] as num).toInt(),
      authorId: (json['authorId'] as num).toInt(),
      authorName: json['authorName'] as String,
      fromRating: json['fromRating'] != null ? (json['fromRating'] as num).toDouble() : null,
      toRating: json['toRating'] != null ? (json['toRating'] as num).toDouble() : null,
      checkInDate: json['checkInDate'] as String,
      checkOutDate: json['checkOutDate'] as String,
      oneNight: json['oneNight'] as bool,
      price: (json['price'] as num).toInt(),
      countOfPeople: (json['countOfPeople'] as num).toInt(),
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
      'districts': districts.map((d) => d.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  /// ⬅️ СТАТУСЫ ЗАЯВОК НА РУССКОМ
  /// Backend enum: OPEN_TO_PRICE_REQUEST, PRICE_REQUEST_PENDING,
  ///               WAIT_TO_RESERVATION, FINISHED, CANCELLED
  String get statusText {
    switch (status) {
      case 'OPEN_TO_PRICE_REQUEST':
        return 'Открыта для предложений';
      case 'PRICE_REQUEST_PENDING':
        return 'Ожидание предложений';
      case 'WAIT_TO_RESERVATION':
        return 'Ожидание бронирования';
      case 'FINISHED':
        return 'Завершена';
      case 'CANCELLED':
        return 'Отменена';
      default:
        return status;
    }
  }

  /// ⬅️ Цвет статуса
  String get statusColor {
    switch (status) {
      case 'OPEN_TO_PRICE_REQUEST':
        return 'green';
      case 'PRICE_REQUEST_PENDING':
        return 'orange';
      case 'WAIT_TO_RESERVATION':
        return 'blue';
      case 'FINISHED':
        return 'grey';
      case 'CANCELLED':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// ⬅️ Типы размещения на русском
  String get unitTypesText {
    return unitTypes.map((type) {
      switch (type) {
        case 'HOTEL_ROOM':
          return 'Гостиница';
        case 'APARTMENT':
          return 'Квартира';
        case 'HOUSE':
          return 'Дом';
        default:
          return type;
      }
    }).join(', ');
  }
}