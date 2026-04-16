import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/features/events/models/session_model.dart';
import 'package:event_manager_app/features/events/services/event_service.dart';
import 'package:event_manager_app/features/feedback/models/feedback_model.dart';
import 'package:event_manager_app/features/feedback/services/feedback_service.dart';
import 'package:event_manager_app/features/feedback/widgets/feedback_form_bottom_sheet.dart';
import 'package:event_manager_app/features/profile/models/profile_model.dart';
import 'package:event_manager_app/features/profile/services/profile_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late final EventService _eventService;
  late final FeedbackService _feedbackService;
  late final ProfileService _profileService;
  late Future<_EventDetailData> _detailFuture;

  bool _isJoinLoading = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _eventService = EventService(apiClient);
    _feedbackService = FeedbackService(apiClient);
    _profileService = ProfileService(apiClient);
    _detailFuture = _loadData();
  }

  Future<_EventDetailData> _loadData() async {
    final profile = await _profileService.getProfile();
    final event = await _eventService.getEventById(widget.eventId);
    final sessions = await _eventService.getSessionsByEventId(widget.eventId);

    final organizerEmail = event.organizerEmail?.trim().toLowerCase();
    final currentEmail = profile.email.trim().toLowerCase();
    final isOrganizer = organizerEmail != null && organizerEmail == currentEmail;
    final isCompleted = _isEventCompleted(event);

    FeedbackModel? myFeedback;
    if (event.isParticipant && !isOrganizer && isCompleted) {
      myFeedback = await _feedbackService.getMyFeedback(widget.eventId);
    }

    return _EventDetailData(
      event: event,
      sessions: sessions,
      profile: profile,
      myFeedback: myFeedback,
      isOrganizer: isOrganizer,
      isCompleted: isCompleted,
    );
  }

  void _reload() {
    setState(() {
      _detailFuture = _loadData();
    });
  }

  bool _isEventCompleted(EventModel event) {
    try {
      final endDate = DateTime.parse(event.endDate).toUtc();
      return endDate.isBefore(DateTime.now().toUtc());
    } catch (_) {
      return false;
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

   Future<void> _joinEvent(EventModel event) async {
    if (_isEventCompleted(event)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись недоступна: мероприятие уже завершено'),
        ),
      );
      return;
    }

    setState(() {
      _isJoinLoading = true;
    });

    try {
      await _eventService.joinEvent(widget.eventId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы успешно записались на мероприятие'),
        ),
      );

      _reload();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка записи: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isJoinLoading = false;
      });
    }
  }

  Future<void> _openFeedbackSheet({
    required bool isEditing,
    FeedbackModel? feedback,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FeedbackFormBottomSheet(
          initialRating: feedback?.rating ?? 5,
          initialComment: feedback?.comment ?? '',
          isEditing: isEditing,
          onSubmit: (rating, comment) async {
            if (isEditing) {
              await _feedbackService.updateFeedback(
                eventId: widget.eventId,
                rating: rating,
                comment: comment,
              );
            } else {
              await _feedbackService.createFeedback(
                eventId: widget.eventId,
                rating: rating,
                comment: comment,
              );
            }
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Отзыв обновлён' : 'Отзыв успешно отправлен',
          ),
        ),
      );

      _reload();
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Мероприятие',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  Widget _buildSessionsSection(List<SessionModel> sessions) {
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
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SessionInfoChip(
                    icon: Icons.schedule_rounded,
                    text: _formatDateTime(session.startDate),
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

  Widget _buildParticipantSection(_EventDetailData data) {
    final event = data.event;

     if (data.isCompleted) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'Мероприятие уже прошло, запись недоступна.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

    if (data.isOrganizer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Вы являетесь организатором этого мероприятия.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (event.isParticipant) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFDFF3E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF1E7A46),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Вы уже записаны на это мероприятие',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E7A46),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (event.status.toLowerCase() != 'published') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Запись доступна только для опубликованных мероприятий.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isJoinLoading ? null : () => _joinEvent(event),
        icon: _isJoinLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.how_to_reg_rounded),
        label: Text(
          _isJoinLoading ? 'Запись...' : 'Записаться на мероприятие',
        ),
      ),
    );
  }

  Widget _buildFeedbackStars(int rating) {
    return Row(
      children: List.generate(
        5,
            (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 22,
          color: index < rating
              ? const Color(0xFFF5B301)
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(_EventDetailData data) {
    if (data.isOrganizer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Организатор не может оставлять отзыв на собственное мероприятие.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!data.event.isParticipant) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Оставить отзыв может только пользователь, записанный на мероприятие.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!data.isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Оставить отзыв можно после завершения мероприятия.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final feedback = data.myFeedback;

    if (feedback == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openFeedbackSheet(isEditing: false),
          icon: const Icon(Icons.rate_review_rounded),
          label: const Text('Оставить отзыв'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeedbackStars(feedback.rating),
        const SizedBox(height: 12),
        Text(
          feedback.comment?.trim().isNotEmpty == true
              ? feedback.comment!.trim()
              : 'Комментарий не добавлен',
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openFeedbackSheet(
              isEditing: true,
              feedback: feedback,
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Изменить отзыв'),
          ),
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

  Widget _buildLoadedState(_EventDetailData data) {
    final event = data.event;
    final sessions = data.sessions;

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
                  title: 'Участие',
                  child: _buildParticipantSection(data),
                ),
                _buildSectionCard(
                  title: 'Обратная связь',
                  child: _buildFeedbackSection(data),
                ),
                _buildSectionCard(
                  title: 'Сессии мероприятия',
                  child: _buildSessionsSection(sessions),
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
      body: FutureBuilder<_EventDetailData>(
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

class _EventDetailData {
  final EventModel event;
  final List<SessionModel> sessions;
  final ProfileModel profile;
  final FeedbackModel? myFeedback;
  final bool isOrganizer;
  final bool isCompleted;

  _EventDetailData({
    required this.event,
    required this.sessions,
    required this.profile,
    required this.myFeedback,
    required this.isOrganizer,
    required this.isCompleted,
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