import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user/user_model.dart';
import '../../data/services/token_storage.dart';

/// ProfileScreen - user profile with real data from storage
/// Features: Load user data, Inline editing, Edit mode toggle, Save changes, Logout
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Edit mode state
  bool _isEditMode = false;
  bool _isLoading = true;

  // User data
  UserModel? _user;

  // Original values (for reset on cancel)
  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalEmail = '';
  String _originalPhone = '';

  // Text controllers for editable fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is logged in
      final isLoggedIn = await TokenStorage.isLoggedIn();

      if (!isLoggedIn) {
        // Token expired or no token - redirect to login
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // Get user data from storage
      final userData = await TokenStorage.getUserData();
      _user = UserModel.fromStorage(userData);

      // Set controllers with user data
      _firstNameController.text = _user?.firstName ?? '';
      _lastNameController.text = _user?.lastName ?? '';
      _emailController.text = _user?.email ?? '';
      _phoneController.text = _user?.phone ?? '';

      // Save original values
      _originalFirstName = _firstNameController.text;
      _originalLastName = _lastNameController.text;
      _originalEmail = _emailController.text;
      _originalPhone = _phoneController.text;
    } catch (e) {
      print('Error loading user data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;

      // If exiting edit mode without saving, reset values
      if (!_isEditMode) {
        _firstNameController.text = _originalFirstName;
        _lastNameController.text = _originalLastName;
        _emailController.text = _originalEmail;
        _phoneController.text = _originalPhone;
      }
    });
  }

  /// Save changes
  Future<void> _saveChanges() async {
    try {
      // Save updated user data to storage
      await TokenStorage.saveUserData(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        username: _user?.username,
      );

      // Update original values
      _originalFirstName = _firstNameController.text;
      _originalLastName = _lastNameController.text;
      _originalEmail = _emailController.text;
      _originalPhone = _phoneController.text;

      setState(() {
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Данные успешно сохранены'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.only(
              bottom: 80.h,
              left: 20.w,
              right: 20.w,
            ),
          ),
        );
      }

      // TODO: Also send updated data to backend API
      // await _authRepository.updateProfile(...)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Logout user
  Future<void> _logout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear all stored data
      await TokenStorage.clearAll();

      if (mounted) {
        // Navigate to login
        context.go('/login');
      }
    }
  }

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
        actions: [
          // Logout button
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.red.shade400,
              size: 24.sp,
            ),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: _isEditMode ? 100.h : 20.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and name section
                _buildAvatarSection(),

                SizedBox(height: 32.h),

                // Divider
                Divider(color: Colors.grey.shade200, height: 1),

                SizedBox(height: 24.h),

                // First Name field
                _buildEditableField(
                  label: 'Имя',
                  controller: _firstNameController,
                ),

                SizedBox(height: 20.h),

                // Last Name field
                _buildEditableField(
                  label: 'Фамилия',
                  controller: _lastNameController,
                ),

                SizedBox(height: 20.h),

                // Email field
                _buildEditableField(
                  label: 'Почта',
                  controller: _emailController,
                ),

                SizedBox(height: 20.h),

                // Phone field
                _buildEditableField(
                  label: 'Номер',
                  controller: _phoneController,
                ),

                SizedBox(height: 20.h),

                // Username (read-only)
                if (_user?.username != null) ...[
                  _buildReadOnlyField(
                    label: 'Имя пользователя',
                    value: _user!.username!,
                  ),
                  SizedBox(height: 20.h),
                ],

                // Token expiration info - СКРЫТО
                // _buildTokenExpirationInfo(),

                SizedBox(height: 80.h),
              ],
            ),
          ),

          // Save button
          if (_isEditMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: _buildSaveButton(),
              ),
            ),
        ],
      ),
    );
  }

  /// Avatar section with name and edit button
  Widget _buildAvatarSection() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF295CDB).withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF295CDB),
              ),
            ),
          ),
        ),

        SizedBox(width: 16.w),

        // Name and email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_firstNameController.text} ${_lastNameController.text}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _emailController.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Edit button
        GestureDetector(
          onTap: _toggleEditMode,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _isEditMode
                  ? const Color(0xFF295CDB).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.edit_outlined,
              size: 24.sp,
              color: _isEditMode
                  ? const Color(0xFF295CDB)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  /// Get user initials for avatar
  String _getInitials() {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;

    if (firstName.isEmpty && lastName.isEmpty) return '?';

    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  /// Editable field with label
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: _isEditMode ? Colors.white : const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isEditMode
                  ? const Color(0xFF295CDB).withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: _isEditMode,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              border: InputBorder.none,
              hintText: label,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Read-only field
  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 20.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Token expiration info
  Widget _buildTokenExpirationInfo() {
    return FutureBuilder<int?>(
      future: TokenStorage.getTimeUntilExpiration(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final seconds = snapshot.data!;
        final minutes = (seconds / 60).floor();
        final hours = (minutes / 60).floor();

        String timeText;
        if (hours > 0) {
          timeText = 'Токен истечет через $hours ч';
        } else if (minutes > 0) {
          timeText = 'Токен истечет через $minutes мин';
        } else {
          timeText = 'Токен истек';
        }

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: hours < 1 ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                hours < 1 ? Icons.warning_amber : Icons.info_outline,
                size: 20.sp,
                color: hours < 1 ? Colors.red.shade600 : Colors.blue.shade600,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: hours < 1 ? Colors.red.shade700 : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF295CDB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Сохранить',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}