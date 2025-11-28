import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../services/token_storage.dart';
import '../models/search/search_request_models.dart';

/// API Service for Search Requests
class SearchRequestApiService {
  static final SearchRequestApiService _instance = SearchRequestApiService._internal();
  factory SearchRequestApiService() => _instance;
  SearchRequestApiService._internal();

  static const String _searchRequestsEndpoint = '/search-requests';

  /// Get authorization header with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// POST /search-requests - Create search request
  ///
  /// Returns SearchRequest on success (200)
  /// Throws Exception on error (400, 401, 403, 500)
  Future<SearchRequest> createSearchRequest(SearchRequestCreate request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint');
      final headers = await _getHeaders();

      print('📤 Create Search Request:');
      print('URL: $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Search request created successfully');
        return SearchRequest.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Некорректные данные запроса';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Доступ запрещен');
      } else if (response.statusCode == 500) {
        throw Exception('Внутренняя ошибка сервера');
      } else {
        throw Exception('Ошибка создания заявки: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating search request: $e');
      rethrow;
    }
  }

  /// GET /search-requests/{id} - Get search request by ID
  ///
  /// Returns SearchRequest on success (200)
  /// Throws Exception on error (401, 403, 404, 500)
  Future<SearchRequest> getSearchRequestById(int id) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id');
      final headers = await _getHeaders();

      print('📤 Get Search Request by ID: $id');
      print('URL: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Search request loaded successfully');
        return SearchRequest.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Доступ запрещен');
      } else if (response.statusCode == 404) {
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        throw Exception('Внутренняя ошибка сервера');
      } else {
        throw Exception('Ошибка загрузки заявки: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading search request: $e');
      rethrow;
    }
  }

  /// PATCH /search-requests/{id}/price - Update price
  ///
  /// Returns updated SearchRequest on success (200)
  /// Throws Exception on error (400, 401, 403, 404, 500)
  Future<SearchRequest> updatePrice(int id, int newPrice) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/price');
      final headers = await _getHeaders();

      print('📤 Update Price for Request #$id:');
      print('URL: $url');
      print('New Price: $newPrice');

      final response = await http
          .patch(
        url,
        headers: headers,
        body: jsonEncode({'price': newPrice}),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Price updated successfully');
        return SearchRequest.fromJson(data);
      } else if (response.statusCode == 400) {
        throw Exception('Некорректные данные или недопустимый статус заявки');
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Доступ запрещен - можно обновлять только свои заявки');
      } else if (response.statusCode == 404) {
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        throw Exception('Внутренняя ошибка сервера');
      } else {
        throw Exception('Ошибка обновления цены: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating price: $e');
      rethrow;
    }
  }

  /// PATCH /search-requests/{id}/cancel - Cancel search request
  ///
  /// Returns cancelled SearchRequest on success (204)
  /// Throws Exception on error (400, 401, 403, 404, 500)
  Future<void> cancelSearchRequest(int id) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$_searchRequestsEndpoint/$id/cancel');
      final headers = await _getHeaders();

      print('📤 Cancel Search Request #$id');
      print('URL: $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 204) {
        print('✅ Search request cancelled successfully');
        return;
      } else if (response.statusCode == 400) {
        throw Exception('Недопустимый статус заявки для отмены');
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Доступ запрещен - можно отменять только свои заявки');
      } else if (response.statusCode == 404) {
        throw Exception('Заявка не найдена');
      } else if (response.statusCode == 500) {
        throw Exception('Внутренняя ошибка сервера');
      } else {
        throw Exception('Ошибка отмены заявки: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cancelling search request: $e');
      rethrow;
    }
  }
}