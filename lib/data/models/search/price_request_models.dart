/// Models for Price Request API

/// ⬅️ FIXED: Nullable поля для безопасного парсинга
class PriceRequest {
  final int id;
  final int searchRequestId;
  final int? managerId;  // ⬅️ Nullable
  final String? managerName;  // ⬅️ Nullable
  final int? accommodationId;  // ⬅️ Nullable
  final String? accommodationName;  // ⬅️ Nullable
  final int? accommodationUnitId;  // ⬅️ Nullable
  final String? accommodationUnitName;  // ⬅️ Nullable
  final int price;
  final String clientResponseStatus; // WAITING, ACCEPTED, REJECTED
  final String createdAt;

  PriceRequest({
    required this.id,
    required this.searchRequestId,
    this.managerId,  // ⬅️ Nullable
    this.managerName,  // ⬅️ Nullable
    this.accommodationId,  // ⬅️ Nullable
    this.accommodationName,  // ⬅️ Nullable
    this.accommodationUnitId,  // ⬅️ Nullable
    this.accommodationUnitName,  // ⬅️ Nullable
    required this.price,
    required this.clientResponseStatus,
    required this.createdAt,
  });

  factory PriceRequest.fromJson(Map<String, dynamic> json) {
    try {
      return PriceRequest(
        id: (json['id'] as num).toInt(),
        searchRequestId: (json['searchRequestId'] as num).toInt(),

        // ⬅️ SAFE: Nullable поля с проверкой
        managerId: json['managerId'] != null ? (json['managerId'] as num).toInt() : null,
        managerName: json['managerName'] as String?,
        accommodationId: json['accommodationId'] != null ? (json['accommodationId'] as num).toInt() : null,
        accommodationName: json['accommodationName'] as String?,
        accommodationUnitId: json['accommodationUnitId'] != null ? (json['accommodationUnitId'] as num).toInt() : null,
        accommodationUnitName: json['accommodationUnitName'] as String?,

        price: (json['price'] as num).toInt(),
        clientResponseStatus: json['clientResponseStatus'] as String? ?? 'WAITING',
        createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
    } catch (e, stackTrace) {
      print('❌ [PRICE REQUEST] Parse error: $e');
      print('   JSON: $json');
      print('   Stack: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'searchRequestId': searchRequestId,
      if (managerId != null) 'managerId': managerId,
      if (managerName != null) 'managerName': managerName,
      if (accommodationId != null) 'accommodationId': accommodationId,
      if (accommodationName != null) 'accommodationName': accommodationName,
      if (accommodationUnitId != null) 'accommodationUnitId': accommodationUnitId,
      if (accommodationUnitName != null) 'accommodationUnitName': accommodationUnitName,
      'price': price,
      'clientResponseStatus': clientResponseStatus,
      'createdAt': createdAt,
    };
  }

  /// ⬅️ СТАТУСЫ ПРЕДЛОЖЕНИЙ НА РУССКОМ
  String get statusTextRussian {
    switch (clientResponseStatus) {
      case 'WAITING':
        return 'Ожидает ответа';
      case 'ACCEPTED':
        return 'Принято';
      case 'REJECTED':
        return 'Отклонено';
      default:
        return clientResponseStatus;
    }
  }

  /// ⬅️ НОВОЕ: Безопасные геттеры с fallback
  String get safeAccommodationName => accommodationName ?? 'Не указано';
  String get safeAccommodationUnitName => accommodationUnitName ?? 'Не указано';
  String get safeManagerName => managerName ?? 'Менеджер';
}

/// Price Request Create Model
class PriceRequestCreate {
  final int searchRequestId;
  final int accommodationUnitId;
  final int price;

  PriceRequestCreate({
    required this.searchRequestId,
    required this.accommodationUnitId,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'searchRequestId': searchRequestId,
      'accommodationUnitId': accommodationUnitId,
      'price': price,
    };
  }
}

/// ⬅️ FIXED: Client Response Request (для accept/reject)
class ClientResponseRequest {
  final String clientResponseStatus; // "ACCEPTED" или "REJECTED"

  ClientResponseRequest({
    required this.clientResponseStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientResponseStatus': clientResponseStatus,
    };
  }
}