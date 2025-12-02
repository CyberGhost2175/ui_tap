import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio dio;
  late CookieJar cookieJar;

  Future<void> init() async {
    // Инициализация cookie jar
    final appDocDir = await getApplicationDocumentsDirectory();
    final appDocPath = appDocDir.path;
    cookieJar = PersistCookieJar(
      storage: FileStorage('$appDocPath/.cookies/'),
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
    ));

    // Добавляем cookie manager
    dio.interceptors.add(CookieManager(cookieJar));

    // Логирование (опционально)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[DIO] $obj'),
    ));

    print('✅ [DIO] Client initialized with cookie support');
  }

  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
    print('🍪 [DIO] All cookies cleared');
  }
}