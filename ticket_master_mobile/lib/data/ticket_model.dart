/// ============================================================================
/// TICKET MODEL - Django REST API Alignment
/// ============================================================================
/// Matches Django Ticket table structure
/// Fields: id, type, prix, stock, id_evenement
/// ============================================================================

class TicketModel {
  final int id;
  final String type;
  final double prix;
  final int stock;
  final int idEvenement;

  TicketModel({
    required this.id,
    required this.type,
    required this.prix,
    required this.stock,
    required this.idEvenement,
  });

  /// From JSON (Django API response) - BULLETPROOF PARSING
  /// Django returns: id_ticket, type, prix, stock, id_evenement
  /// Handles all null cases with safe defaults
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      // CRITICAL: Django uses 'id_ticket' NOT 'id'
      id: json['id_ticket'] as int? ?? json['id'] as int? ?? 0,
      
      // Safe string parsing
      type: json['type']?.toString() ?? 'Standard',
      
      // Safe price parsing (handles String, int, double)
      prix: double.tryParse(json['prix']?.toString() ?? '0') ?? 0.0,
      
      // Safe stock parsing
      stock: json['stock'] as int? ?? 0,
      
      // Safe event ID parsing
      idEvenement: json['id_evenement'] as int? ?? 0,
    );
  }

  /// To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'prix': prix,
      'stock': stock,
      'id_evenement': idEvenement,
    };
  }

  // ========================================
  // COMPATIBILITY GETTERS (for old UI code)
  // ========================================
  
  /// Alias for type (backward compatibility)
  String get name => type;
  
  /// Alias for prix (backward compatibility)
  double get price => prix;
  
  /// Alias for stock (backward compatibility)
  int get currentStock => stock;

  /// Check if ticket is available
  bool get isAvailable => stock > 0;

  /// Check if stock is low
  bool get isLowStock => stock < 10 && stock > 0;

  /// Check if sold out
  bool get isSoldOut => stock <= 0;

  /// Copy with
  TicketModel copyWith({
    int? id,
    String? type,
    double? prix,
    int? stock,
    int? idEvenement,
  }) {
    return TicketModel(
      id: id ?? this.id,
      type: type ?? this.type,
      prix: prix ?? this.prix,
      stock: stock ?? this.stock,
      idEvenement: idEvenement ?? this.idEvenement,
    );
  }
}

// ========================================
// BACKWARD COMPATIBILITY ALIAS
// ========================================
/// Alias for TicketModel to maintain compatibility with old UI code
typedef TicketTypeModel = TicketModel;
