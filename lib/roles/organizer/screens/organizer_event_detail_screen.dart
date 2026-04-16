import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/features/events/models/session_model.dart';
import 'package:event_manager_app/features/events/services/event_service.dart';
import 'package:event_manager_app/features/feedback/models/feedback_summary_model.dart';
import 'package:event_manager_app/features/feedback/services/feedback_service.dart';
import 'package:event_manager_app/roles/organizer/screens/organizer_event_edit_screen.dart';
import 'package:event_manager_app/roles/organizer/screens/organizer_event_feedbacks_screen.dart';
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

  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _eventService = EventService(apiClient);
    _organizerEventService = OrganizerEventService(apiClient);
    _detailFuture = _loadData();
  }

  Future<_OrganizerEventDetailData> _loadData() async {
    final event = await _eventService.getEventById(widget.eventId);
    final sessions = await _eventService.getSessionsByEventId(widget.eventId);

    FeedbackSummaryModel summary;

    try {
      summary =
      await FeedbackService(ApiClient()).getEventFeedbackSummary(widget.eventId);
    } catch (_) {
      summary = FeedbackSummaryModel(
        eventId: widget.eventId,
        totalFeedbacks: 0,
        averageRating: 0,
        breakdown: const [],
      );
    }

    return _OrganizerEventDetailData(
      event: event,
      sessions: sessions,
      summary: summary,
    );
  }

  void _reload() {
    setState(() {
      _detailFuture = _loadData();
    });
  }

  Future<void> _openEditScreen(EventModel event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerEventEditScreen(event: event),
      ),
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  Future<void> _openCreateSessionScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerSessionCreateScreen(eventId: widget.eventId),
      ),
    );

    if (result == true && mounted) {
      _reload();
      return;
    }

    if (mounted) {
      _reload();
    }
  }

  Future<void> _openEditSessionScreen(SessionModel session) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerSessionCreateScreen(
          eventId: widget.eventId,
          session: session,
        ),
      ),
    );

    if (result == true && mounted) {
      _reload();
      return;
    }

    if (mounted) {
      _reload();
    }
  }

  Future<void> _openFeedbacksScreen(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerEventFeedbacksScreen(
          eventId: event.id,
          eventTitle: event.title,
        ),
      ),
    );

    if (!mounted) return;
    _reload();
  }

  Future<void> _sendToReview(EventModel event) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await _organizerEventService.sendToReview(
        eventId: event.id,
        event: event,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие отправлено на проверку'),
        ),
      );

      _reload();
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
        _isActionLoading = false;
      });
    }
  }

  Future<void> _publishEvent(EventModel event) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await _organizerEventService.publishEvent(eventId: event.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие опубликовано'),
        ),
      );

      _reload();
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
        _isActionLoading = false;
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

  Widget _buildTopSection(EventModel event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ],
          ),
          const SizedBox(height: 18),
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
                color: Color(0xFFEAF0FF),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TopInfoChip(
                icon: Icons.calendar_today_rounded,
                text: _formatDateTime(event.startDate),
              ),
              if (event.location != null && event.location!.isNotEmpty)
                _TopInfoChip(
                  icon: Icons.location_on_outlined,
                  text: event.location!,
                ),
              if (event.categoryName != null && event.categoryName!.isNotEmpty)
                _TopInfoChip(
                  icon: Icons.local_activity_outlined,
                  text: event.categoryName!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EventModel event) {
    final status = event.status.toLowerCase();

    final canEdit = status != 'completed';
    final canSendToReview = status == 'draft' || status == 'needs_edit';
    final canPublish = status == 'reviewed';
    final canAddSession = status != 'completed';

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
          const Text(
            'Действия',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (canEdit)
                OutlinedButton.icon(
                  onPressed:
                  _isActionLoading ? null : () => _openEditScreen(event),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Редактировать'),
                ),
              if (canSendToReview)
                ElevatedButton.icon(
                  onPressed:
                  _isActionLoading ? null : () => _sendToReview(event),
                  icon: const Icon(Icons.rate_review_rounded),
                  label: Text(
                    _isActionLoading
                        ? 'Отправка...'
                        : 'Отправить на проверку',
                  ),
                ),
              if (canPublish)
                ElevatedButton.icon(
                  onPressed:
                  _isActionLoading ? null : () => _publishEvent(event),
                  icon: const Icon(Icons.public_rounded),
                  label: Text(
                    _isActionLoading ? 'Публикация...' : 'Опубликовать',
                  ),
                ),
            ],
          ),
          if (!canEdit && !canAddSession && !canSendToReview && !canPublish) ...[
            const SizedBox(height: 4),
            const Text(
              'Для текущего статуса дополнительных действий нет.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
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

  Widget _buildSessionsSection(
      List<SessionModel> sessions, {
        required bool canManageSessions,
      }) {
    if (sessions.isEmpty) {
      return const Text(
        'Для этого мероприятия пока нет сессий.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
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
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (canManageSessions)
                    IconButton(
                      onPressed: _isActionLoading
                          ? null
                          : () => _openEditSessionScreen(session),
                      tooltip: 'Редактировать сессию',
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                ],
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
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SessionInfoChip(
                    icon: Icons.schedule_rounded,
                    text: _formatDateTime(session.startDate),
                  ),
                  if (session.endDate.isNotEmpty)
                    _SessionInfoChip(
                      icon: Icons.event_available_rounded,
                      text: _formatDateTime(session.endDate),
                    ),
                  if (session.location != null && session.location!.isNotEmpty)
                    _SessionInfoChip(
                      icon: Icons.location_on_outlined,
                      text: session.location!,
                    ),
                  if (session.type != null && session.type!.isNotEmpty)
                    _SessionInfoChip(
                      icon: Icons.sell_outlined,
                      text: session.type!,
                    ),
                  if (session.ageLimit != null)
                    _SessionInfoChip(
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

  Widget _buildRatingStars(int rating, {double size = 18}) {
    return Row(
      children: List.generate(
        5,
            (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: index < rating
              ? const Color(0xFFF5B301)
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFeedbackSummary(FeedbackSummaryModel summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Средняя оценка',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Отзывов',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${summary.totalFeedbacks}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (summary.breakdown.isNotEmpty)
          Column(
            children: summary.breakdown.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${item.rating}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF5B301),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: summary.totalFeedbacks == 0
                              ? 0
                              : item.count / summary.totalFeedbacks,
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${item.count}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
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
                'Не удалось загрузить карточку мероприятия',
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
    final summary = data.summary;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _reload();
        await _detailFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildTopSection(event),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              children: [
                _buildActionButtons(event),
                _buildSectionCard(
                  title: 'Информация о мероприятии',
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
                      if (event.organizerName != null &&
                          event.organizerName!.isNotEmpty)
                        _buildMetaRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Организатор',
                          value: event.organizerName!,
                        ),
                      _buildMetaRow(
                        icon: Icons.people_alt_outlined,
                        label: 'Участники',
                        value: '${event.participantsCount}',
                      ),
                    ],
                  ),
                ),
                _buildSectionCard(
                  title: 'Сессии мероприятия',
                  trailing: TextButton.icon(
                    onPressed: _isActionLoading ? null : _openCreateSessionScreen,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                  child: _buildSessionsSection(
                    sessions,
                    canManageSessions: event.status.toLowerCase() != 'completed',
                  ),
                ),
                _buildSectionCard(
                  title: 'Отзывы участников',
                  trailing: TextButton.icon(
                    onPressed: () => _openFeedbacksScreen(event),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Открыть все'),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeedbackSummary(summary),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.reviews_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                summary.totalFeedbacks > 0
                                    ? 'Всего отзывов: ${summary.totalFeedbacks}. Откройте отдельную страницу для просмотра полного списка.'
                                    : 'Отзывов пока нет. Когда участники оставят оценки, они будут доступны на отдельной странице.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
  final FeedbackSummaryModel summary;

  _OrganizerEventDetailData({
    required this.event,
    required this.sessions,
    required this.summary,
  });
}

class _TopInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TopInfoChip({
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

class _SessionInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SessionInfoChip({
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}