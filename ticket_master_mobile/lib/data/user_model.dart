/// ============================================================================
/// USER MODEL - Django REST API Alignment + Personalization
/// ============================================================================
/// Matches Django User table structure
/// Fields: id, nom, prenom, email, solde (wallet balance)
/// Personalization: city, interests, goals, followedOrganizers, isSetupComplete
/// ============================================================================

class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final double solde;
  final DateTime? lastLogin; // Pour déterminer si c'est la première connexion

  // Personalization fields
  final String? city;
  final List<String> interests;
  final List<String> goals;
  final List<int> followedOrganizers;
  final bool isSetupComplete;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.solde,
    this.lastLogin,
    this.city,
    this.interests = const [],
    this.goals = const [],
    this.followedOrganizers = const [],
    this.isSetupComplete = false,
  });

  /// From JSON (Django API response) - BULLETPROOF PARSING
  /// Django returns: id_utilisateur, nom, prenom, email, solde, statut
  /// Handles all null cases with safe defaults
  /// CRITICAL: Preserves existing ID if incoming ID is invalid (0 or null)
  factory UserModel.fromJson(Map<String, dynamic> json,
      {UserModel? existingUser}) {
    // CRITICAL: Extract ID with fallback to existing user's ID
    final incomingId =
        json['id_utilisateur'] as int? ?? json['id'] as int? ?? 0;
    final finalId = (incomingId > 0) ? incomingId : (existingUser?.id ?? 0);

    if (incomingId == 0 && existingUser != null) {}

    return UserModel(
      // CRITICAL: Use validated ID
      id: finalId,

      // Safe string parsing with fallback to existing user data
      nom: json['nom']?.toString() ?? existingUser?.nom ?? '',
      prenom: json['prenom']?.toString() ?? existingUser?.prenom ?? '',
      email: json['email']?.toString() ?? existingUser?.email ?? '',

      // Handle Django Decimal (can be String, int, or double)
      solde: _parseSolde(json['solde']),

      // Parse last_login from Django
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : existingUser?.lastLogin,

      // Personalization fields (may not be in Django yet)
      city: json['city']?.toString() ??
          json['ville']?.toString() ??
          existingUser?.city,
      interests:
          _parseStringList(json['interests']) ?? existingUser?.interests ?? [],
      goals: _parseStringList(json['goals']) ?? existingUser?.goals ?? [],
      followedOrganizers: _parseIntList(json['followed_organizers']) ??
          existingUser?.followedOrganizers ??
          [],
      isSetupComplete: json['is_setup_complete'] as bool? ??
          existingUser?.isSetupComplete ??
          false,
    );
  }

  /// Safely parse solde from Django Decimal (can be String, int, or double)
  /// CRITICAL: Django Decimal fields are returned as strings like "500000.00"
  /// UNIVERSAL: Handles ANY format from PostgreSQL
  static double _parseSolde(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      // UNIVERSAL: Handle string format from PostgreSQL
      final cleaned = value.trim();
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      } else {
        return 0.0;
      }
    }

    return 0.0;
  }

  /// Safely parse string list
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Safely parse int list
  static List<int>? _parseIntList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList();
    }
    return null;
  }

  /// To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'solde': solde,
      'last_login': lastLogin?.toIso8601String(),
      'city': city,
      'interests': interests,
      'goals': goals,
      'followed_organizers': followedOrganizers,
      'is_setup_complete': isSetupComplete,
    };
  }

  /// Full name helper
  String get fullName => '$prenom $nom'.trim();

  /// Copy with
  UserModel copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    double? solde,
    DateTime? lastLogin,
    String? city,
    List<String>? interests,
    List<String>? goals,
    List<int>? followedOrganizers,
    bool? isSetupComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      solde: solde ?? this.solde,
      lastLogin: lastLogin ?? this.lastLogin,
      city: city ?? this.city,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      followedOrganizers: followedOrganizers ?? this.followedOrganizers,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
    );
  }
}
