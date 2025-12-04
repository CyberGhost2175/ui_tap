import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';

/// ⬅️ FIXED: Правильное сохранение cookies между сессиями
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio dio;
  late PersistCookieJar cookieJar;  // ⬅️ Изменен тип для явного указания

  Future<void> init() async {
    print('🚀 [DIO] Initializing client...');

    // Инициализация cookie jar с постоянным хранилищем
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/.cookies/';

    print('🍪 [DIO] Cookie path: $cookiePath');

    // ⬅️ CRITICAL: ignoreExpires = false, чтобы удалять истекшие cookies
    cookieJar = PersistCookieJar(
      storage: FileStorage(cookiePath),
      ignoreExpires: false,  // ⬅️ ВАЖНО: удаляем истекшие cookies
    );

    // Инициализация Dio
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
      // ⬅️ НОВОЕ: Разрешаем следовать редиректам
      followRedirects: true,
      maxRedirects: 5,
    ));

    // ⬅️ Добавляем cookie manager ПЕРВЫМ
    dio.interceptors.add(CookieManager(cookieJar));

    // Логирование (опционально)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,   // ⬅️ Показываем headers (cookies)
      responseHeader: true,  // ⬅️ Показываем response headers
      logPrint: (obj) => print('[DIO] $obj'),
    ));

    print('✅ [DIO] Client initialized with persistent cookies');

    // ⬅️ DEBUG: Показываем сохраненные cookies
    await printSavedCookies();  // ⬅️ Убрали _
  }

  /// ⬅️ НОВОЕ: Показать сохраненные cookies (для отладки)
  Future<void> printSavedCookies() async {  // ⬅️ Убрали _
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final cookies = await cookieJar.loadForRequest(uri);

      if (cookies.isEmpty) {
        print('🍪 [DIO] No saved cookies');
      } else {
        print('🍪 [DIO] Saved cookies (${cookies.length}):');
        for (var cookie in cookies) {
          print('   - ${cookie.name}: ${cookie.value.substring(0, 20)}... (expires: ${cookie.expires})');
        }
      }
    } catch (e) {
      print('⚠️ [DIO] Error loading cookies: $e');
    }
  }

  /// ⬅️ НОВОЕ: Проверить наличие refreshToken в cookies
  Future<bool> hasRefreshToken() async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final cookies = await cookieJar.loadForRequest(uri);

      final hasToken = cookies.any((c) => c.name == 'refreshToken');
      print('🔍 [DIO] Has refreshToken cookie: $hasToken');
      return hasToken;
    } catch (e) {
      print('❌ [DIO] Error checking refreshToken: $e');
      return false;
    }
  }

  Future<void> clearCookies() async {
    print('🗑️ [DIO] Clearing all cookies...');
    await cookieJar.deleteAll();
    print('✅ [DIO] All cookies cleared');
  }
}