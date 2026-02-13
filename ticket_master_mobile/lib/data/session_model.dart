/// ============================================================================
/// SESSION MODEL - Django REST API Alignment
/// ============================================================================
/// Matches Django Session table structure
/// Fields: id_session, id_evenement, date_heure, places_disponibles
/// ============================================================================

class SessionModel {
  final int id;
  final int eventId;
  final DateTime dateHeure;
  final int placesDisponibles;

  SessionModel({
    required this.id,
    required this.eventId,
    required this.dateHeure,
    required this.placesDisponibles,
  });

  /// From JSON (Django API response)
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id_session'] as int? ?? json['id'] as int? ?? 0,
      eventId: json['id_evenement'] as int? ?? 0,
      dateHeure: DateTime.tryParse(json['date_heure']?.toString() ?? '') ?? DateTime.now(),
      placesDisponibles: json['places_disponibles'] as int? ?? 0,
    );
  }

  /// To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id_session': id,
      'id_evenement': eventId,
      'date_heure': dateHeure.toIso8601String(),
      'places_disponibles': placesDisponibles,
    };
  }

  /// Check if session is sold out
  bool get isSoldOut => placesDisponibles <= 0;

  /// Check if session is low stock
  bool get isLowStock => placesDisponibles < 10;

  /// Get date only (without time)
  DateTime get dateOnly {
    return DateTime(dateHeure.year, dateHeure.month, dateHeure.day);
  }

  /// Get time only as string (e.g., "14:00")
  String get timeOnly {
    final hour = dateHeure.hour.toString().padLeft(2, '0');
    final minute = dateHeure.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get formatted time in 24-hour format (e.g., "14:30")
  String get formattedTime {
    final hour = dateHeure.hour.toString().padLeft(2, '0');
    final minute = dateHeure.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Copy with
  SessionModel copyWith({
    int? id,
    int? eventId,
    DateTime? dateHeure,
    int? placesDisponibles,
  }) {
    return SessionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      dateHeure: dateHeure ?? this.dateHeure,
      placesDisponibles: placesDisponibles ?? this.placesDisponibles,
    );
  }
}
