import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/profile/profile_screen.dart'; // New screen

// --------------------
// Routes initialization
// --------------------
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const BookingSearchScreen(),
    ),
    // About Screen route
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    // Profile Screen route
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

void main() {
  runApp(const UiTapApp());
}

class UiTapApp extends StatelessWidget {
  const UiTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Ui Tap',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter, // GoRouter configuration
          theme: ThemeData(
            primaryColor: const Color(0xFF295CDB),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'SF Pro Display', // Custom font if available
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('kk', 'KZ'), // Kazakh
            Locale('en', 'US'),
          ],
          locale: const Locale('ru', 'RU'),
        );
      },
    );
  }
}