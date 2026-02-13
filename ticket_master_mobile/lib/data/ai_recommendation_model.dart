/// ============================================================================
/// AI RECOMMENDATION MODEL - Django REST API Alignment
/// ============================================================================
/// Matches Django AI recommendation response structure
/// Fields: event_id, event_title, reason
/// ============================================================================

class AiRecommendationModel {
  final int eventId;
  final String eventTitle;
  final String reason;

  AiRecommendationModel({
    required this.eventId,
    required this.eventTitle,
    required this.reason,
  });

  /// From JSON (Django API response)
  factory AiRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AiRecommendationModel(
      eventId: json['event_id'] as int? ?? json['id_evenement'] as int? ?? 0,
      eventTitle: json['event_title']?.toString() ?? 
                  json['titre_evenement']?.toString() ?? 
                  'Événement recommandé',
      reason: json['reason']?.toString() ?? 
              json['raison']?.toString() ?? 
              'Cet événement pourrait vous intéresser.',
    );
  }

  /// To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_title': eventTitle,
      'reason': reason,
    };
  }

  /// Copy with
  AiRecommendationModel copyWith({
    int? eventId,
    String? eventTitle,
    String? reason,
  }) {
    return AiRecommendationModel(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      reason: reason ?? this.reason,
    );
  }
}
