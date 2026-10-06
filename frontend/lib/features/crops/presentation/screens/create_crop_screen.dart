import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/crop_create_request.dart';
import '../state/crop_controller.dart';
import '../state/crop_state.dart';

class CreateCropScreen extends ConsumerStatefulWidget {
  const CreateCropScreen({required this.farmId, super.key});

  final String farmId;

  @override
  ConsumerState<CreateCropScreen> createState() => _CreateCropScreenState();
}

class _CreateCropScreenState extends ConsumerState<CreateCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _seasonController = TextEditingController();
  String _status = 'active';
  DateTime? _sowingDate;
  DateTime? _harvestDate;

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool sowing}) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: (sowing ? _sowingDate : _harvestDate) ?? DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (sowing) {
        _sowingDate = selected;
      } else {
        _harvestDate = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        ref.read(cropControllerProvider) is CropCreating) {
      return;
    }

    final success = await ref
        .read(cropControllerProvider.notifier)
        .createCrop(
          widget.farmId,
          CropCreateRequest(
            cropName: _nameController.text.trim(),
            variety: _varietyController.text.trim().isEmpty
                ? null
                : _varietyController.text.trim(),
            sowingDate: _sowingDate,
            expectedHarvestDate: _harvestDate,
            season: _seasonController.text.trim(),
            status: _status,
          ),
        );
    if (!mounted) return;
    if (success) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropControllerProvider);
    final isSaving = state is CropCreating;
    final error = state is CropError ? state.message : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Add Crop'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Crop name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a crop name'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _varietyController,
              decoration: const InputDecoration(
                labelText: 'Variety (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _seasonController,
              decoration: const InputDecoration(labelText: 'Season'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a season'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'harvested', child: Text('Harvested')),
              ],
              onChanged: isSaving
                  ? null
                  : (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            _DateField(
              label: 'Sowing date (optional)',
              date: _sowingDate,
              onTap: () => _pickDate(sowing: true),
            ),
            const SizedBox(height: AppSpacing.md),
            _DateField(
              label: 'Expected harvest date (optional)',
              date: _harvestDate,
              onTap: () => _pickDate(sowing: false),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                error,
                style: const TextStyle(color: AppColors.attentionCoral),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: isSaving ? null : _submit,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save crop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          date == null
              ? 'Select date'
              : '${date!.day}/${date!.month}/${date!.year}',
        ),
      ),
    );
  }
}
