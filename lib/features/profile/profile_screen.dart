import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ProfileScreen - user profile with personal information
/// Contains: Avatar, Name, Email, Phone, Password, Payment methods
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data
  String _userName = 'Алия Нурбекова';
  String _userEmail = 'aliya.nurbekova@example.com';
  String _userPhone = '+7 (777) 123-45-67';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Профиль',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // Avatar section
            _buildAvatarSection(),
            SizedBox(height: 32.h),

            // Personal info
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Имя',
              value: _userName,
              onEdit: () => _showEditDialog('Имя', _userName, (val) {
                setState(() => _userName = val);
              }),
            ),
            SizedBox(height: 12.h),

            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: _userEmail,
              onEdit: () => _showEditDialog('Email', _userEmail, (val) {
                setState(() => _userEmail = val);
              }),
            ),
            SizedBox(height: 12.h),

            _buildInfoCard(
              icon: Icons.phone_outlined,
              title: 'Телефон',
              value: _userPhone,
              onEdit: () => _showEditDialog('Телефон', _userPhone, (val) {
                setState(() => _userPhone = val);
              }),
            ),
            SizedBox(height: 12.h),

            _buildInfoCard(
              icon: Icons.lock_outline,
              title: 'Пароль',
              value: '••••••••',
              onEdit: () => _showPasswordDialog(),
            ),
            SizedBox(height: 24.h),

            // Payment methods
            _buildPaymentMethodsCard(),
            SizedBox(height: 24.h),

            // Save button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// Avatar section with edit button
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar circle
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF6F6F6),
                border: Border.all(
                  color: const Color(0xFF295CDB).withOpacity(0.2),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 50.sp,
                color: const Color(0xFF295CDB),
              ),
            ),
            // Edit button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement avatar change
                  _showComingSoonDialog('Изменение аватара');
                },
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF295CDB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          _userName,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _userEmail,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Info card with edit button
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 22.sp, color: const Color(0xFF295CDB)),
          ),
          SizedBox(width: 12.w),

          // Title & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              size: 22.sp,
              color: const Color(0xFF295CDB),
            ),
          ),
        ],
      ),
    );
  }

  /// Payment methods card
  Widget _buildPaymentMethodsCard() {
    return InkWell(
      onTap: () {
        // TODO: Navigate to payment methods screen
        _showComingSoonDialog('Способы оплаты');
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.credit_card_outlined,
                size: 22.sp,
                color: const Color(0xFF295CDB),
              ),
            ),
            SizedBox(width: 12.w),

            // Text
            Expanded(
              child: Text(
                'Способы оплаты',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              size: 24.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Save user data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Данные сохранены'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF295CDB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Сохранить изменения',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Show edit dialog
  void _showEditDialog(String field, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Изменить $field',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Введите $field',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: Text(
              'Сохранить',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF295CDB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show password change dialog
  void _showPasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Изменить пароль',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Старый пароль',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Новый пароль',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Подтвердите пароль',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement password change logic
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Пароль успешно изменён'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Пароли не совпадают'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Изменить',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF295CDB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          feature,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Эта функция скоро будет доступна',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Понятно',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF295CDB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}