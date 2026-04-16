import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/core/storage/user_mode_storage.dart';
import 'package:event_manager_app/features/auth/screens/user_mode_select_screen.dart';
import 'package:event_manager_app/features/profile/services/profile_service.dart';
import 'package:event_manager_app/roles/admin/screens/admin_home_screen.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';
import 'package:event_manager_app/shared/widgets/main_screen.dart';

class RoleRedirectScreen extends StatefulWidget {
  const RoleRedirectScreen({super.key});

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> {
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(ApiClient());
    _redirectByRole();
  }

  Future<void> _redirectByRole() async {
    try {
      final profile = await _profileService.getProfile();

      if (!mounted) return;

      if (profile.isSystem) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminHomeScreen(),
          ),
              (route) => false,
        );
        return;
      }

      final savedMode = await UserModeStorage.getSavedUserMode();

      if (!mounted) return;

      if (savedMode == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const UserModeSelectScreen(),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              initialUserMode: savedMode,
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка определения роли пользователя: $e'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const UserModeSelectScreen(),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}