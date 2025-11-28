import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/jwt_decoder.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/token_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle registration with REAL API
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ⬅️ ИСПРАВЛЕНО: передаем все параметры
      final result = await _authRepository.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (result.error != null) {
        // ❌ Ошибка от сервера
        print('❌ Registration error: ${result.error}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else if (result.response != null) {
        // ✅ Успешная регистрация!
        final response = result.response!;

        print('✅ Registration successful!');
        print('Token: ${response.accessToken.substring(0, 20)}...');
        print('Expires in: ${response.expiresIn} seconds');

        // Сохраняем токен
        await TokenStorage.saveToken(
          accessToken: response.accessToken,
          tokenType: response.tokenType,
          expiresIn: response.expiresIn,
        );

        // Декодируем JWT и извлекаем данные пользователя
        print('🔍 Decoding JWT token...');
        final userData = JwtDecoder.extractUserData(response.accessToken);

        print('👤 User data from JWT:');
        print('Email: ${userData['email']}');
        print('First Name: ${userData['firstName']}');
        print('Last Name: ${userData['lastName']}');
        print('Username: ${userData['username']}');

        // Сохраняем данные пользователя
        await TokenStorage.saveUserData(
          email: userData['email'] ?? _emailController.text.trim(),
          firstName: userData['firstName'] ?? _firstNameController.text.trim(),
          lastName: userData['lastName'] ?? _lastNameController.text.trim(),
          username: userData['username'] ?? _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        print('💾 Token and user data saved to storage');

        if (!mounted) return;

        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Регистрация успешна! Добро пожаловать!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Переходим на главную
        context.go('/home');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Непредвиденная ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Логотип
                Center(
                  child: SvgPicture.asset(
                    'assets/icons/Logo.svg',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 40),

                // Имя
                _buildLabel("Имя"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _firstNameController,
                  hintText: "Введите имя",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Фамилия
                _buildLabel("Фамилия"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _lastNameController,
                  hintText: "Введите фамилию",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите фамилию';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username
                _buildLabel("Имя пользователя"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _usernameController,
                  hintText: "Введите имя пользователя",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя пользователя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Почта
                _buildLabel("Почта"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _emailController,
                  hintText: "Введите почту",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!value.contains('@')) {
                      return 'Некорректный email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Телефон
                _buildLabel("Номер телефона"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _phoneController,
                  hintText: "+7 (___) ___-__-__",
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите номер телефона';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Пароль
                _buildLabel("Пароль"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _passwordController,
                  hintText: "Придумайте пароль",
                  obscure: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть минимум 6 символов';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 30),

                // Кнопка регистрации
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF295CDB),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Зарегистрировать',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Уже есть аккаунт
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Есть аккаунт? ",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        "Войти",
                        style: TextStyle(
                          color: Color(0xFF295CDB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: suffixIcon,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}