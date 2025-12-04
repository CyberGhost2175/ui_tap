import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/reservations/reservation_models.dart';
import '../services/token_storage.dart';
import 'dio_client.dart';

/// 📋 API Service for Reservations (Bookings)
class ReservationApiService {
  static final ReservationApiService _instance = ReservationApiService._internal();
  factory ReservationApiService() => _instance;
  ReservationApiService._internal();

  static const String _reservationsEndpoint = '/reservations';

  Dio get _dio => DioClient().dio;

  /// Get authorization headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 📋 GET /reservations/my - Get all user's reservations
  Future<List<Reservation>> getMyReservations({
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Get My Reservations');
      print('URL: ${ApiConstants.baseUrl}$_reservationsEndpoint/my');

      final response = await _dio.get(
        '$_reservationsEndpoint/my',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDirection': sortDirection,
        },
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> data;

        if (responseData is Map<String, dynamic>) {
          // Если бэкенд вернул объект с пагинацией
          print('📦 [API] Response is paginated object');
          data = responseData['content'] as List<dynamic>;
          print('📄 [API] Page: ${responseData['page']}, Size: ${responseData['size']}, Total: ${responseData['totalElements']}');
        } else if (responseData is List) {
          // Если бэкенд вернул просто массив
          print('📦 [API] Response is plain array');
          data = responseData;
        } else {
          throw Exception('Неожиданный формат ответа от сервера');
        }

        print('✅ [API] Loaded ${data.length} reservations');

        // Парсим брони
        final reservations = data.map((json) => Reservation.fromJson(json)).toList();

        return reservations;
      } else {
        throw Exception('Ошибка загрузки бронирований: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');
      print('   Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Ошибка сервера');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// ⬅️ НОВОЕ: POST /reservations - Create reservation from accepted price request
  Future<Reservation> createReservation(int priceRequestId) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Create Reservation');
      print('URL: ${ApiConstants.baseUrl}$_reservationsEndpoint');
      print('Body: {"priceRequestId": $priceRequestId}');

      final response = await _dio.post(
        _reservationsEndpoint,
        data: {
          'priceRequestId': priceRequestId,
        },
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [API] Reservation created successfully');
        return Reservation.fromJson(response.data);
      } else {
        throw Exception('Ошибка создания бронирования: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');
      print('   Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Неверные данные');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Предложение цены не найдено');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Ошибка сервера');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 📋 GET /reservations/{id} - Get reservation by ID
  Future<Reservation> getReservationById(int id) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Get Reservation by ID: $id');
      print('URL: ${ApiConstants.baseUrl}$_reservationsEndpoint/$id');

      final response = await _dio.get(
        '$_reservationsEndpoint/$id',
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [API] Reservation loaded successfully');
        return Reservation.fromJson(response.data);
      } else {
        throw Exception('Ошибка загрузки бронирования: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');
      print('   Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Доступ запрещен');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Бронирование не найдено');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Ошибка сервера');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 🗑️ PATCH /reservations/{id}/cancel - Cancel reservation
  Future<void> cancelReservation(int id) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Cancel Reservation: $id');
      print('URL: ${ApiConstants.baseUrl}$_reservationsEndpoint/$id/cancel');

      final response = await _dio.patch(
        '$_reservationsEndpoint/$id/cancel',
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 204) {
        print('✅ [API] Reservation cancelled successfully');
        return;
      } else {
        throw Exception('Ошибка отмены бронирования: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');
      print('   Response: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] as String?;
        if (errorMessage != null && errorMessage.contains('слишком поздно')) {
          throw Exception('Отмена невозможна - слишком поздно (менее 1 дня до заезда)');
        }
        throw Exception('Отмена невозможна - недопустимый статус или слишком поздно');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Доступ запрещен - можно отменять только свои бронирования');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Бронирование не найдено');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Ошибка сервера');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }
}