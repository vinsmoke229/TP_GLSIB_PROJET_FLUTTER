/// ============================================================================
/// EVENT MODEL - Django REST API Alignment + Discovery Features
/// ============================================================================
/// Matches Django Event table structure
/// Fields: id, titre, date, lieu, image, type_evenement, category, isFavorite
/// NEW: sessions list for dynamic calendar
/// ============================================================================

import 'session_model.dart';

class EventModel {
  final int id;
  final String titre;
  final DateTime date;
  final String lieu;
  final String image;
  final String typeEvenement;

  // Additional computed fields
  final int? totalStock;
  final int? stockRestant;

  // NEW: Discovery features
  final String category; // Tourism, Music, Tech, Sport, Art, Food
  final bool isFavorite;

  // NEW: GPS Coordinates for navigation
  final double? latitude;
  final double? longitude;

  // NEW: Sessions for dynamic calendar
  final List<SessionModel> sessions;

  // Event time
  final String? heureDebut;
  final String? heureFin;

  EventModel({
    required this.id,
    required this.titre,
    required this.date,
    required this.lieu,
    required this.image,
    required this.typeEvenement,
    this.totalStock,
    this.stockRestant,
    this.category = 'Music',
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.sessions = const [],
    this.heureDebut,
    this.heureFin,
  });

  /// From JSON (Django API response) - BULLETPROOF PARSING
  /// Django returns: id_evenement, titre_evenement, date, lieu, image, sessions
  /// Handles all null cases with safe defaults
  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse image URL with intelligent fallback
    String imageUrl = json['image']?.toString() ?? '';

    // CRITICAL: Handle relative URLs from Django
    if (imageUrl.isNotEmpty && imageUrl.startsWith('/media/')) {
      imageUrl = 'http://10.0.2.2:8000$imageUrl';
    }

    // If image is empty or invalid, use category-based high-quality fallback
    if (imageUrl.isEmpty ||
        imageUrl == 'null' ||
        imageUrl.contains('placeholder')) {
      final titre = json['titre_evenement']?.toString().toLowerCase() ??
          json['titre']?.toString().toLowerCase() ??
          '';
      final category = json['category']?.toString().toLowerCase() ?? '';
      final typeEvenement =
          json['type_evenement']?.toString().toLowerCase() ?? '';

      // Smart fallback based on title, category, or type_evenement keywords
      if (titre.contains('music') ||
          titre.contains('concert') ||
          titre.contains('festival') ||
          titre.contains('olomide') ||
          category == 'music' ||
          typeEvenement == 'music') {
        imageUrl =
            'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80';
      } else if (titre.contains('tech') ||
          titre.contains('conference') ||
          titre.contains('summit') ||
          titre.contains('africa') ||
          category == 'tech' ||
          typeEvenement == 'tech') {
        imageUrl =
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80';
      } else if (titre.contains('sport') ||
          titre.contains('match') ||
          titre.contains('game') ||
          titre.contains('football') ||
          category == 'sport' ||
          typeEvenement == 'sport') {
        imageUrl =
            'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&q=80';
      } else if (titre.contains('art') ||
          titre.contains('expo') ||
          titre.contains('gallery') ||
          titre.contains('exhibition') ||
          category == 'art' ||
          typeEvenement == 'art') {
        imageUrl =
            'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=800&q=80';
      } else if (titre.contains('food') ||
          titre.contains('cuisine') ||
          titre.contains('restaurant') ||
          category == 'food' ||
          typeEvenement == 'food') {
        imageUrl =
            'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80';
      } else {
        // Default: Generic event/celebration image
        imageUrl =
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&q=80';
      }
    }

    // Parse sessions list
    List<SessionModel> sessionsList = [];
    if (json['sessions'] != null && json['sessions'] is List) {
      sessionsList = (json['sessions'] as List)
          .map((sessionJson) =>
              SessionModel.fromJson(sessionJson as Map<String, dynamic>))
          .toList();
    }

    return EventModel(
      // CRITICAL: Django uses 'id_evenement' NOT 'id'
      id: json['id_evenement'] as int? ?? json['id'] as int? ?? 0,

      // CRITICAL: Django uses 'titre_evenement' NOT 'titre'
      titre: json['titre_evenement']?.toString() ??
          json['titre']?.toString() ??
          'Sans titre',

      // Safe date parsing with fallback
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),

      // Safe location parsing
      lieu: json['lieu']?.toString() ?? 'Lomé, Togo',

      // Use smart fallback image (with /media/ prefix handling)
      image: imageUrl,

      // Type evenement with default
      typeEvenement: json['type_evenement']?.toString() ?? 'Music',

      // Stock fields (may not be in Django response)
      totalStock: json['total_stock'] as int?,
      stockRestant: json['stock_restant'] as int?,

      // Discovery features
      category: json['category']?.toString() ?? 'Music',
      isFavorite: json['is_favorite'] as bool? ?? false,

      // GPS Coordinates for navigation
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),

      // Sessions for dynamic calendar
      sessions: sessionsList,

      // Event time
      heureDebut: json['heure_debut']?.toString(),
      heureFin: json['heure_fin']?.toString(),
    );
  }

  /// Safely parse double from various types
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'date': date.toIso8601String(),
      'lieu': lieu,
      'image': image,
      'type_evenement': typeEvenement,
      'total_stock': totalStock,
      'stock_restant': stockRestant,
      'category': category,
      'is_favorite': isFavorite,
      'latitude': latitude,
      'longitude': longitude,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
    };
  }

  /// Check if event has valid GPS coordinates
  bool get hasValidGPS {
    return latitude != null && longitude != null;
  }

  /// Calculate progress percentage for stock
  double get stockProgress {
    if (totalStock == null || totalStock == 0) return 0.0;
    if (stockRestant == null) return 0.0;

    final sold = totalStock! - stockRestant!;
    return (sold / totalStock!).clamp(0.0, 1.0);
  }

  /// Check if event is sold out
  bool get isSoldOut => stockRestant != null && stockRestant! <= 0;

  /// Check if stock is low
  bool get isLowStock => stockRestant != null && stockRestant! < 10;

  /// Get formatted time range (HH:mm format)
  String get timeRange {
    if (heureDebut == null) return '';

    // Parse heure_debut (format: HH:mm:ss ou HH:mm)
    final debut = _formatTime(heureDebut!);

    if (heureFin != null) {
      final fin = _formatTime(heureFin!);
      return '$debut - $fin';
    }

    return debut;
  }

  /// Format time from HH:mm:ss to HH:mm
  String _formatTime(String time) {
    if (time.isEmpty) return '';

    // If format is HH:mm:ss, extract HH:mm
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return time;
  }

  // ========================================
  // COMPATIBILITY GETTERS (for old UI code)
  // ========================================

  /// Alias for titre (backward compatibility)
  String get title => titre;

  /// Alias for lieu (backward compatibility)
  String get locationName => lieu;

  /// Alias for image (backward compatibility)
  String get imageUrl => image;

  /// Placeholder description (not in Django model)
  String get description =>
      'Découvrez cet événement exceptionnel à $lieu. Ne manquez pas cette occasion unique!';

  /// Get unique dates from sessions
  List<DateTime> get availableDates {
    return sessions.map((s) => s.dateOnly).toSet().toList()..sort();
  }

  /// Get sessions for a specific date
  List<SessionModel> getSessionsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return sessions.where((s) {
      final sessionDate =
          DateTime(s.dateHeure.year, s.dateHeure.month, s.dateHeure.day);
      return sessionDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  }

  /// Copy with
  EventModel copyWith({
    int? id,
    String? titre,
    DateTime? date,
    String? lieu,
    String? image,
    String? typeEvenement,
    int? totalStock,
    int? stockRestant,
    String? category,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    List<SessionModel>? sessions,
  }) {
    return EventModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      date: date ?? this.date,
      lieu: lieu ?? this.lieu,
      image: image ?? this.image,
      typeEvenement: typeEvenement ?? this.typeEvenement,
      totalStock: totalStock ?? this.totalStock,
      stockRestant: stockRestant ?? this.stockRestant,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sessions: sessions ?? this.sessions,
    );
  }
}
