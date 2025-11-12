import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart'; // 🔹 добавили

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
    // 🔹 ждём 3 секунды анимации, потом безопасно переходим через GoRouter
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // безопасный переход после завершения фрейма
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login'); // или '/home' если нужно сразу на карту
        });
      }
    });
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
