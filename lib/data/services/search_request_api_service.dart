import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../services/token_storage.dart';
import '../models/search/search_request_models.dart';

/// 🔍 API Service for Search Requests (Complete CRUD)
class SearchRequestApiService {
  static final SearchRequestApiService _instance = SearchRequestApiService._internal();
  factory SearchRequestApiService() => _instance;
  SearchRequestApiService._internal();

  static const String _searchRequestsEndpoint = '/search-requests';

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
  /// WORKAROUND: Backend returns empty body on 201
  /// Solution: Get latest request after creation
  Future<SearchRequest> createSearchRequest(SearchRequestCreate request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint');
      final headers = await _getHeaders();

      print('📤 [API] Create Search Request');
      print('URL: $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [API] Response: ${response.statusCode}');
      print('📥 [API] Response body length: ${response.body.length}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ⚠️ WORKAROUND: Бэкенд возвращает пустое тело
        if (response.body.isEmpty || response.body.trim() == '') {
          print('⚠️ [API] Backend returned empty body (this is a backend bug!)');
          print('🔄 [API] Workaround: Fetching all requests to find the latest...');

          // Получаем все заявки пользователя и возвращаем последнюю
          final allRequests = await getAllSearchRequests();

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
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          print('✅ [API] Search request created successfully (${response.statusCode})');
          return SearchRequest.fromJson(data);
        } catch (e) {
          print('❌ [API] Failed to parse response: $e');
          print('❌ [API] Response was: ${response.body}');

          // Fallback: загружаем последнюю заявку
          print('🔄 [API] Fallback: Fetching all requests...');
          final allRequests = await getAllSearchRequests();
          if (allRequests.isNotEmpty) {
            return allRequests.first;
          }

          throw Exception('Заявка создана, но не удалось получить её данные');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные запроса';
          print('❌ [API] Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Некорректные данные запроса');
        }
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
    } catch (e) {
      print('❌ [API] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 📋 GET /search-requests/{id} - Get search request by ID
  Future<SearchRequest> getSearchRequestById(int id) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id');
      final headers = await _getHeaders();

      print('📤 [API] Get Search Request by ID: $id');
      print('URL: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ [API] Search request loaded successfully');
        return SearchRequest.fromJson(data);
      } else if (response.statusCode == 401) {
        print('❌ [API] Error 401: Unauthorized');
        throw Exception('Необходима авторизация');
      } else if (response.statusCode == 403) {
        print('❌ [API] Error 403: Forbidden');
        throw Exception('Доступ запрещен');
      } else if (response.statusCode == 404) {
        print('❌ [API] Error 404: Not found');
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        print('❌ [API] Error 500: Server error');
        throw Exception('Ошибка сервера');
      } else {
        print('❌ [API] Error ${response.statusCode}');
        throw Exception('Ошибка загрузки заявки: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [API] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 💰 PATCH /search-requests/{id}/price - Update price
  Future<SearchRequest> updatePrice(int id, int newPrice) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/price');
      final headers = await _getHeaders();

      print('📤 [API] Update Price: $id -> $newPrice');
      print('URL: $url');

      final response = await http
          .patch(
        url,
        headers: headers,
        body: jsonEncode({'price': newPrice}),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ [API] Price updated successfully');
        return SearchRequest.fromJson(data);
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные';
          print('❌ [API] Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Некорректные данные');
        }
      } else if (response.statusCode == 401) {
        print('❌ [API] Error 401: Unauthorized');
        throw Exception('Необходима авторизация');
      } else if (response.statusCode == 403) {
        print('❌ [API] Error 403: Forbidden');
        throw Exception('Доступ запрещен - можно обновлять только свои заявки');
      } else if (response.statusCode == 404) {
        print('❌ [API] Error 404: Not found');
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        print('❌ [API] Error 500: Server error');
        throw Exception('Ошибка сервера');
      } else {
        print('❌ [API] Error ${response.statusCode}');
        throw Exception('Ошибка обновления цены: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [API] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// ❌ PATCH /search-requests/{id}/cancel - Cancel search request
  /// 💰 PATCH /search-requests/{id}/price - Update price
  ///
  /// После создания заявки можно изменить только цену.
  /// Другие параметры изменить нельзя.
  Future<void> updateSearchRequestPrice(int id, int newPrice) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/price');
      final headers = await _getHeaders();

      print('📤 [API] Update Search Request Price: $id');
      print('URL: $url');
      print('Body: {"price": $newPrice}');

      final response = await http
          .patch(
        url,
        headers: headers,
        body: jsonEncode({'price': newPrice}),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [API] Price updated successfully');
        return;
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные или недопустимый статус заявки';
          print('❌ [API] Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Некорректные данные запроса');
        }
      } else if (response.statusCode == 401) {
        print('❌ [API] Error 401: Unauthorized');
        throw Exception('Необходима авторизация');
      } else if (response.statusCode == 403) {
        print('❌ [API] Error 403: Forbidden');
        throw Exception('Доступ запрещен - можно обновлять только свои заявки');
      } else if (response.statusCode == 404) {
        print('❌ [API] Error 404: Not found');
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        print('❌ [API] Error 500: Server error');
        throw Exception('Ошибка сервера');
      } else {
        print('❌ [API] Error ${response.statusCode}');
        throw Exception('Ошибка обновления цены: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [API] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// ❌ PATCH /search-requests/{id}/cancel - Cancel search request
  Future<void> cancelSearchRequest(int id) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/cancel');
      final headers = await _getHeaders();

      print('📤 [API] Cancel Search Request: $id');
      print('URL: $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ [API] Search request cancelled successfully');
        return;
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Недопустимый статус заявки';
          print('❌ [API] Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Недопустимый статус заявки');
        }
      } else if (response.statusCode == 401) {
        print('❌ [API] Error 401: Unauthorized');
        throw Exception('Необходима авторизация');
      } else if (response.statusCode == 403) {
        print('❌ [API] Error 403: Forbidden');
        throw Exception('Доступ запрещен - можно отменять только свои заявки');
      } else if (response.statusCode == 404) {
        print('❌ [API] Error 404: Not found');
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        print('❌ [API] Error 500: Server error');
        throw Exception('Ошибка сервера');
      } else {
        print('❌ [API] Error ${response.statusCode}');
        throw Exception('Ошибка отмены заявки: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [API] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// 📋 GET /search-requests/my - Get all user's search requests
  ///
  /// ⬅️ FIXED: Используем правильный endpoint /my
  Future<List<SearchRequest>> getAllSearchRequests({
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'desc', // desc = новые first
  }) async {
    try {
      // ⬅️ ВАЖНО: Используем /search-requests/my вместо /search-requests
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/my').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'sortBy': sortBy,
          'sortDirection': sortDirection,
        },
      );

      final headers = await _getHeaders();

      print('📤 [API] Get All Search Requests');
      print('URL: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // ⬅️ ВАЖНО: Бэкенд возвращает объект с пагинацией
        // Формат: { "content": [...], "page": 0, "size": 20, ... }
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

        print('✅ [API] Loaded ${data.length} search requests');

        // Парсим заявки
        final requests = data.map((json) => SearchRequest.fromJson(json)).toList();

        // Сортировка уже выполняется на бэкенде через параметры
        return requests;
      } else if (response.statusCode == 401) {
        print('❌ [API] Error 401: Unauthorized');
        throw Exception('Необходима авторизация');
      } else if (response.statusCode == 500) {
        print('❌ [API] Error 500: Server error');
        throw Exception('Ошибка сервера');
      } else {
        print('❌ [API] Error ${response.statusCode}');
        throw Exception('Ошибка загрузки заявок: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [API] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения к серверу');
    }
  }
}