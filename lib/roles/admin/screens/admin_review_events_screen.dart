import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/roles/admin/screens/admin_event_detail_screen.dart';
import 'package:event_manager_app/roles/admin/services/admin_event_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class AdminReviewEventsScreen extends StatefulWidget {
  const AdminReviewEventsScreen({super.key});

  @override
  State<AdminReviewEventsScreen> createState() => _AdminReviewEventsScreenState();
}

class _AdminReviewEventsScreenState extends State<AdminReviewEventsScreen> {
  late final AdminEventService _adminEventService;
  late Future<List<EventModel>> _eventsFuture;

  String? _processingEventId;

  @override
  void initState() {
    super.initState();
    _adminEventService = AdminEventService(ApiClient());
    _eventsFuture = _adminEventService.getPendingEvents();
  }

  void _reload() {
    setState(() {
      _eventsFuture = _adminEventService.getPendingEvents();
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

  Future<void> _openEventDetail(EventModel event) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEventDetailScreen(
          eventId: event.id,
          adminEventService: _adminEventService,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      _reload();
    }
  }

  Future<void> _approveEvent(EventModel event) async {
    setState(() {
      _processingEventId = event.id;
    });

    try {
      await _adminEventService.markReviewed(event.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие одобрено'),
        ),
      );

      _reload();
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
        _processingEventId = null;
      });
    }
  }

  Future<void> _rejectEvent(EventModel event) async {
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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Отмена',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) {
                  return;
                }
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
      _processingEventId = event.id;
    });

    try {
      await _adminEventService.markNeedsEdit(
        eventId: event.id,
        reason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие отправлено на доработку'),
        ),
      );

      _reload();
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
        _processingEventId = null;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              Icons.rule_folder_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Мероприятия на проверке',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Откройте мероприятие, просмотрите детали и примите решение',
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
    final isProcessing = _processingEventId == event.id;

    return Container(
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
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
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
                if (event.organizerName != null && event.organizerName!.isNotEmpty)
                  _InfoChip(
                    icon: Icons.person_outline_rounded,
                    text: event.organizerName!,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openEventDetail(event),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Открыть детали'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectEvent(event),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('На доработку'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB23A3A),
                            side: const BorderSide(color: Color(0xFFE9B1B1)),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveEvent(event),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Одобрить'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
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
                'Не удалось загрузить мероприятия',
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
                  Icons.task_alt_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Нет мероприятий на проверке',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Все мероприятия уже обработаны',
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

  Widget _buildContent(List<EventModel> events) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _reload();
        await _eventsFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _eventsFuture,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
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