import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/navigation/app_router.dart';

void main() {
  runApp(const UiTapApp());
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

          // 🔧 FIX: Add localizations
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

          theme: ThemeData(
            primaryColor: const Color(0xFF295CDB),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'SF Pro Display', // Or your custom font
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF295CDB),
            ),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}