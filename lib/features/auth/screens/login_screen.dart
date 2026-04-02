import 'package:event_manager_app/features/auth/screens/role_redirect_screen.dart';
import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/core/storage/token_storage.dart';
import 'package:event_manager_app/features/auth/models/login_request.dart';
import 'package:event_manager_app/features/auth/screens/register_screen.dart';
import 'package:event_manager_app/features/auth/services/auth_service.dart';
import 'package:event_manager_app/features/events/screens/event_list_screen.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

import '../../../shared/widgets/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiClient());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final response = await _authService.login(request);
      await TokenStorage.saveToken(response.accessToken);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вход выполнен успешно'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleRedirectScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка входа: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    return null;
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Добро пожаловать',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Войдите, чтобы смотреть мероприятия и участвовать в них',
            style: TextStyle(
              color: Color(0xFFE8EEF9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: _requiredValidator,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Войти',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                'Нет аккаунта? Зарегистрироваться',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildFormCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}