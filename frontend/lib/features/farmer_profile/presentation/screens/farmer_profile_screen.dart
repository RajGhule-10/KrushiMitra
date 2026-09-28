import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/farmer_profile.dart';
import '../../data/models/farmer_profile_update_request.dart';
import '../state/farmer_profile_controller.dart';
import '../state/farmer_profile_state.dart';

class FarmerProfileScreen extends ConsumerStatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  ConsumerState<FarmerProfileScreen> createState() =>
      _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends ConsumerState<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _villageController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;

  String _preferredLanguage = 'mr';

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _villageController = TextEditingController();
    _districtController = TextEditingController();
    _stateController = TextEditingController();

    Future.microtask(() {
      ref.read(farmerProfileControllerProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _populateFields(FarmerProfile profile) {
    if (_fullNameController.text != profile.fullName) {
      _fullNameController.text = profile.fullName;
    }

    if (_villageController.text != (profile.village ?? '')) {
      _villageController.text = profile.village ?? '';
    }

    if (_districtController.text != (profile.district ?? '')) {
      _districtController.text = profile.district ?? '';
    }

    if (_stateController.text != (profile.state ?? '')) {
      _stateController.text = profile.state ?? '';
    }

    if (_preferredLanguage != profile.preferredLanguage) {
      _preferredLanguage = profile.preferredLanguage;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(farmerProfileControllerProvider.notifier)
        .updateProfile(
          FarmerProfileUpdateRequest(
            fullName: _fullNameController.text.trim(),
            village: _villageController.text.trim().isEmpty
                ? null
                : _villageController.text.trim(),
            district: _districtController.text.trim().isEmpty
                ? null
                : _districtController.text.trim(),
            state: _stateController.text.trim().isEmpty
                ? null
                : _stateController.text.trim(),
            preferredLanguage: _preferredLanguage,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerProfileControllerProvider);

    ref.listen<FarmerProfileState>(farmerProfileControllerProvider, (
      previous,
      next,
    ) {
      if (next is FarmerProfileLoaded && previous is FarmerProfileUpdating) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }

      if (next is FarmerProfileError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final isUpdating = state is FarmerProfileUpdating;

    if (state is FarmerProfileInitial || state is FarmerProfileLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is FarmerProfileError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unable to load your profile.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(farmerProfileControllerProvider.notifier)
                        .loadProfile();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    FarmerProfile profile;

    if (state is FarmerProfileLoaded) {
      profile = state.profile;
    } else if (state is FarmerProfileUpdating) {
      profile = state.profile;
    } else {
      return const SizedBox.shrink();
    }

    _populateFields(profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
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
              _ProfileHeader(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              _ProfileSection(
                title: 'Personal information',
                child: Column(
                  children: [
                    _ProfileField(
                      controller: _fullNameController,
                      label: 'Full name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProfileSection(
                title: 'Farm location',
                child: Column(
                  children: [
                    _ProfileField(
                      controller: _villageController,
                      label: 'Village',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProfileField(
                      controller: _districtController,
                      label: 'District',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProfileField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.public_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProfileSection(
                title: 'Language',
                child: DropdownButtonFormField<String>(
                  initialValue: _preferredLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Preferred language',
                    prefixIcon: Icon(Icons.language),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                    DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: isUpdating
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _preferredLanguage = value;
                            });
                          }
                        },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isUpdating ? null : _saveProfile,
                  child: isUpdating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile.fullName.isNotEmpty
        ? profile.fullName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Farmer profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
