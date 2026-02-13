import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:event_app/services/api_service.dart';
import 'package:event_app/data/ticket_model.dart';
import 'package:event_app/data/achat_model.dart';

part 'booking_state.dart';

/// ============================================================================
/// BOOKING CUBIT - Mock API Integration
/// ============================================================================
/// Features:
/// - Fetch tickets from Mock API
/// - Purchase tickets via Mock API
/// - Mock service handles all transaction logic
/// - Fetch user purchase history
/// Updated: 2026-02-07
/// ============================================================================

class BookingCubit extends Cubit<BookingState> {
  final ApiService _apiService;

  BookingCubit(this._apiService) : super(BookingInitial());

  /// Load tickets for an event
  Future<void> loadTickets(int eventId) async {
    emit(BookingLoading());
    
    try {

final tickets = await _apiService.fetchTickets(eventId);
      
      if (tickets.isEmpty) {
        
        emit(BookingError(message: 'No tickets available for this event'));
        return;
      }

emit(TicketsLoaded(tickets: tickets));
    } catch (e) {
      
      emit(BookingError(message: 'Failed to load tickets'));
    }
  }
  
  /// Backward compatibility: loadTicketTypes
  Future<void> loadTicketTypes(dynamic eventId) async {
    // Convert String to int if needed
    final id = eventId is String ? int.tryParse(eventId) ?? 0 : eventId as int;
    return loadTickets(id);
  }

  /// Purchase ticket with session ID
  /// Backend handles all validation and transaction logic
  /// PRODUCTION: Immediately syncs wallet balance from PostgreSQL after purchase
  /// NEW: Requires session ID for dynamic calendar system
  Future<void> purchaseTicket({
    required int ticketId,
    required int quantity,
    int? sessionId, // NEW: Session ID for dynamic calendar
    // Old parameters (ignored, for backward compatibility)
    dynamic eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventLocation,
    dynamic ticketTypeId,
    String? ticketTypeName,
    double? totalPrice,
  }) async {
    emit(BookingProcessing());
    
    try {

if (sessionId != null) {
        
      }
      
      final achat = await _apiService.purchaseTicket(
        idTicket: ticketId,
        quantite: quantity,
        idSession: sessionId,
      );

// CRITICAL: Reset state to force UI refresh
      emit(BookingInitial());
      
      // PRODUCTION: Immediately sync wallet balance from PostgreSQL
      
      try {
        final freshUser = await _apiService.getCurrentUser();
        
        // Note: AuthCubit will be updated by the UI layer
      } catch (e) {
        
        // Don't fail the purchase if wallet sync fails
      }
      
      // CRITICAL: Reload tickets from Django (already sorted by server)
      try {
        
        await loadUserBookings();
        
      } catch (e) {
        
        // Don't fail the purchase if reload fails
      }
      
      emit(BookingSuccess(booking: achat));
    } catch (e) {

String errorMessage = _extractErrorMessage(e.toString());
      emit(BookingError(message: errorMessage));
    }
  }

  /// Load user purchases/bookings
  Future<void> loadUserBookings() async {
    // CRITICAL: Reset state to clear any cached data
    emit(BookingInitial());
    
    emit(BookingLoading());
    
    try {

final achats = await _apiService.fetchUserAchats();
      
      // TRUST DJANGO ORDERING: Django sends data with order_by('-id_achat')
      // No local sorting needed - use server order as-is

for (var i = 0; i < achats.length && i < 5; i++) {
        
      }
      
      emit(UserBookingsLoaded(bookings: achats));
    } catch (e) {
      
      emit(BookingError(message: 'Failed to load bookings'));
    }
  }

  /// Extract user-friendly error message
  String _extractErrorMessage(String error) {
    String message = error.replaceAll('Exception: ', '');
    
    if (message.contains('Insufficient balance') || 
        message.contains('solde insuffisant')) {
      return 'Insufficient balance. Please recharge your wallet.';
    } else if (message.contains('Insufficient stock') || 
               message.contains('stock insuffisant')) {
      return 'Not enough tickets available.';
    } else if (message.contains('Unauthorized')) {
      return 'Please sign in to purchase tickets.';
    } else if (message.contains('not found')) {
      return 'Ticket or event not found.';
    } else if (message.contains('network') || 
               message.contains('connection')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Purchase failed. Please try again.';
    }
  }

  /// Reset to initial state
  void reset() {
    emit(BookingInitial());
  }
}
