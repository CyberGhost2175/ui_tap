/// Models for Price Request (предложения цен от менеджеров)

/// Price Request - предложение цены от менеджера
class PriceRequest {
  final int id;
  final int searchRequestId;
  final int accommodationUnitId;
  final String accommodationUnitName;
  final String accommodationName;
  final int price;
  final String status; // ACCEPTED, REJECTED, WAITING
  final String clientResponseStatus; // ACCEPTED, REJECTED, WAITING
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  PriceRequest({
    required this.id,
    required this.searchRequestId,
    required this.accommodationUnitId,
    required this.accommodationUnitName,
    required this.accommodationName,
    required this.price,
    required this.status,
    required this.clientResponseStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory PriceRequest.fromJson(Map<String, dynamic> json) {
    return PriceRequest(
      id: (json['id'] as num).toInt(),
      searchRequestId: (json['searchRequestId'] as num).toInt(),
      accommodationUnitId: (json['accommodationUnitId'] as num).toInt(),
      accommodationUnitName: json['accommodationUnitName'] as String,
      accommodationName: json['accommodationName'] as String,
      price: (json['price'] as num).toInt(),
      status: json['status'] as String,
      clientResponseStatus: json['clientResponseStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDeleted: json['isDeleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'searchRequestId': searchRequestId,
      'accommodationUnitId': accommodationUnitId,
      'accommodationUnitName': accommodationUnitName,
      'accommodationName': accommodationName,
      'price': price,
      'status': status,
      'clientResponseStatus': clientResponseStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  /// Статус на русском
  String get statusText {
    switch (clientResponseStatus) {
      case 'ACCEPTED':
        return 'Принято';
      case 'REJECTED':
        return 'Отклонено';
      case 'WAITING':
        return 'Ожидает ответа';
      default:
        return clientResponseStatus;
    }
  }

  /// Цвет статуса
  String get statusColor {
    switch (clientResponseStatus) {
      case 'ACCEPTED':
        return 'green';
      case 'REJECTED':
        return 'red';
      case 'WAITING':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Можно ли ответить на предложение
  bool get canRespond => clientResponseStatus == 'WAITING';
}

/// Response for client decision
class ClientResponseRequest {
  final String clientResponseStatus; // ACCEPTED or REJECTED

  ClientResponseRequest({
    required this.clientResponseStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientResponseStatus': clientResponseStatus,
    };
  }
}