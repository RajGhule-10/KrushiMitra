import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _FarmBoundaryInfoCard(
                  onDrawBoundary: () => _showComingSoonMessage(context),
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
        content: Text('Boundary drawing will be available next.'),
      ),
    );
  }
}

class _FarmBoundaryInfoCard extends StatelessWidget {
  const _FarmBoundaryInfoCard({required this.onDrawBoundary});

  final VoidCallback onDrawBoundary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your farm boundary',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Your farm boundary will appear here once it is added.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDrawBoundary,
                child: const Text('Draw Boundary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}