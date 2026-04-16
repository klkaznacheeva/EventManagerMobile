import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/core/storage/token_storage.dart';
import 'package:event_manager_app/core/storage/user_mode_storage.dart';
import 'package:event_manager_app/features/auth/screens/login_screen.dart';
import 'package:event_manager_app/features/auth/screens/user_mode_select_screen.dart';
import 'package:event_manager_app/features/profile/models/profile_model.dart';
import 'package:event_manager_app/features/profile/screens/change_password_screen.dart';
import 'package:event_manager_app/features/profile/services/profile_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';
import 'package:event_manager_app/features/profile/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? currentUserMode;

  const ProfileScreen({
    super.key,
    this.currentUserMode,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;
  late Future<ProfileModel> _profileFuture;

  bool _isUploadingAvatar = false;
  String? _userMode;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(ApiClient());
    _profileFuture = _profileService.getProfile();
    _initUserMode();
  }

  Future<void> _initUserMode() async {
    if (widget.currentUserMode != null) {
      setState(() {
        _userMode = widget.currentUserMode;
      });
      return;
    }

    final storedMode = await UserModeStorage.getSavedUserMode();

    if (!mounted) return;

    setState(() {
      _userMode = storedMode ?? UserModeStorage.participantMode;
    });
  }

  void _reload() {
    setState(() {
      _profileFuture = _profileService.getProfile();
    });
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    await UserModeStorage.clearUserMode();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> _openEditProfile(ProfileModel profile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile),
      ),
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  Future<void> _openModeSelect() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const UserModeSelectScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _isUploadingAvatar = true;
      });

      await _profileService.uploadAvatar(File(pickedFile.path));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Аватар успешно загружен'),
        ),
      );

      _reload();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки аватара: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }

  String _formatBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Не указана';
    }

    try {
      final date = DateTime.parse(value);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day.$month.$year';
    } catch (_) {
      return value;
    }
  }

  String _buildInitials(ProfileModel profile) {
    final fullName = profile.fullName.trim();

    if (fullName.isEmpty) {
      return 'U';
    }

    final parts = fullName
        .split(' ')
        .where((element) => element.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  String _modeLabel() {
    if (_userMode == UserModeStorage.organizerMode) {
      return 'Организатор';
    }

    return 'Участник';
  }

  Widget _buildAvatar(ProfileModel profile) {
    final initials = _buildInitials(profile);

    return Stack(
      children: [
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.accent,
            backgroundImage: NetworkImage(profile.avatarUrl!),
          )
        else
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.accent,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: _isUploadingAvatar
                  ? const Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
                  : const Icon(
                Icons.edit_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ProfileModel profile) {
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
          _buildAvatar(profile),
          const SizedBox(height: 18),
          Text(
            profile.fullName.isNotEmpty ? profile.fullName : 'Пользователь',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.email,
            style: const TextStyle(
              color: Color(0xFFE8EEF9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Текущий режим: ${_modeLabel()}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ProfileModel profile) {
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
      child: Column(
        children: [
          _ProfileRow(
            icon: Icons.person_outline_rounded,
            label: 'Имя',
            value: profile.firstName.isNotEmpty ? profile.firstName : 'Не указано',
          ),
          _ProfileRow(
            icon: Icons.badge_outlined,
            label: 'Отчество',
            value: profile.secondName?.isNotEmpty == true
                ? profile.secondName!
                : 'Не указано',
          ),
          _ProfileRow(
            icon: Icons.account_box_outlined,
            label: 'Фамилия',
            value: profile.lastName?.isNotEmpty == true
                ? profile.lastName!
                : 'Не указана',
          ),
          _ProfileRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: profile.email,
          ),
          _ProfileRow(
            icon: Icons.phone_outlined,
            label: 'Телефон',
            value: profile.phone?.isNotEmpty == true
                ? profile.phone!
                : 'Не указан',
          ),
          _ProfileRow(
            icon: Icons.cake_outlined,
            label: 'Дата рождения',
            value: _formatBirthDate(profile.birthDate),
          ),
          _ProfileRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Режим',
            value: _modeLabel(),
          ),
          _ProfileRow(
            icon: Icons.verified_user_outlined,
            label: 'Системный',
            value: profile.isSystem ? 'Да' : 'Нет',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ProfileModel profile) {
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
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openEditProfile(profile),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Редактировать профиль'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openModeSelect,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Сменить режим'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Обновить профиль'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Сменить пароль'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Выйти'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Не удалось загрузить профиль',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _reload,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(ProfileModel profile) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _reload();
        await _profileFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(profile),
          const SizedBox(height: 20),
          _buildInfoCard(profile),
          const SizedBox(height: 16),
          _buildActions(profile),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<ProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error!);
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _buildErrorState('Данные профиля не получены');
          }

          return _buildLoadedState(profile);
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}