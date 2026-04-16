import 'package:flutter/material.dart';

import 'package:event_manager_app/core/storage/user_mode_storage.dart';
import 'package:event_manager_app/features/events/screens/event_list_screen.dart';
import 'package:event_manager_app/features/profile/screens/profile_screen.dart';
import 'package:event_manager_app/roles/organizer/screens/organizer_home_screen.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  final String initialUserMode;

  const MainScreen({
    super.key,
    required this.initialUserMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  bool get _isOrganizerMode =>
      widget.initialUserMode == UserModeStorage.organizerMode;

  List<Widget> _buildScreens() {
    if (_isOrganizerMode) {
      return [
        const OrganizerHomeScreen(),
        ProfileScreen(currentUserMode: widget.initialUserMode),
      ];
    }

    return [
      EventListScreen(userMode: widget.initialUserMode),
      ProfileScreen(currentUserMode: widget.initialUserMode),
    ];
  }

  List<BottomNavigationBarItem> _buildItems() {
    if (_isOrganizerMode) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_customize_rounded),
          label: 'Панель',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Профиль',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.event_rounded),
        label: 'Мероприятия',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Профиль',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();
    final items = _buildItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          items: items,
        ),
      ),
    );
  }
}