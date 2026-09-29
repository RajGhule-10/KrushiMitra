import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/farm_create_request.dart';
import '../state/farm_controller.dart';
import '../state/farm_state.dart';

class CreateFarmScreen extends ConsumerStatefulWidget {
  const CreateFarmScreen({super.key});

  @override
  ConsumerState<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends ConsumerState<CreateFarmScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _gatNumberController;
  late final TextEditingController _areaController;
  late final TextEditingController _villageController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _gatNumberController = TextEditingController();
    _areaController = TextEditingController();
    _villageController = TextEditingController();
    _districtController = TextEditingController();
    _stateController = TextEditingController();

    ref.listenManual<FarmState>(farmControllerProvider, _handleFarmState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gatNumberController.dispose();
    _areaController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    ref
        .read(farmControllerProvider.notifier)
        .createFarm(
          FarmCreateRequest(
            name: _nameController.text.trim(),
            gatNumber: _optionalValue(_gatNumberController),
            areaHectares: _areaController.text.trim().isEmpty
                ? null
                : double.parse(_areaController.text.trim()),
            village: _optionalValue(_villageController),
            district: _optionalValue(_districtController),
            state: _optionalValue(_stateController),
          ),
        );
  }

  void _handleFarmState(FarmState? previous, FarmState next) {
    if (!_isSubmitting) {
      return;
    }

    if (next is FarmLoaded) {
      _isSubmitting = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm created successfully.')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (next is FarmError) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message)));
    }
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmControllerProvider);
    final isCreating = state is FarmCreating || _isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Add farm'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              _FormIntro(),
              const SizedBox(height: AppSpacing.xl),
              _FarmField(
                controller: _nameController,
                label: 'Farm name',
                icon: Icons.agriculture_outlined,
                required: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a farm name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _FarmField(
                controller: _gatNumberController,
                label: 'Gat number',
                icon: Icons.tag,
              ),
              const SizedBox(height: AppSpacing.md),
              _FarmField(
                controller: _areaController,
                label: 'Area (hectares)',
                icon: Icons.square_foot_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final area = double.tryParse(value.trim());
                  if (area == null || area <= 0) {
                    return 'Enter a positive area';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _FormSection(
                title: 'Location',
                child: Column(
                  children: [
                    _FarmField(
                      controller: _villageController,
                      label: 'Village',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FarmField(
                      controller: _districtController,
                      label: 'District',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FarmField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.public_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: isCreating ? null : _submit,
                icon: isCreating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnDark,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(isCreating ? 'Creating farm...' : 'Create farm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.10),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.spa_outlined,
            color: AppColors.primaryGreen,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Add the details you know. You can update the farm later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _FarmField extends StatelessWidget {
  const _FarmField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}
