import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/search/price_request_models.dart';  // ⬅️ Импортируем модели
import 'token_storage.dart';

/// API service для работы с Price Requests (предложениями цен)
class PriceRequestApiService {
  static const String baseUrl = 'http://63.178.189.113:8888/api';

  /// Получить access token
  Future<String?> _getAccessToken() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final isExpired = await TokenStorage.isTokenExpired();
        if (isExpired) {
          print('⚠️ Token expired');
          return null;
        }
        return token;
      }
      return null;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  /// 📥 Получить все Price Requests для Search Request
  /// GET /price-requests/by-search-request/{searchRequestId}
  Future<List<PriceRequest>> getPriceRequestsBySearchRequest(
      int searchRequestId, {
        int page = 0,
        int size = 20,
        String sortBy = 'createdAt',
        String sortDirection = 'desc',
      }) async {
    print('📤 [API] Get Price Requests for Search Request: $searchRequestId');

    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse(
      '$baseUrl/price-requests/by-search-request/$searchRequestId'
          '?page=$page&size=$size&sortBy=$sortBy&sortDirection=$sortDirection',
    );

    print('URL: $url');

    final response = await http.get(
      url,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 [API] Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final dynamic data = json.decode(utf8.decode(response.bodyBytes));

      // Проверяем структуру ответа
      if (data is Map<String, dynamic> && data.containsKey('content')) {
        // Paginated response
        final List<dynamic> content = data['content'] as List<dynamic>;
        print('📦 [API] Found ${content.length} price requests');

        final requests = content
            .map((json) => PriceRequest.fromJson(json as Map<String, dynamic>))
            .toList();

        return requests;
      } else if (data is List<dynamic>) {
        // Array response
        print('📦 [API] Found ${data.length} price requests');
        final requests = data
            .map((json) => PriceRequest.fromJson(json as Map<String, dynamic>))
            .toList();
        return requests;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      print('❌ [API] Error: $errorBody');
      throw Exception('Failed to load price requests: ${response.statusCode}');
    }
  }

  /// ✅ Принять предложение цены (ACCEPTED)
  /// PATCH /price-requests/{id}/respond
  Future<void> acceptPriceRequest(int priceRequestId) async {
    print('📤 [API] Accept Price Request: $priceRequestId');

    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$baseUrl/price-requests/$priceRequestId/respond');
    print('URL: $url');

    final request = ClientResponseRequest(
      clientResponseStatus: 'ACCEPTED',
    );

    final response = await http.patch(
      url,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    print('📥 [API] Response: ${response.statusCode}');

    if (response.statusCode == 204) {
      print('✅ [API] Price request accepted');
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      print('❌ [API] Error: $errorBody');
      throw Exception('Failed to accept price request: ${response.statusCode}');
    }
  }

  /// ❌ Отклонить предложение цены (REJECTED)
  /// PATCH /price-requests/{id}/respond
  Future<void> rejectPriceRequest(int priceRequestId) async {
    print('📤 [API] Reject Price Request: $priceRequestId');

    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$baseUrl/price-requests/$priceRequestId/respond');
    print('URL: $url');

    final request = ClientResponseRequest(
      clientResponseStatus: 'REJECTED',
    );

    final response = await http.patch(
      url,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    print('📥 [API] Response: ${response.statusCode}');

    if (response.statusCode == 204) {
      print('✅ [API] Price request rejected');
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      print('❌ [API] Error: $errorBody');
      throw Exception('Failed to reject price request: ${response.statusCode}');
    }
  }
}