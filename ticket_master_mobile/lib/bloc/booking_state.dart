part of 'booking_cubit.dart';

/// ============================================================================
/// BOOKING STATES - Mock API Integration
/// Updated: 2026-02-07
/// ============================================================================

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingProcessing extends BookingState {}

class TicketsLoaded extends BookingState {
  final List<TicketModel> tickets;

  TicketsLoaded({required this.tickets});
  
  // Backward compatibility
  List<TicketModel> get ticketTypes => tickets;
}

class BookingSuccess extends BookingState {
  final AchatModel booking;

  BookingSuccess({required this.booking});
  
  // Backward compatibility
  AchatModel get achat => booking;
}

class UserBookingsLoaded extends BookingState {
  final List<AchatModel> bookings;

  UserBookingsLoaded({required this.bookings});
  
  // Backward compatibility
  List<AchatModel> get achats => bookings;
}

// ========================================
// BACKWARD COMPATIBILITY ALIASES
// ========================================
/// Alias for TicketsLoaded to maintain compatibility
typedef TicketTypesLoaded = TicketsLoaded;

class BookingError extends BookingState {
  final String message;

  BookingError({required this.message});
}
