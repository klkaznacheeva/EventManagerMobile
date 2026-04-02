import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/categories/models/category_model.dart';
import 'package:event_manager_app/features/categories/services/category_service.dart';
import 'package:event_manager_app/roles/organizer/models/organizer_event_create_request.dart';
import 'package:event_manager_app/roles/organizer/services/organizer_event_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class OrganizerEventCreateScreen extends StatefulWidget {
  const OrganizerEventCreateScreen({super.key});

  @override
  State<OrganizerEventCreateScreen> createState() =>
      _OrganizerEventCreateScreenState();
}

class _OrganizerEventCreateScreenState
    extends State<OrganizerEventCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  late final OrganizerEventService _organizerEventService;
  late final CategoryService _categoryService;

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;

  bool _isLoading = false;
  bool _isCategoriesLoading = true;

  final List<Map<String, String>> _statuses = const [
    {'value': 'draft', 'label': 'Черновик'},
    {'value': 'published', 'label': 'Опубликовано'},
    {'value': 'cancelled', 'label': 'Отменено'},
  ];

  String _selectedStatus = 'draft';

  @override
  void initState() {
    super.initState();
    _organizerEventService = OrganizerEventService(ApiClient());
    _categoryService = CategoryService(ApiClient());
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки категорий: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isCategoriesLoading = false;
      });
    }
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
      helpText: 'Выберите дату',
      cancelText: 'Отмена',
      confirmText: 'ОК',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: 'Выберите время',
      cancelText: 'Отмена',
      confirmText: 'ОК',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = _formatForApi(result);
  }

  String _formatForApi(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day' 'T' '$hour:$minute:00';
  }

  String _formatForView(String value) {
    try {
      final date = DateTime.parse(value);
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите категорию'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = OrganizerEventCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        status: _selectedStatus,
      );

      await _organizerEventService.createEvent(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мероприятие успешно создано'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания мероприятия: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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
              Icons.add_box_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Новое мероприятие',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Заполните основные данные о мероприятии',
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

  Widget _buildFormCard() {
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Название мероприятия',
                prefixIcon: Icon(
                  Icons.title_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Описание',
                alignLabelWithHint: true,
                prefixIcon: Icon(
                  Icons.notes_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Локация',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_isCategoriesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: AppColors.primary,
                  ),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Статус',
                prefixIcon: Icon(
                  Icons.flag_outlined,
                  color: AppColors.primary,
                ),
              ),
              items: _statuses
                  .map(
                    (status) => DropdownMenuItem(
                  value: status['value'],
                  child: Text(status['label']!),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _startDateController,
              readOnly: true,
              validator: _requiredValidator,
              onTap: () => _pickDateTime(_startDateController),
              decoration: InputDecoration(
                labelText: 'Дата и время начала',
                prefixIcon: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                ),
                hintText: _startDateController.text.isEmpty
                    ? null
                    : _formatForView(_startDateController.text),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _endDateController,
              readOnly: true,
              validator: _requiredValidator,
              onTap: () => _pickDateTime(_endDateController),
              decoration: InputDecoration(
                labelText: 'Дата и время окончания',
                prefixIcon: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                ),
                hintText: _endDateController.text.isEmpty
                    ? null
                    : _formatForView(_endDateController.text),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Создать мероприятие',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Создание мероприятия'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildFormCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}