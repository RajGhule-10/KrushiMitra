import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../farms/data/farm_boundary_providers.dart';
import '../../../farms/presentation/screens/farm_boundary_screen.dart';
import '../../data/crop_health_providers.dart';
import '../../data/models/crop_health_map.dart';

class CropHealthMapScreen extends ConsumerStatefulWidget {
  const CropHealthMapScreen({required this.cropId, super.key});

  final String cropId;

  @override
  ConsumerState<CropHealthMapScreen> createState() =>
      _CropHealthMapScreenState();
}

class _CropHealthMapScreenState extends ConsumerState<CropHealthMapScreen> {
  final _mapController = MapController();
  CropHealthMap? _map;
  List<List<LatLng>> _polygons = [];
  TileProvider? _tileProvider;
  String? _error;
  bool _loading = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _tileProvider = null;
    });

    try {
      final map = await ref
          .read(cropHealthRepositoryProvider)
          .getCropHealthMap(widget.cropId);
      final boundary = await ref
          .read(farmBoundaryRepositoryProvider)
          .getBoundary(map.farmId);
      final polygons = latLngPolygonsFromGeometry(boundary.geometry);
      final token = await ref.read(tokenStorageProvider).getAccessToken();

      if (!mounted) return;
      if (token == null || token.isEmpty) {
        throw StateError('Authentication is required to load the map.');
      }

      final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;
      final tileUrl = Uri.parse(
        baseUrl,
      ).resolve(map.tileUrlTemplate).toString();

      setState(() {
        _map = map;
        _polygons = polygons;
        _tileProvider = NetworkTileProvider(
          headers: {'Authorization': 'Bearer $token'},
        );
        _tileUrl = tileUrl;
        _loading = false;
      });
      _fitBoundary();
    } on FormatException {
      _showError('We could not display this farm boundary. Please try again.');
    } catch (_) {
      _showError('Unable to load the satellite map. Please try again.');
    }
  }

  String? _tileUrl;

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  void _fitBoundary() {
    if (!_mapReady || _polygons.isEmpty) return;
    final bounds = farmBoundaryBounds(_polygons);
    if (bounds == null) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        minZoom: 3,
        maxZoom: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Satellite map'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }

    final map = _map;
    final tileProvider = _tileProvider;
    final tileUrl = _tileUrl;
    if (map == null || tileProvider == null || tileUrl == null) {
      return _ErrorView(
        message: 'Satellite map is unavailable. Please try again.',
        onRetry: _load,
      );
    }

    return Stack(
      children: [
        FlutterMap(
          key: const Key('crop-health-map'),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _polygons.isNotEmpty && _polygons.first.isNotEmpty
                ? _polygons.first.first
                : const LatLng(18.5204, 73.8567),
            initialZoom: 13,
            onMapReady: () {
              _mapReady = true;
              _fitBoundary();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.krushimitra.app',
            ),
            TileLayer(
              key: const Key('ndvi-tile-layer'),
              urlTemplate: tileUrl,
              tileProvider: tileProvider,
              userAgentPackageName: 'com.krushimitra.app',
            ),
            PolygonLayer(
              key: const Key('farm-boundary-layer'),
              polygons: [
                for (final polygon in _polygons)
                  Polygon(
                    points: polygon,
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderColor: AppColors.primaryGreen,
                    borderStrokeWidth: 3,
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: _NdviLegend(palette: map.visualization.palette),
        ),
      ],
    );
  }
}

class _NdviLegend extends StatelessWidget {
  const _NdviLegend({required this.palette});

  final List<String> palette;

  @override
  Widget build(BuildContext context) {
    final colors = [for (final value in palette) _colorFromHex(value)];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop condition',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final color in colors)
                  Expanded(child: Container(height: 12, color: color)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low / stressed'),
                Text('Moderate'),
                Text('Good'),
                Text('Healthy'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorFromHex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.attentionCoral,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
