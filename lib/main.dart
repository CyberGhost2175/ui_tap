import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/navigation/app_router.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/dio_client.dart';
import 'data/services/notification_service.dart';

/// 🚀 Main entry point with auto-refresh initialization
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient().init();

  // 📱 Initialize notifications
  await NotificationService().initialize();

  // 🔄 Initialize auto-refresh on app startup
  await _initializeAutoRefresh();

  runApp(const UiTapApp());
}

/// Initialize automatic token refresh
Future<void> _initializeAutoRefresh() async {
  try {
    final authService = AuthApiService();
    await authService.initAutoRefresh();
    print('✅ [MAIN] Auto-refresh initialized');
  } catch (e) {
    print('❌ [MAIN] Auto-refresh initialization failed: $e');
    // Continue app startup even if initialization fails
  }
}

class UiTapApp extends StatelessWidget {
  const UiTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'UI Tap',
          debugShowCheckedModeBanner: false,

          // Localizations
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ru', ''), // Russian
            Locale('kk', ''), // Kazakh
          ],

          // Theme
          theme: ThemeData(
            primaryColor: const Color(0xFF295CDB),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'SF Pro Display',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF295CDB),
            ),
            useMaterial3: true,
          ),

          // Router
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}