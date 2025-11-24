import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/token_storage.dart'; // 🔹 ДОБАВИЛИ

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTransition();
  }

  void _startTransition() {
    // 🔹 Ждём 3 секунды для анимации + проверяем авторизацию
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  /// 🔐 Проверка авторизации и навигация
  Future<void> _checkAuthAndNavigate() async {
    try {
      // Проверяем есть ли токен и не истек ли он
      final isLoggedIn = await TokenStorage.isLoggedIn();

      print('🔐 Splash: Проверка авторизации - $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        // Пользователь авторизован и токен валидный
        // Загружаем данные пользователя для проверки
        final userData = await TokenStorage.getUserData();
        final hasUserData = userData['email'] != null &&
            userData['email']!.isNotEmpty;

        print('👤 Splash: Данные пользователя найдены - $hasUserData');

        if (hasUserData) {
          // ✅ Все хорошо - переходим на главную (АВТОЛОГИН)
          print('✅ Splash: Автологин успешен → /home');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });
        } else {
          // Токен есть, но данных нет - идем на логин
          print('⚠️ Splash: Токен есть, но данных нет → /login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/login');
          });
        }
      } else {
        // ❌ Не авторизован или токен истек - идем на логин
        print('❌ Splash: Не авторизован → /login');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/login');
        });
      }
    } catch (e) {
      print('❌ Splash: Ошибка проверки авторизации: $e');
      // При ошибке - идем на логин
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/login');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/lottie/house_animation.json',
                    width: 250.w,
                    height: 250.h,
                    repeat: true,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            Positioned(
              bottom: 60.h,
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/icons/Logo.svg',
                    width: 120.w,
                  ),
                  SizedBox(height: 20.h),
                  const CircularProgressIndicator(
                    color: Color(0xFF295CDB),
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}