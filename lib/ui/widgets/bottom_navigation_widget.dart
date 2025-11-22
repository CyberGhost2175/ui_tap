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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true, // чтобы не пересекаться с home bar на iPhone
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
        width: 65.w, // ширина всей кнопки
        padding: EdgeInsets.only(top: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== BLUE INDICATOR (full width) =====
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3.h,
              width: isSelected ? 70.w : 0,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF295CDB) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            SizedBox(height: 10.h),

            // ===== ICON =====
            SvgPicture.asset(
              iconPath,
              height: 26.h,
              width: 26.w,
              color: isSelected ? const Color(0xFF295CDB) : Colors.grey.shade400,
            ),

            SizedBox(height: 2.h),

            // ===== LABEL =====
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF295CDB) : Colors.grey.shade400,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
