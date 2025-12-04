import 'dart:convert';  // ⬅️ ДОБАВЛЕНО для декодирования сообщений
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../services/token_storage.dart';
import '../models/search/search_request_models.dart';
import 'dio_client.dart';

/// 🔍 API Service for Search Requests (Complete CRUD)
/// ⬅️ FIXED: Обработка 404 + декодирование русских сообщений
class SearchRequestApiService {
  static final SearchRequestApiService _instance = SearchRequestApiService._internal();
  factory SearchRequestApiService() => _instance;
  SearchRequestApiService._internal();

  static const String _searchRequestsEndpoint = '/search-requests';

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

  /// ✅ POST /search-requests - Create search request
  ///
  /// ⬅️ FIXED: Обработка 404 (жилье не найдено) + декодирование русских сообщений
  Future<SearchRequest> createSearchRequest(SearchRequestCreate request) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Create Search Request');
      print('URL: ${ApiConstants.baseUrl}$_searchRequestsEndpoint');
      print('Body: ${request.toJson()}');

      // ⬅️ НОВОЕ: Проверка на пустую цену
      if (request.price <= 0) {
        throw Exception('Укажите цену за ночь');
      }

      final response = await _dio.post(
        _searchRequestsEndpoint,
        data: request.toJson(),
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');
      print('📥 [API] Response body length: ${response.data?.toString().length ?? 0}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ⚠️ WORKAROUND: Бэкенд возвращает пустое тело
        if (response.data == null || response.data.toString().trim() == '') {
          print('⚠️ [API] Backend returned empty body (this is a backend bug!)');
          print('🔄 [API] Workaround: Fetching all requests to find the latest...');

          // Получаем все заявки пользователя и возвращаем последнюю
          final allRequests = await getMySearchRequests();

          if (allRequests.isEmpty) {
            throw Exception('Заявка создана, но не удалось получить её данные');
          }

          // Возвращаем последнюю созданную заявку
          final latestRequest = allRequests.first;
          print('✅ [API] Found latest request: ID=${latestRequest.id}');
          return latestRequest;
        }

        // Если body не пустое - парсим как обычно
        try {
          print('✅ [API] Search request created successfully (${response.statusCode})');
          return SearchRequest.fromJson(response.data);
        } catch (e) {
          print('❌ [API] Failed to parse response: $e');
          print('❌ [API] Response was: ${response.data}');

          // Fallback: загружаем последнюю заявку
          print('🔄 [API] Fallback: Fetching all requests...');
          final allRequests = await getMySearchRequests();
          if (allRequests.isNotEmpty) {
            return allRequests.first;
          }

          throw Exception('Заявка создана, но не удалось получить её данные');
        }
      } else if (response.statusCode == 400) {
        final errorMessage = response.data?['message'] ?? 'Некорректные данные запроса';
        print('❌ [API] Error 400: $errorMessage');
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        print('❌ [API] Error 401: Unauthorized');
        throw Exception('Необходима авторизация');
      } else if (response.statusCode == 403) {
        print('❌ [API] Error 403: Forbidden');
        throw Exception('Доступ запрещен');
      } else if (response.statusCode == 500) {
        print('❌ [API] Error 500: Server error');
        throw Exception('Ошибка сервера');
      } else {
        print('❌ [API] Error ${response.statusCode}');
        throw Exception('Ошибка создания заявки: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');
      print('   Response: ${e.response?.data}');

      // ⬅️ FIXED: Обработка 404 (жилье не найдено)
      if (e.response?.statusCode == 404) {
        String errorMessage = 'Жилье не найдено в указанном бюджете';

        try {
          // Декодируем русское сообщение от сервера
          final data = e.response?.data;
          if (data != null && data is Map<String, dynamic>) {
            final rawMessage = data['message'] as String?;
            if (rawMessage != null && rawMessage.isNotEmpty) {
              // Исправляем кракозябры (декодируем из Latin-1 в UTF-8)
              try {
                errorMessage = utf8.decode(rawMessage.codeUnits);
              } catch (_) {
                errorMessage = rawMessage;
              }

              print('📝 [API] Decoded error message: $errorMessage');
            }
          }
        } catch (parseError) {
          print('⚠️ [API] Failed to parse error message: $parseError');
        }

        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Некорректные данные';
        throw Exception(errorMessage);
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 📋 GET /search-requests/{id} - Get search request by ID
  Future<SearchRequest> getSearchRequestById(int id) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Get Search Request by ID: $id');
      print('URL: ${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id');

      final response = await _dio.get(
        '$_searchRequestsEndpoint/$id',
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [API] Search request loaded successfully');
        return SearchRequest.fromJson(response.data);
      } else {
        throw Exception('Ошибка загрузки заявки: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Доступ запрещен');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Заявка не найдена');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Ошибка сервера');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 💰 PATCH /search-requests/{id}/price - Update price
  Future<SearchRequest> updatePrice(int id, int newPrice) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Update Price: $id -> $newPrice');
      print('URL: ${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/price');

      final response = await _dio.patch(
        '$_searchRequestsEndpoint/$id/price',
        data: {'price': newPrice},
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [API] Price updated successfully');
        return SearchRequest.fromJson(response.data);
      } else {
        throw Exception('Ошибка обновления цены: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Некорректные данные';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Доступ запрещен - можно обновлять только свои заявки');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Заявка не найдена');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 💰 PATCH /search-requests/{id}/price - Update price (void version)
  Future<void> updateSearchRequestPrice(int id, int newPrice) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Update Search Request Price: $id');
      print('URL: ${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/price');
      print('Body: {"price": $newPrice}');

      final response = await _dio.patch(
        '$_searchRequestsEndpoint/$id/price',
        data: {'price': newPrice},
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [API] Price updated successfully');
        return;
      } else {
        throw Exception('Ошибка обновления цены: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Некорректные данные или недопустимый статус заявки';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Доступ запрещен - можно обновлять только свои заявки');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Заявка не найдена');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// ❌ PATCH /search-requests/{id}/cancel - Cancel search request
  Future<void> cancelSearchRequest(int id) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Cancel Search Request: $id');
      print('URL: ${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/cancel');

      final response = await _dio.patch(
        '$_searchRequestsEndpoint/$id/cancel',
        options: Options(headers: headers),
      );

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ [API] Search request cancelled successfully');
        return;
      } else {
        throw Exception('Ошибка отмены заявки: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException: ${e.message}');

      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Недопустимый статус заявки';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Доступ запрещен - можно отменять только свои заявки');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Заявка не найдена');
      }

      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 📋 GET /search-requests/my - Get all user's search requests
  Future<List<SearchRequest>> getMySearchRequests({
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();

      print('📤 [API] Get My Search Requests');
      print('URL: ${ApiConstants.baseUrl}$_searchRequestsEndpoint/my');

      final response = await _dio.get(
        '$_searchRequestsEndpoint/my',
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
          print('📦 [API] Response is paginated object');
          data = responseData['content'] as List<dynamic>;
          print('📄 [API] Page: ${responseData['page']}, Size: ${responseData['size']}, Total: ${responseData['totalElements']}');
        } else if (responseData is List) {
          print('📦 [API] Response is plain array');
          data = responseData;
        } else {
          throw Exception('Неожиданный формат ответа от сервера');
        }

        print('✅ [API] Loaded ${data.length} search requests');
        final requests = data.map((json) => SearchRequest.fromJson(json)).toList();
        return requests;
      } else {
        throw Exception('Ошибка загрузки заявок: ${response.statusCode}');
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

  /// 📋 GET /search-requests - Get all search requests (старый метод для совместимости)
  ///
  /// ⬅️ DEPRECATED: Используйте getMySearchRequests() вместо этого
  Future<List<SearchRequest>> getAllSearchRequests({
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'desc',
  }) async {
    // Перенаправляем на новый метод
    return getMySearchRequests(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
    );
  }
}