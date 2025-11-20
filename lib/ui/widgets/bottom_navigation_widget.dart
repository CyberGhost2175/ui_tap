import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  static const Color primary = Color(0xFF2853AF); // 🔥 Новый цвет

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: 64.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              iconPath: 'assets/icons/main_icon.svg',
              label: 'Главная',
              index: 0,
            ),
            _buildNavItem(
              iconPath: 'assets/icons/bookings_icon.svg',
              label: 'Мои брони',
              index: 1,
            ),
            _buildNavItem(
              iconPath: 'assets/icons/settings_icon.svg',
              label: 'Настройки',
              index: 2,
            ),
            _buildNavItem(
              iconPath: 'assets/icons/profile_icon.svg',
              label: 'Профиль',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required int index,
    required String iconPath,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        width: 70.w,
        padding: EdgeInsets.only(top: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔵 Линия сверху — НОВЫЙ ЦВЕТ
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3.h,
              width: isSelected ? 70.w : 0,
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            SizedBox(height: 10.h),

            /// 🔵 Иконка — НОВЫЙ ЦВЕТ
            SvgPicture.asset(
              iconPath,
              height: 26.h,
              width: 26.w,
              color: isSelected ? primary : Colors.grey.shade400,
            ),

            SizedBox(height: 2.h),

            /// 🔵 Текст — НОВЫЙ ЦВЕТ
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
