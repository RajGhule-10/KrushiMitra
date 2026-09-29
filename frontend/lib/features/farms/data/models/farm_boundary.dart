class FarmBoundary {
  const FarmBoundary({this.id, required this.farmId, required this.geometry});

  final String? id;
  final String farmId;
  final GeoJsonGeometry geometry;

  factory FarmBoundary.fromJson(Map<String, dynamic> json) {
    return FarmBoundary(
      id: json['id'] as String?,
      farmId: json['farm_id'] as String,
      geometry: GeoJsonGeometry.fromJson(
        json['geometry'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'farm_id': farmId,
      'geometry': geometry.toJson(),
    };
  }
}

class GeoJsonGeometry {
  const GeoJsonGeometry({required this.type, required this.coordinates});

  final String type;
  final List<dynamic> coordinates;

  factory GeoJsonGeometry.fromJson(Map<String, dynamic> json) {
    return GeoJsonGeometry(
      type: json['type'] as String,
      coordinates: List<dynamic>.from(json['coordinates'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}
