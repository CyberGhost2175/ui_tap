import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ProfileScreen - user profile with editable fields
/// Features: Inline editing, Edit mode toggle, Save changes
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Edit mode state
  bool _isEditMode = false;

  // Text controllers for editable fields
  final TextEditingController _firstNameController = TextEditingController(text: 'Victor');
  final TextEditingController _lastNameController = TextEditingController(text: 'Pin');
  final TextEditingController _emailController = TextEditingController(text: 'PinVic@mail.ru');
  final TextEditingController _phoneController = TextEditingController(text: '+7 777 777 77 77');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;

      // If exiting edit mode without saving, reset values
      if (!_isEditMode) {
        _firstNameController.text = 'Victor';
        _lastNameController.text = 'Pin';
        _emailController.text = 'PinVic@mail.ru';
        _phoneController.text = '+7 777 777 77 77';
      }
    });
  }

  /// Save changes
  void _saveChanges() {
    // TODO: Implement save logic to backend
    setState(() {
      _isEditMode = false;
    });

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
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: _isEditMode ? 100.h : 20.h, // Extra padding when save button visible
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

                SizedBox(height: 80.h), // Extra space for save button
              ],
            ),
          ),

          // Save button (appears at bottom when in edit mode)
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
            color: Colors.grey.shade200,
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.rawpixel.com/image_png_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDIzLTAxL3JtNjA5LXNvbGlkaWNvbi13LTAwMi1wLnBuZw.png',
              ),
              fit: BoxFit.cover,
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
                  fontStyle: FontStyle.italic,
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

  /// Editable field with label
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),

        SizedBox(height: 8.h),

        // Input field
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