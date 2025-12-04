import 'package:flutter/material.dart';

/// 📋 Reservation Model (бронирование)
/// Backend enum: SUCCESSFUL, WAITING_TO_APPROVE, APPROVED, REJECTED,
///               CLIENT_DIDNT_CAME, FINISHED_SUCCESSFUL, CANCELED
class Reservation {
  final int id;
  final int clientId;
  final String clientName;
  final int accommodationUnitId;
  final String accommodationUnitName;
  final String accommodationName;
  final int priceRequestId;
  final int searchRequestId;
  final int price;
  final String status;
  final bool needToPay;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reservation({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.accommodationUnitId,
    required this.accommodationUnitName,
    required this.accommodationName,
    required this.priceRequestId,
    required this.searchRequestId,
    required this.price,
    required this.status,
    required this.needToPay,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: (json['id'] as num).toInt(),
      clientId: (json['clientId'] as num).toInt(),
      clientName: json['clientName'] as String,
      accommodationUnitId: (json['accommodationUnitId'] as num).toInt(),
      accommodationUnitName: json['accommodationUnitName'] as String,
      accommodationName: json['accommodationName'] as String,
      priceRequestId: (json['priceRequestId'] as num).toInt(),
      searchRequestId: (json['searchRequestId'] as num).toInt(),
      price: (json['price'] as num).toInt(),
      status: json['status'] as String,
      needToPay: json['needToPay'] as bool,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      guestCount: (json['guestCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'accommodationUnitId': accommodationUnitId,
      'accommodationUnitName': accommodationUnitName,
      'accommodationName': accommodationName,
      'priceRequestId': priceRequestId,
      'searchRequestId': searchRequestId,
      'price': price,
      'status': status,
      'needToPay': needToPay,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'guestCount': guestCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// ⬅️ СТАТУСЫ НА РУССКОМ (основной геттер)
  String get statusTextRussian {
    switch (status) {
      case 'SUCCESSFUL':
        return 'Успешна';
      case 'WAITING_TO_APPROVE':
        return 'Ожидает подтверждения';
      case 'APPROVED':
        return 'Подтверждена';
      case 'REJECTED':
        return 'Отклонена';
      case 'CLIENT_DIDNT_CAME':
        return 'Клиент не пришел';
      case 'FINISHED_SUCCESSFUL':
        return 'Завершена успешно';
      case 'CANCELED':
        return 'Отменена';
      default:
        return status;
    }
  }

  /// ⬅️ Цвета для статусов
  Color get statusColor {
    switch (status) {
      case 'SUCCESSFUL':
        return Colors.green;
      case 'WAITING_TO_APPROVE':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CLIENT_DIDNT_CAME':
        return Colors.red.shade700;
      case 'FINISHED_SUCCESSFUL':
        return Colors.blue;
      case 'CANCELED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// ⬅️ Иконки для статусов
  IconData get statusIcon {
    switch (status) {
      case 'SUCCESSFUL':
        return Icons.check_circle;
      case 'WAITING_TO_APPROVE':
        return Icons.access_time;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'CLIENT_DIDNT_CAME':
        return Icons.person_off;
      case 'FINISHED_SUCCESSFUL':
        return Icons.done_all;
      case 'CANCELED':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  /// Активные брони
  bool get isActive {
    return status == 'SUCCESSFUL' ||
        status == 'WAITING_TO_APPROVE' ||
        status == 'APPROVED';
  }

  /// Завершенные брони
  bool get isFinished {
    return status == 'FINISHED_SUCCESSFUL' ||
        status == 'REJECTED' ||
        status == 'CLIENT_DIDNT_CAME' ||
        status == 'CANCELED';
  }

  /// Можно ли отменить
  bool get canCancel {
    return status == 'SUCCESSFUL' ||
        status == 'WAITING_TO_APPROVE' ||
        status == 'APPROVED';
  }
}