import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class FarmMapScreen extends StatelessWidget {
  const FarmMapScreen({super.key});

  static const LatLng _initialCenter = LatLng(18.5204, 73.8567);
  static const double _initialZoom = 13;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Map'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.krushimitra.app',
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: _FarmBoundaryInfoCard(
                  onAddBoundary: () => _showComingSoonMessage(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm boundary setup will be available next.'),
      ),
    );
  }
}

class _FarmBoundaryInfoCard extends StatelessWidget {
  const _FarmBoundaryInfoCard({required this.onAddBoundary});

  final VoidCallback onAddBoundary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.agriculture_outlined,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'YOUR FARM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No farm boundary yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Add your farm boundary to start monitoring your "
              "farm's health and satellite insights.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddBoundary,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Farm Boundary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}