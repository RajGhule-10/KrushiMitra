import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/farm_boundary.dart';
import '../state/farm_boundary_controller.dart';
import '../state/farm_boundary_state.dart';

class FarmBoundaryScreen extends ConsumerStatefulWidget {
  const FarmBoundaryScreen({required this.farmId, super.key});

  final String farmId;

  @override
  ConsumerState<FarmBoundaryScreen> createState() => _FarmBoundaryScreenState();
}

class _FarmBoundaryScreenState extends ConsumerState<FarmBoundaryScreen> {
  final _points = BoundaryPointStore();
  List<List<LatLng>> _savedPolygons = [];
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual<FarmBoundaryState>(
      farmBoundaryControllerProvider,
      _handleBoundaryState,
    );
    Future.microtask(
      () => ref
          .read(farmBoundaryControllerProvider.notifier)
          .loadBoundary(widget.farmId),
    );
  }

  void _handleBoundaryState(
    FarmBoundaryState? previous,
    FarmBoundaryState next,
  ) {
    if (previous is FarmBoundarySaving && next is FarmBoundaryLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm boundary saved successfully.')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else if (next is FarmBoundaryLoaded) {
      try {
        final polygons = latLngPolygonsFromGeometry(next.boundary.geometry);
        setState(() {
          _savedPolygons = polygons;
          _isEditing = false;
          _points.clear();
        });
      } on FormatException {
        setState(() {
          _savedPolygons = [];
          _isEditing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not display this farm boundary. Please try again.',
            ),
          ),
        );
      }
    } else if (previous is FarmBoundarySaving && next is FarmBoundaryError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message)));
    } else if (next is FarmBoundaryError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message)));
    } else if (next is FarmBoundaryEmpty) {
      setState(() {
        _savedPolygons = [];
        _isEditing = true;
      });
    }
  }

  void _saveBoundary() {
    final state = ref.read(farmBoundaryControllerProvider);
    if (!_points.isReady || state is FarmBoundarySaving) {
      return;
    }

    ref
        .read(farmBoundaryControllerProvider.notifier)
        .saveBoundary(
          widget.farmId,
          boundaryGeometryFromPoints(_points.points),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boundaryState = ref.watch(farmBoundaryControllerProvider);
    final isSaving = boundaryState is FarmBoundarySaving;
    final polygonPoints = _points.isReady ? _points.points : const <LatLng>[];
    final isLoading = boundaryState is FarmBoundaryLoading;
    final canRetryLoad =
        boundaryState is FarmBoundaryError &&
        _points.points.isEmpty &&
        _savedPolygons.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Mark farm boundary'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: const Key('farm-boundary-map'),
            options: MapOptions(
              initialCenter: const LatLng(18.5204, 73.8567),
              initialZoom: 13,
              onTap: (_, point) {
                if (!_isEditing || isLoading || isSaving) {
                  return;
                }
                if (_points.add(point)) {
                  setState(() {});
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.krushimitra.app',
              ),
              if (polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      color: AppColors.primaryGreen.withValues(alpha: 0.28),
                      borderColor: AppColors.primaryGreen,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              if (!_isEditing && _savedPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    for (final polygon in _savedPolygons)
                      Polygon(
                        points: polygon,
                        color: AppColors.primaryGreen.withValues(alpha: 0.28),
                        borderColor: AppColors.primaryGreen,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
              if (_points.points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (var index = 0; index < _points.points.length; index++)
                      Marker(
                        point: _points.points[index],
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                child: _DrawingControls(
                  pointCount: _points.points.length,
                  canUndo: _points.points.isNotEmpty,
                  isReady: _points.isReady,
                  isSaving: isSaving,
                  hasSavedBoundary: _savedPolygons.isNotEmpty,
                  isEditing: _isEditing,
                  theme: theme,
                  onSave: _saveBoundary,
                  onEdit: _startEditing,
                  onRetryLoad: canRetryLoad ? _loadBoundary : null,
                  onUndo: () {
                    if (_points.undo()) {
                      setState(() {});
                    }
                  },
                  onClear: () {
                    _points.clear();
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          if (isLoading) const _BoundaryLoadingOverlay(),
        ],
      ),
    );
  }

  void _loadBoundary() {
    ref
        .read(farmBoundaryControllerProvider.notifier)
        .loadBoundary(widget.farmId);
  }

  void _startEditing() {
    if (_savedPolygons.length == 1) {
      final points = List<LatLng>.from(_savedPolygons.first);
      if (points.length > 1 && points.first == points.last) {
        points.removeLast();
      }
      _points.clear();
      for (final point in points) {
        _points.add(point);
      }
    } else {
      _points.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draw a new boundary to replace the saved boundary.'),
        ),
      );
    }
    setState(() {
      _isEditing = true;
    });
  }
}

class BoundaryPointStore {
  BoundaryPointStore({this.minimumSeparation = 0.00005});

  final double minimumSeparation;
  final List<LatLng> points = [];

  bool get isReady => points.length >= 3;

  bool add(LatLng point) {
    if (points.any((existing) => _isNear(existing, point))) {
      return false;
    }

    points.add(point);
    return true;
  }

  bool undo() {
    if (points.isEmpty) {
      return false;
    }

    points.removeLast();
    return true;
  }

  void clear() {
    points.clear();
  }

  bool _isNear(LatLng first, LatLng second) {
    return (first.latitude - second.latitude).abs() < minimumSeparation &&
        (first.longitude - second.longitude).abs() < minimumSeparation;
  }
}

Map<String, dynamic> boundaryGeometryFromPoints(List<LatLng> points) {
  if (points.length < 3) {
    throw ArgumentError('A boundary requires at least 3 points.');
  }

  final coordinates = points
      .map((point) => <double>[point.longitude, point.latitude])
      .toList();
  coordinates.add(List<double>.from(coordinates.first));

  return {
    'type': 'Polygon',
    'coordinates': [coordinates],
  };
}

List<List<LatLng>> latLngPolygonsFromGeometry(GeoJsonGeometry geometry) {
  final rawPolygons = switch (geometry.type) {
    'Polygon' => [geometry.coordinates],
    'MultiPolygon' => geometry.coordinates,
    _ => throw FormatException('Unsupported boundary geometry type.'),
  };

  return [
    for (final rawPolygon in rawPolygons)
      _latLngRingFromRaw(rawPolygon as List<dynamic>),
  ];
}

List<LatLng> _latLngRingFromRaw(List<dynamic> polygon) {
  if (polygon.isEmpty || polygon.first is! List<dynamic>) {
    throw FormatException('Invalid boundary polygon coordinates.');
  }

  final ring = polygon.first as List<dynamic>;
  if (ring.length < 3) {
    throw FormatException('Boundary polygon has too few points.');
  }

  return [
    for (final rawPosition in ring)
      _latLngFromRawPosition(rawPosition as List<dynamic>),
  ];
}

LatLng _latLngFromRawPosition(List<dynamic> position) {
  if (position.length < 2 || position[0] is! num || position[1] is! num) {
    throw FormatException('Invalid boundary coordinate.');
  }

  return LatLng(
    (position[1] as num).toDouble(),
    (position[0] as num).toDouble(),
  );
}

class _BoundaryLoadingOverlay extends StatelessWidget {
  const _BoundaryLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x66000000),
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGreen),
                SizedBox(width: AppSpacing.md),
                Text('Loading boundary...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawingControls extends StatelessWidget {
  const _DrawingControls({
    required this.pointCount,
    required this.canUndo,
    required this.isReady,
    required this.isSaving,
    required this.hasSavedBoundary,
    required this.isEditing,
    required this.theme,
    required this.onSave,
    required this.onEdit,
    required this.onRetryLoad,
    required this.onUndo,
    required this.onClear,
  });

  final int pointCount;
  final bool canUndo;
  final bool isReady;
  final bool isSaving;
  final bool hasSavedBoundary;
  final bool isEditing;
  final ThemeData theme;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback? onRetryLoad;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Mark your farm' : 'Saved farm boundary',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isEditing
                  ? 'Tap around the edges of your farm to draw its boundary.'
                  : 'Your saved boundary is shown on the map.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$pointCount boundary ${pointCount == 1 ? 'point' : 'points'}',
              key: const Key('boundary-point-count'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
            if (isEditing && !isReady) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add at least 3 points to mark your farm.',
                key: const Key('boundary-minimum-message'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (hasSavedBoundary && !isEditing)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Boundary'),
                ),
              ),
            if (isEditing)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: pointCount == 0 ? null : onClear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            if (isEditing) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isReady && !isSaving ? onSave : null,
                  icon: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnDark,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    isSaving ? 'Saving boundary...' : 'Save Boundary',
                  ),
                ),
              ),
            ],
            if (onRetryLoad != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRetryLoad,
                  child: const Text('Try loading boundary again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
