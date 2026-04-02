import 'package:flutter/material.dart';

import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/roles/organizer/models/organizer_event_create_request.dart';
import 'package:event_manager_app/roles/organizer/services/organizer_event_service.dart';
import 'package:event_manager_app/shared/theme/app_colors.dart';

class OrganizerEventEditScreen extends StatefulWidget {
  final EventModel event;

  const OrganizerEventEditScreen({
    super.key,
    required this.event,
  });

  @override
  State<OrganizerEventEditScreen> createState() =>
      _OrganizerEventEditScreenState();
}

class _OrganizerEventEditScreenState
    extends State<OrganizerEventEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final OrganizerEventService _service;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _startController;
  late TextEditingController _endController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _service = OrganizerEventService(ApiClient());

    final e = widget.event;

    _titleController = TextEditingController(text: e.title);
    _descriptionController =
        TextEditingController(text: e.description ?? '');
    _locationController = TextEditingController(text: e.location ?? '');
    _startController = TextEditingController(text: e.startDate);
    _endController = TextEditingController(text: e.endDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      v == null || v.isEmpty ? 'Обязательное поле' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = OrganizerEventCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: widget.event.categoryId ?? '',
        startDate: _startController.text,
        endDate: _endController.text,
        location: _locationController.text,
        status: widget.event.status,
      );

      await _service.updateEvent(
        eventId: widget.event.id,
        request: request,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мероприятие обновлено')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Редактирование'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                validator: _required,
                decoration: _dec('Название', Icons.title),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: _dec('Описание', Icons.notes),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: _dec('Локация', Icons.location_on),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startController,
                validator: _required,
                decoration: _dec('Начало', Icons.schedule),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endController,
                validator: _required,
                decoration: _dec('Окончание', Icons.event),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}