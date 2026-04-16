import 'package:flutter/material.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class FeedbackFormBottomSheet extends StatefulWidget {
  final int initialRating;
  final String initialComment;
  final Future<void> Function(int rating, String comment) onSubmit;
  final bool isEditing;

  const FeedbackFormBottomSheet({
    super.key,
    required this.initialRating,
    required this.initialComment,
    required this.onSubmit,
    this.isEditing = false,
  });

  @override
  State<FeedbackFormBottomSheet> createState() =>
      _FeedbackFormBottomSheetState();
}

class _FeedbackFormBottomSheetState extends State<FeedbackFormBottomSheet> {
  late final TextEditingController _commentController;
  late int _rating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите оценку от 1 до 5'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(
        _rating,
        _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения отзыва: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildStar(int index) {
    final filled = index <= _rating;

    return IconButton(
      onPressed: _isSaving
          ? null
          : () {
        setState(() {
          _rating = index;
        });
      },
      icon: Icon(
        filled ? Icons.star_rounded : Icons.star_border_rounded,
        size: 34,
        color: filled ? const Color(0xFFF5B301) : AppColors.textSecondary,
      ),
      tooltip: '$index',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.isEditing ? 'Изменить отзыв' : 'Оставить отзыв',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Оцените мероприятие и при желании добавьте комментарий',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => _buildStar(index + 1)),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 6,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: 'Напишите, что вам понравилось или что можно улучшить',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    widget.isEditing ? 'Сохранить изменения' : 'Отправить отзыв',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}