import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/features/events/models/session_model.dart';
import 'package:event_manager_app/features/events/services/event_service.dart';
import 'package:event_manager_app/roles/organizer/screens/organizer_event_edit_screen.dart';
import 'package:event_manager_app/roles/organizer/screens/organizer_session_create_screen.dart';
import 'package:event_manager_app/roles/organizer/services/organizer_event_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class OrganizerEventDetailScreen extends StatefulWidget {
  final String eventId;

  const OrganizerEventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<OrganizerEventDetailScreen> createState() =>
      _OrganizerEventDetailScreenState();
}

class _OrganizerEventDetailScreenState
    extends State<OrganizerEventDetailScreen> {
  late final EventService _eventService;
  late final OrganizerEventService _organizerEventService;
  late Future<_OrganizerEventDetailData> _detailFuture;

  bool _isStatusLoading = false;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(ApiClient());
    _organizerEventService = OrganizerEventService(ApiClient());
    _detailFuture = _loadData();
  }

  Future<_OrganizerEventDetailData> _loadData() async {
    final event = await _eventService.getEventById(widget.eventId);
    final sessions = await _eventService.getSessionsByEventId(widget.eventId);

    return _OrganizerEventDetailData(
      event: event,
      sessions: sessions,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _detailFuture = _loadData();
    });
    await _detailFuture;
  }

  Future<void> _openCreateSession() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerSessionCreateScreen(eventId: widget.eventId),
      ),
    );

    if (!mounted) return;
    await _reload();
  }

  Future<void> _openEditEvent(EventModel event) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerEventEditScreen(event: event),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _reload();
    }
  }

  Future<void> _sendToReview(EventModel event) async {
    setState(() {
      _isStatusLoading = true;
    });

    try {
      await _organizerEventService.sendToReview(
        eventId: widget.eventId,
        event: event,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие отправлено на проверку'),
        ),
      );

      await _reload();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки на проверку: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isStatusLoading = false;
      });
    }
  }

  Future<void> _publishEvent(EventModel event) async {
    setState(() {
      _isStatusLoading = true;
    });

    try {
      await _organizerEventService.publishEvent(
        eventId: widget.eventId,
        event: event,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие опубликовано'),
        ),
      );

      await _reload();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка публикации: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isStatusLoading = false;
      });
    }
  }

  String _formatDateTime(String value) {
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
        return 'Требует редактирования';
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

  Widget _buildStatusAction(EventModel event) {
    if (_isStatusLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    final status = event.status.toLowerCase();

    if (status == 'draft' || status == 'needs_edit') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openEditEvent(event),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Редактировать'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendToReview(event),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Отправить на проверку'),
            ),
          ),
        ],
      );
    }

    if (status == 'reviewed') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openEditEvent(event),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Редактировать'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _publishEvent(event),
              icon: const Icon(Icons.public_rounded),
              label: const Text('Опубликовать'),
            ),
          ),
        ],
      );
    }

    if (status == 'pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Мероприятие находится на проверке администратора',
          style: TextStyle(
            color: Color(0xFF8A6400),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (status == 'published') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openEditEvent(event),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Редактировать'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF3E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Мероприятие уже опубликовано',
              style: TextStyle(
                color: Color(0xFF1E7A46),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader(EventModel event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _statusBg(event.status),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _statusLabel(event),
              style: TextStyle(
                color: _statusFg(event.status),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description!,
              style: const TextStyle(
                color: Color(0xFFE8EEF9),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TopChip(
                icon: Icons.calendar_today_rounded,
                text: _formatDateTime(event.startDate),
              ),
              _TopChip(
                icon: Icons.event_available_rounded,
                text: _formatDateTime(event.endDate),
              ),
              if (event.location != null && event.location!.isNotEmpty)
                _TopChip(
                  icon: Icons.location_on_outlined,
                  text: event.location!,
                ),
              if (event.categoryName != null && event.categoryName!.isNotEmpty)
                _TopChip(
                  icon: Icons.local_activity_outlined,
                  text: event.categoryName!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
            width: 95,
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

  Widget _buildSessions(List<SessionModel> sessions) {
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Сессии ещё не добавлены.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: sessions.map((session) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (session.description != null &&
                  session.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  session.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SessionChip(
                    icon: Icons.schedule_rounded,
                    text: _formatDateTime(session.startDate),
                  ),
                  _SessionChip(
                    icon: Icons.event_available_rounded,
                    text: _formatDateTime(session.endDate),
                  ),
                  if (session.location != null && session.location!.isNotEmpty)
                    _SessionChip(
                      icon: Icons.location_on_outlined,
                      text: session.location!,
                    ),
                  if (session.type != null && session.type!.isNotEmpty)
                    _SessionChip(
                      icon: Icons.sell_outlined,
                      text: session.type!,
                    ),
                  if (session.ageLimit != null)
                    _SessionChip(
                      icon: Icons.person_outline_rounded,
                      text: '${session.ageLimit}+',
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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
                'Не удалось загрузить мероприятие',
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

  Widget _buildLoadedState(_OrganizerEventDetailData data) {
    final event = data.event;
    final sessions = data.sessions;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(event),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              children: [
                _buildSectionCard(
                  title: 'Действия',
                  child: _buildStatusAction(event),
                ),
                _buildSectionCard(
                  title: 'Информация о мероприятии',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${event.participantsCount} участников',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow(
                        icon: Icons.schedule_rounded,
                        label: 'Начало',
                        value: _formatDateTime(event.startDate),
                      ),
                      _buildMetaRow(
                        icon: Icons.event_available_rounded,
                        label: 'Окончание',
                        value: _formatDateTime(event.endDate),
                      ),
                      if (event.location != null && event.location!.isNotEmpty)
                        _buildMetaRow(
                          icon: Icons.location_on_outlined,
                          label: 'Локация',
                          value: event.location!,
                        ),
                      if (event.categoryName != null &&
                          event.categoryName!.isNotEmpty)
                        _buildMetaRow(
                          icon: Icons.local_activity_outlined,
                          label: 'Категория',
                          value: event.categoryName!,
                        ),
                      _buildMetaRow(
                        icon: Icons.flag_outlined,
                        label: 'Статус',
                        value: _statusLabel(event),
                      ),
                    ],
                  ),
                ),
                _buildSectionCard(
                  title: 'Сессии мероприятия',
                  trailing: ElevatedButton.icon(
                    onPressed: _openCreateSession,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Добавить'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: _buildSessions(sessions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Карточка мероприятия'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<_OrganizerEventDetailData>(
        future: _detailFuture,
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

          final data = snapshot.data;
          if (data == null) {
            return _buildErrorState('Данные не получены');
          }

          return _buildLoadedState(data);
        },
      ),
    );
  }
}

class _OrganizerEventDetailData {
  final EventModel event;
  final List<SessionModel> sessions;

  _OrganizerEventDetailData({
    required this.event,
    required this.sessions,
  });
}

class _TopChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TopChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SessionChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
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