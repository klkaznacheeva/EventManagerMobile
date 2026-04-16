import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/feedback/models/feedback_model.dart';
import 'package:event_manager_app/features/feedback/models/feedback_summary_model.dart';
import 'package:event_manager_app/features/feedback/services/feedback_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class OrganizerEventFeedbacksScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const OrganizerEventFeedbacksScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<OrganizerEventFeedbacksScreen> createState() =>
      _OrganizerEventFeedbacksScreenState();
}

class _OrganizerEventFeedbacksScreenState
    extends State<OrganizerEventFeedbacksScreen> {
  late final FeedbackService _feedbackService;
  late Future<_OrganizerEventFeedbacksData> _feedbacksFuture;

  @override
  void initState() {
    super.initState();
    _feedbackService = FeedbackService(ApiClient());
    _feedbacksFuture = _loadData();
  }

  Future<_OrganizerEventFeedbacksData> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        _feedbackService.getEventFeedbackSummary(widget.eventId),
        _feedbackService.getEventFeedbacks(widget.eventId),
      ]);

      return _OrganizerEventFeedbacksData(
        summary: results[0] as FeedbackSummaryModel,
        feedbacks: results[1] as List<FeedbackModel>,
      );
    } catch (_) {
      return const _OrganizerEventFeedbacksData(
        summary: FeedbackSummaryModel(
          eventId: '',
          totalFeedbacks: 0,
          averageRating: 0,
          breakdown: [],
        ),
        feedbacks: [],
      );
    }
  }

  void _reload() {
    setState(() {
      _feedbacksFuture = _loadData();
    });
  }

  String _formatFeedbackDate(String value) {
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

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 4),
          child: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 20,
            color: const Color(0xFFF5B301),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.reviews_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Отзывы участников',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.eventTitle,
              style: const TextStyle(
                color: Color(0xFFEAF0FF),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
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

  Widget _buildFeedbackSummary(FeedbackSummaryModel summary) {
    final breakdownMap = {
      for (final item in summary.breakdown) item.rating: item.count,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'из 5',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRatingStars(summary.averageRating.round().clamp(0, 5)),
        const SizedBox(height: 10),
        Text(
          'Всего отзывов: ${summary.totalFeedbacks}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = breakdownMap[rating] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$rating★',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: summary.totalFeedbacks == 0
                          ? 0
                          : count / summary.totalFeedbacks,
                      minHeight: 10,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.35),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 26,
                  child: Text(
                    '$count',
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
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Пока отзывов нет',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Когда участники завершённого мероприятия оставят оценки и комментарии, они появятся здесь.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(List<FeedbackModel> feedbacks) {
    if (feedbacks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: feedbacks.map((feedback) {
        final authorName = feedback.author?.fullName.trim().isNotEmpty == true
            ? feedback.author!.fullName
            : 'Пользователь';

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatFeedbackDate(feedback.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRatingStars(feedback.rating),
              const SizedBox(height: 10),
              Text(
                feedback.comment?.trim().isNotEmpty == true
                    ? feedback.comment!.trim()
                    : 'Комментарий не добавлен',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadedState(_OrganizerEventFeedbacksData data) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _reload();
        await _feedbacksFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              children: [
                _buildSectionCard(
                  title: 'Статистика отзывов',
                  child: _buildFeedbackSummary(data.summary),
                ),
                _buildSectionCard(
                  title: 'Все отзывы',
                  child: _buildFeedbackList(data.feedbacks),
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
      body: FutureBuilder<_OrganizerEventFeedbacksData>(
        future: _feedbacksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Не удалось загрузить отзывы',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
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
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }

          return _buildLoadedState(data);
        },
      ),
    );
  }
}

class _OrganizerEventFeedbacksData {
  final FeedbackSummaryModel summary;
  final List<FeedbackModel> feedbacks;

  const _OrganizerEventFeedbacksData({
    required this.summary,
    required this.feedbacks,
  });
}