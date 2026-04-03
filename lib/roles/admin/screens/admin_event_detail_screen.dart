import 'package:flutter/material.dart';

import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/features/events/models/session_model.dart';
import 'package:event_manager_app/roles/admin/services/admin_event_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class AdminEventDetailScreen extends StatefulWidget {
  final String eventId;
  final AdminEventService adminEventService;

  const AdminEventDetailScreen({
    super.key,
    required this.eventId,
    required this.adminEventService,
  });

  @override
  State<AdminEventDetailScreen> createState() => _AdminEventDetailScreenState();
}

class _AdminEventDetailScreenState extends State<AdminEventDetailScreen> {
  late Future<_AdminEventDetailData> _detailFuture;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadData();
  }

  Future<_AdminEventDetailData> _loadData() async {
    final event = await widget.adminEventService.getEventById(widget.eventId);
    final sessions = await widget.adminEventService.getSessionsByEventId(
      widget.eventId,
    );

    return _AdminEventDetailData(
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

  String _eventStatusLabel(EventModel event) {
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
        return 'Требует доработки';
      case 'completed':
        return 'Завершено';
      default:
        return event.status;
    }
  }

  String _sessionStatusLabel(SessionModel session) {
    if (session.statusLabel != null && session.statusLabel!.isNotEmpty) {
      return session.statusLabel!;
    }

    final status = (session.status ?? '').toLowerCase();

    switch (status) {
      case 'draft':
        return 'Черновик';
      case 'pending':
        return 'На проверке';
      case 'reviewed':
        return 'Проверено';
      case 'published':
        return 'Опубликовано';
      case 'needs_edit':
        return 'Требует доработки';
      case 'completed':
        return 'Завершено';
      default:
        return session.status ?? 'Без статуса';
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

  Future<void> _approveEvent() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.adminEventService.markReviewed(widget.eventId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие одобрено'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка одобрения: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectEvent() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Причина доработки'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Введите причину',
              alignLabelWithHint: true,
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Отмена',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.adminEventService.markNeedsEdit(
        eventId: widget.eventId,
        reason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие отправлено на доработку'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка возврата на доработку: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
    }
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
              _eventStatusLabel(event),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
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
          'У этого мероприятия пока нет сессий.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: sessions.map((session) {
        final status = session.status ?? '';

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _sessionStatusLabel(session),
                        style: TextStyle(
                          color: _statusFg(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (session.description != null &&
                  session.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  session.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _buildMetaRow(
                icon: Icons.schedule_rounded,
                label: 'Начало',
                value: _formatDateTime(session.startDate),
              ),
              _buildMetaRow(
                icon: Icons.event_rounded,
                label: 'Окончание',
                value: _formatDateTime(session.endDate),
              ),
              if (session.location != null && session.location!.isNotEmpty)
                _buildMetaRow(
                  icon: Icons.location_on_outlined,
                  label: 'Место',
                  value: session.location!,
                ),
              if (session.type != null && session.type!.isNotEmpty)
                _buildMetaRow(
                  icon: Icons.category_outlined,
                  label: 'Тип',
                  value: session.type!,
                ),
              if (session.ageLimit != null)
                _buildMetaRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Возраст',
                  value: '${session.ageLimit}+',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    if (_isProcessing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _rejectEvent,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('На доработку'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB23A3A),
              side: const BorderSide(color: Color(0xFFE9B1B1)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _approveEvent,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Одобрить'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(_AdminEventDetailData data) {
    final event = data.event;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSectionCard(
            title: 'Информация о мероприятии',
            child: Column(
              children: [
                _buildMetaRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Организатор',
                  value: event.organizerName ?? 'Не указан',
                ),
                _buildMetaRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: event.organizerEmail ?? 'Не указан',
                ),
                _buildMetaRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Дата начала',
                  value: _formatDateTime(event.startDate),
                ),
                _buildMetaRow(
                  icon: Icons.event_available_outlined,
                  label: 'Дата окончания',
                  value: _formatDateTime(event.endDate),
                ),
                if (event.location != null && event.location!.isNotEmpty)
                  _buildMetaRow(
                    icon: Icons.place_outlined,
                    label: 'Локация',
                    value: event.location!,
                  ),
                if (event.categoryName != null && event.categoryName!.isNotEmpty)
                  _buildMetaRow(
                    icon: Icons.local_activity_outlined,
                    label: 'Категория',
                    value: event.categoryName!,
                  ),
                _buildMetaRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Статус',
                  value: _eventStatusLabel(event),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Сессии мероприятия',
            child: _buildSessions(data.sessions),
          ),
          _buildSectionCard(
            title: 'Действия администратора',
            child: _buildActions(),
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
                'Не удалось загрузить детали мероприятия',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Детали мероприятия'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<_AdminEventDetailData>(
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
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              _buildHeader(data.event),
              Expanded(
                child: _buildBody(data),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminEventDetailData {
  final EventModel event;
  final List<SessionModel> sessions;

  const _AdminEventDetailData({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}