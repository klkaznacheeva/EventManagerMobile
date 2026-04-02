import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart' as core;
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/features/events/services/event_service.dart';
import 'package:event_manager_app/features/profile/models/profile_model.dart';
import 'package:event_manager_app/features/profile/services/profile_service.dart';
import 'package:event_manager_app/roles/organizer/screens/organizer_event_detail_screen.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class OrganizerMyEventsScreen extends StatefulWidget {
  const OrganizerMyEventsScreen({super.key});

  @override
  State<OrganizerMyEventsScreen> createState() => _OrganizerMyEventsScreenState();
}

class _OrganizerMyEventsScreenState extends State<OrganizerMyEventsScreen> {
  late final EventService _eventService;
  late final ProfileService _profileService;
  late Future<List<EventModel>> _myEventsFuture;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(core.ApiClient());
    _profileService = ProfileService(core.ApiClient());
    _myEventsFuture = _loadMyEvents();
  }

  Future<List<EventModel>> _loadMyEvents() async {
    final profile = await _profileService.getProfile();
    final events = await _eventService.getEvents();
    return _filterMyEvents(events, profile);
  }

  List<EventModel> _filterMyEvents(
      List<EventModel> events,
      ProfileModel profile,
      ) {
    final myEmail = profile.email.trim().toLowerCase();

    return events.where((event) {
      final organizerEmail = event.organizerEmail?.trim().toLowerCase();
      return organizerEmail != null && organizerEmail == myEmail;
    }).toList();
  }

  void _reload() {
    setState(() {
      _myEventsFuture = _loadMyEvents();
    });
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day.$month.$year • $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  String _statusLabel(EventModel event) {
    if (event.statusLabel != null && event.statusLabel!.isNotEmpty) {
      return event.statusLabel!;
    }

    switch (event.status.toLowerCase()) {
      case 'draft':
        return 'Черновик';
      case 'pending':
        return 'На проверке';
      case 'reviewed':
        return 'Проверено';
      case 'published':
        return 'Опубликовано';
      case 'needs_edit':
        return 'Нужна доработка';
      case 'completed':
        return 'Завершено';
      default:
        return event.status;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return const Color(0xFFDFF3E8);
      case 'reviewed':
        return const Color(0xFFE3EEFF);
      case 'pending':
        return const Color(0xFFFFF4D6);
      case 'needs_edit':
        return const Color(0xFFFCE4E4);
      case 'completed':
        return const Color(0xFFE7E7E7);
      default:
        return AppColors.accent.withValues(alpha: 0.55);
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return const Color(0xFF1E7A46);
      case 'reviewed':
        return const Color(0xFF2E63C8);
      case 'pending':
        return const Color(0xFF9A6A00);
      case 'needs_edit':
        return const Color(0xFFB23A3A);
      case 'completed':
        return const Color(0xFF555555);
      default:
        return AppColors.primary;
    }
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
              Icons.event_note_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Мои мероприятия',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Здесь отображаются все созданные вами мероприятия',
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

  Widget _buildEventCard(EventModel event) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrganizerEventDetailScreen(eventId: event.id),
          ),
        );

        if (!mounted) return;
        _reload();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg(event.status),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _statusLabel(event),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _statusFg(event.status),
                      ),
                    ),
                  ),
                ],
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    text: _formatDate(event.startDate),
                  ),
                  if (event.location != null && event.location!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      text: event.location!,
                    ),
                  if (event.categoryName != null && event.categoryName!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.local_activity_outlined,
                      text: event.categoryName!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${event.participantsCount} участников',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Text(
                    'Открыть',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 18,
                offset: Offset(0, 8),
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
                  color: AppColors.accent.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'У вас пока нет мероприятий',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Создайте первое мероприятие в панели организатора',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 18,
                offset: Offset(0, 8),
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
                  color: AppColors.accent.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Не удалось загрузить мои мероприятия',
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
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reload,
                  child: const Text('Повторить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<EventModel> events) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _reload();
        await _myEventsFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ...events.map(_buildEventCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Мои мероприятия'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildHeader(),
            ),
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _myEventsFuture,
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

                  final events = snapshot.data ?? [];

                  if (events.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildContent(events);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}