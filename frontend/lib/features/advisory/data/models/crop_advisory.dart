/// A single advisory item for a crop, exactly as returned by the
/// backend. No classification or text generation happens here — this
/// is a pure parse of the backend's response.
class AdvisoryItem {
  const AdvisoryItem({
    required this.id,
    required this.cropId,
    required this.observationId,
    required this.title,
    required this.message,
    required this.severity,
    required this.priority,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String cropId;
  final String observationId;
  final String title;
  final String message;
  final String severity;
  final String priority;
  final String category;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;

  factory AdvisoryItem.fromJson(Map<String, dynamic> json) {
    return AdvisoryItem(
      id: json['id'] as String,
      cropId: json['crop_id'] as String,
      observationId: json['observation_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      priority: json['priority'] as String,
      category: json['category'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Wraps the backend's `{ "crop_id": ..., "advisory": ... }` response.
/// `advisory` is null whenever the backend has no advisory to show —
/// this is a normal, expected state, not an error.
class CropAdvisory {
  const CropAdvisory({required this.cropId, this.advisory});

  final String cropId;
  final AdvisoryItem? advisory;

  factory CropAdvisory.fromJson(Map<String, dynamic> json) {
    final advisoryJson = json['advisory'] as Map<String, dynamic>?;

    return CropAdvisory(
      cropId: json['crop_id'] as String,
      advisory: advisoryJson == null
          ? null
          : AdvisoryItem.fromJson(advisoryJson),
    );
  }
}
