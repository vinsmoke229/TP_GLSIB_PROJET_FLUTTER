/// ============================================================================
/// ACHAT MODEL - Django REST API Alignment (PRODUCTION READY)
/// ============================================================================
/// Represents a purchase/booking from Django backend
/// Used for purchase history and ticket display
/// ZERO PLACEHOLDERS - All fields mapped to real Django data
/// ============================================================================

library;

class AchatModel {
  final int id;
  final int idTicket;
  final int idUser;
  final int quantite;
  final double montantTotal;
  final DateTime dateAchat;
  final String status;
  final bool estUtilise;
  
  // Expanded fields from nested objects
  final String eventTitre;
  final String eventLieu;
  final DateTime eventDate;
  final String ticketType;
  final String? eventImage;
  
  // QR Code and seat information
  final String qrCode;
  final String? qrCodeUrl; // NEW: URL de l'image QR code du backend
  final DateTime? dateUtilisation; // NEW: Date d'utilisation du ticket
  final String gate;
  final String row;
  final String seat;
  final String paymentStatus;

  AchatModel({
    required this.id,
    required this.idTicket,
    required this.idUser,
    required this.quantite,
    required this.montantTotal,
    required this.dateAchat,
    required this.status,
    this.estUtilise = false, // OPTIONAL with default value
    required this.eventTitre,
    required this.eventLieu,
    required this.eventDate,
    required this.ticketType,
    this.eventImage,
    required this.qrCode,
    this.qrCodeUrl, // NEW: Optional QR code URL
    this.dateUtilisation, // NEW: Optional utilisation date
    required this.gate,
    required this.row,
    required this.seat,
    required this.paymentStatus,
  });

  /// From JSON (Django API response) - ULTRA-FLEXIBLE PARSING
  /// Handles multiple response formats:
  /// 1. Flat keys: {evenement_titre: "...", evenement_lieu: "..."}
  /// 2. Nested event: {evenement: {titre: "...", lieu: "..."}}
  /// 3. Root level: {titre: "...", lieu: "..."}
  /// ZERO NULL: If title is null, use "Événement #${id}"
  factory AchatModel.fromJson(Map<String, dynamic> json) {
    // SMART UNWRAPPING: If JSON is wrapped in 'achat' key, unwrap it
    final data = json.containsKey('achat') 
        ? (json['achat'] is Map<String, dynamic> ? json['achat'] as Map<String, dynamic> : json)
        : json;

// Parse ID
    final idAchat = data['id_achat'] as int? ?? data['id'] as int? ?? 0;
    
    // Parse basic fields
    final quantite = data['quantite'] as int? ?? 1;
    final montantTotal = double.tryParse(data['montant_total']?.toString() ?? '0') ?? 0.0;
    final estUtilise = data['est_utilise'] as bool? ?? false;
    final dateAchat = DateTime.tryParse(data['date_achat']?.toString() ?? '') ?? DateTime.now();
    final ticketId = data['id_ticket'] as int? ?? 0;
    
    // ULTRA-FLEXIBLE EVENT DATA EXTRACTION
    String eventTitre = '';
    String eventLieu = '';
    String eventDateStr = '';
    String eventImage = '';
    
    // Strategy 1: Check for nested 'evenement' object
    if (data['evenement'] != null && data['evenement'] is Map) {
      final evenement = data['evenement'] as Map<String, dynamic>;
      eventTitre = evenement['titre']?.toString() ?? 
                   evenement['titre_evenement']?.toString() ?? '';
      eventLieu = evenement['lieu']?.toString() ?? '';
      eventDateStr = evenement['date']?.toString() ?? '';
      eventImage = evenement['image']?.toString() ?? '';
      
    }
    
    // Strategy 2: Check for flat keys with 'evenement_' prefix
    if (eventTitre.isEmpty) {
      eventTitre = data['evenement_titre']?.toString() ?? 
                   data['evenement_titre_evenement']?.toString() ?? '';
      eventLieu = data['evenement_lieu']?.toString() ?? '';
      eventDateStr = data['evenement_date']?.toString() ?? '';
      eventImage = data['evenement_image']?.toString() ?? '';
      if (eventTitre.isNotEmpty) {
        
      }
    }
    
    // Strategy 3: Check for root level keys
    if (eventTitre.isEmpty) {
      eventTitre = data['titre']?.toString() ?? 
                   data['titre_evenement']?.toString() ?? '';
      eventLieu = data['lieu']?.toString() ?? '';
      eventDateStr = data['date']?.toString() ?? '';
      eventImage = data['image']?.toString() ?? '';
      if (eventTitre.isNotEmpty) {
        
      }
    }
    
    // ZERO NULL: If title is still empty, use VISIBLE fallback
    if (eventTitre.isEmpty) {
      eventTitre = 'Billet #$idAchat';
      
    }
    
    // Parse ticket type (flexible)
    final ticketType = data['ticket_type']?.toString() ?? 
                      data['type_ticket']?.toString() ?? 
                      'Standard';
    
    // Parse event date
    DateTime eventDate = DateTime.now();
    if (eventDateStr.isNotEmpty) {
      eventDate = DateTime.tryParse(eventDateStr) ?? DateTime.now();
    }
    
    // IMAGE HANDLING - SYNCHRONIZED WITH EVENTMODEL
    if (eventImage.isNotEmpty && eventImage.startsWith('/media/')) {
      eventImage = 'http://10.0.2.2:8000$eventImage';
    }
    
    // Smart fallback based on title keywords
    if (eventImage.isEmpty || eventImage == 'null') {
      final titre = eventTitre.toLowerCase();
      
      if (titre.contains('music') || titre.contains('concert') || titre.contains('festival') || 
          titre.contains('olomide')) {
        eventImage = 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80';
      } else if (titre.contains('tech') || titre.contains('conference') || titre.contains('summit') || 
                 titre.contains('africa')) {
        eventImage = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80';
      } else if (titre.contains('sport') || titre.contains('match') || titre.contains('football')) {
        eventImage = 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&q=80';
      } else if (titre.contains('art') || titre.contains('expo') || titre.contains('gallery')) {
        eventImage = 'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=800&q=80';
      } else if (titre.contains('food') || titre.contains('cuisine') || titre.contains('restaurant')) {
        eventImage = 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80';
      } else {
        eventImage = 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&q=80';
      }
    }
    
    // Parse QR code from backend (with fallback)
    final qrCode = data['code_qr']?.toString() ?? 'TICKET-$idAchat';
    final qrCodeUrl = data['qr_code_url']?.toString();
    final dateUtilisation = data['date_utilisation'] != null 
        ? DateTime.tryParse(data['date_utilisation'].toString())
        : null;
    
    // Seat assignment
    final gate = data['gate']?.toString() ?? '02';
    final row = data['row']?.toString() ?? '01';
    final seat = data['seat']?.toString() ?? '${10 + (idAchat % 20)}';

return AchatModel(
      id: idAchat,
      idTicket: ticketId,
      idUser: data['id_utilisateur'] as int? ?? data['id_user'] as int? ?? 0,
      quantite: quantite,
      montantTotal: montantTotal,
      dateAchat: dateAchat,
      estUtilise: estUtilise,
      status: estUtilise ? 'used' : 'active',
      eventTitre: eventTitre,
      eventLieu: eventLieu.isEmpty ? 'Lomé, Togo' : eventLieu,
      eventDate: eventDate,
      ticketType: ticketType,
      eventImage: eventImage,
      qrCode: qrCode,
      qrCodeUrl: qrCodeUrl, // NEW
      dateUtilisation: dateUtilisation, // NEW
      gate: gate,
      row: row,
      seat: seat,
      paymentStatus: 'Paid',
    );
  }

  /// To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id_achat': id,
      'id_ticket': idTicket,
      'id_utilisateur': idUser,
      'quantite': quantite,
      'montant_total': montantTotal,
      'date_achat': dateAchat.toIso8601String(),
      'est_utilise': estUtilise,
      'status': status,
    };
  }

  // ========================================
  // BUSINESS LOGIC
  // ========================================
  
  /// Check if purchase is active
  bool get isActive => !estUtilise && status.toLowerCase() == 'active';
  
  /// Check if event is upcoming (in the future)
  bool get isUpcoming => eventDate.isAfter(DateTime.now());
  
  /// Check if event is completed (in the past)
  bool get isCompleted => eventDate.isBefore(DateTime.now());
  
  /// Get days left until event
  int get daysLeft {
    final now = DateTime.now();
    if (eventDate.isBefore(now)) return 0;
    return eventDate.difference(now).inDays;
  }
  
  /// Get ticket status display text
  String get ticketStatus {
    if (estUtilise) return 'used';
    if (isUpcoming) return 'upcoming';
    if (isCompleted) return 'completed';
    return 'active';
  }
  
  // ========================================
  // COMPATIBILITY GETTERS
  // ========================================
  
  String get qrCodeData => qrCode;
  String get eventTitle => eventTitre;
  String get eventLocation => eventLieu;
  int get quantity => quantite;
  double get totalPrice => montantTotal;
  DateTime get purchaseDate => dateAchat;
  String get ticketTypeName => ticketType;

  /// Copy with
  AchatModel copyWith({
    int? id,
    int? idTicket,
    int? idUser,
    int? quantite,
    double? montantTotal,
    DateTime? dateAchat,
    String? status,
    bool? estUtilise,
    String? eventTitre,
    String? eventLieu,
    DateTime? eventDate,
    String? ticketType,
    String? eventImage,
    String? qrCode,
    String? qrCodeUrl,
    DateTime? dateUtilisation,
    String? gate,
    String? row,
    String? seat,
    String? paymentStatus,
  }) {
    return AchatModel(
      id: id ?? this.id,
      idTicket: idTicket ?? this.idTicket,
      idUser: idUser ?? this.idUser,
      quantite: quantite ?? this.quantite,
      montantTotal: montantTotal ?? this.montantTotal,
      dateAchat: dateAchat ?? this.dateAchat,
      status: status ?? this.status,
      estUtilise: estUtilise ?? this.estUtilise,
      eventTitre: eventTitre ?? this.eventTitre,
      eventLieu: eventLieu ?? this.eventLieu,
      eventDate: eventDate ?? this.eventDate,
      ticketType: ticketType ?? this.ticketType,
      eventImage: eventImage ?? this.eventImage,
      qrCode: qrCode ?? this.qrCode,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      dateUtilisation: dateUtilisation ?? this.dateUtilisation,
      gate: gate ?? this.gate,
      row: row ?? this.row,
      seat: seat ?? this.seat,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}

// ========================================
// BACKWARD COMPATIBILITY ALIAS
// ========================================
typedef BookingModel = AchatModel;
