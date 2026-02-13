import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:event_app/services/api_service.dart';
import 'package:event_app/data/event_model.dart';

part 'event_state.dart';

/// ============================================================================
/// EVENT CUBIT - Django REST API Integration
/// ============================================================================
/// Features:
/// - Fetch events from Django backend
/// - AI-powered recommendations
/// - Event filtering and search
/// ============================================================================

class EventCubit extends Cubit<EventState> {
  final ApiService _apiService;

  EventCubit(this._apiService) : super(EventInitial());

  /// Fetch all events
  Future<void> fetchEvents() async {
    emit(EventLoading());
    
    try {

final events = await _apiService.fetchEvents();
      
      if (events.isEmpty) {
        
        emit(EventEmpty());
        return;
      }

emit(EventLoaded(events: events));
    } catch (e) {
      
      emit(EventError(message: 'Failed to load events'));
    }
  }

  /// Search events by query (real-time)
  Future<void> searchEvents(String query) async {
    // If query is empty, fetch all events
    if (query.trim().isEmpty) {
      await fetchEvents();
      return;
    }

    emit(EventLoading());
    
    try {

final events = await _apiService.searchEvents(query);
      
      if (events.isEmpty) {
        
        emit(EventEmpty());
        return;
      }

emit(EventLoaded(events: events));
    } catch (e) {
      
      emit(EventError(message: 'Failed to search events'));
    }
  }

  /// Fetch events by category
  Future<void> fetchEventsByCategory(String category) async {
    emit(EventLoading());
    
    try {

final events = await _apiService.fetchEventsByCategory(category);
      
      if (events.isEmpty) {
        
        emit(EventEmpty());
        return;
      }

emit(EventLoaded(events: events));
    } catch (e) {
      
      emit(EventError(message: 'Failed to load category'));
    }
  }

  /// Get single event by ID
  Future<void> getEventById(int eventId) async {
    emit(EventLoading());
    
    try {

final event = await _apiService.getEventById(eventId);

emit(EventDetailLoaded(event: event));
    } catch (e) {
      
      emit(EventError(message: 'Failed to load event details'));
    }
  }

  /// Get AI recommendations
  Future<void> getAIRecommendations() async {
    emit(EventLoading());
    
    try {

final events = await _apiService.getAIRecommendations();
      
      if (events.isEmpty) {
        
        // Fallback to regular events
        await fetchEvents();
        return;
      }

emit(EventLoaded(events: events, isAIRecommended: true));
    } catch (e) {
      
      // Fallback to regular events
      await fetchEvents();
    }
  }

  /// Filter events by type
  void filterEventsByType(String type) {
    final currentState = state;
    
    if (currentState is EventLoaded) {
      final filteredEvents = currentState.events
          .where((event) => event.typeEvenement.toLowerCase() == type.toLowerCase())
          .toList();
      
      if (filteredEvents.isEmpty) {
        emit(EventEmpty());
      } else {
        emit(EventLoaded(events: filteredEvents));
      }
    }
  }

  /// Refresh events
  Future<void> refreshEvents() async {
    await fetchEvents();
  }

  // ========================================
  // ADVANCED FILTERING METHODS (NEW)
  // ========================================

  /// Filter events by multiple criteria
  void filterEvents({
    String? searchQuery,
    String? category,
    String? timeframe,
  }) {
    final currentState = state;
    
    if (currentState is! EventLoaded) {
      return;
    }

    var filtered = List<EventModel>.from(currentState.events);
    final now = DateTime.now();

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        final title = event.title.toLowerCase();
        final location = event.locationName.toLowerCase();
        final query = searchQuery.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    }

    // Apply category filter
    if (category != null && category.isNotEmpty && category != 'All') {
      filtered = filtered.where((event) {
        return event.category.toLowerCase() == category.toLowerCase();
      }).toList();
    }

    // Apply timeframe filter
    if (timeframe != null && timeframe.isNotEmpty) {
      if (timeframe == 'This Week') {
        final weekEnd = now.add(const Duration(days: 7));
        filtered = filtered.where((event) {
          return event.date.isAfter(now) && event.date.isBefore(weekEnd);
        }).toList();
      } else if (timeframe == 'New Shows') {
        // Events added in the last 7 days (mock: just show all for now)
        filtered = filtered.where((event) => event.date.isAfter(now)).toList();
      } else if (timeframe == 'Late Night') {
        filtered = filtered.where((event) {
          return event.date.hour >= 21; // After 9 PM
        }).toList();
      }
    }

    if (filtered.isEmpty) {
      emit(EventEmpty());
    } else {
      emit(EventLoaded(events: filtered));
    }
  }

  /// Get events near a location (within radius)
  List<EventModel> getNearbyEvents(List<EventModel> events, {int limit = 10}) {
    // For now, return all events sorted by date
    // In production, this would use geolocation distance calculation
    final sorted = List<EventModel>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.take(limit).toList();
  }

  /// Get popular events (by stock sold percentage)
  List<EventModel> getPopularEvents(List<EventModel> events, {int limit = 10}) {
    final sorted = List<EventModel>.from(events)
      ..sort((a, b) {
        final aProgress = a.stockProgress;
        final bProgress = b.stockProgress;
        return bProgress.compareTo(aProgress);
      });
    return sorted.take(limit).toList();
  }

  // ========================================
  // FAVORITES METHODS - OPTIMISTIC UI + BACKEND SYNC
  // ========================================

  /// Toggle favorite status for an event
  /// OPTIMISTIC UI: Updates immediately, reverts on error
  Future<void> toggleFavorite(int eventId) async {
    final currentState = state;
    
    // STEP 1: OPTIMISTIC UPDATE - Update UI immediately
    if (currentState is EventLoaded) {

final updatedEvents = currentState.events.map((event) {
        if (event.id == eventId) {
          return event.copyWith(isFavorite: !event.isFavorite);
        }
        return event;
      }).toList();
      
      // Emit updated state immediately (UI updates instantly)
      emit(EventLoaded(
        events: updatedEvents,
        isAIRecommended: currentState.isAIRecommended,
      ));
    }
    
    // STEP 2: SYNC WITH BACKEND
    try {
      
      await _apiService.toggleFavorite(eventId);

// STEP 3: REFRESH FROM BACKEND to get accurate state
      // This ensures we have the latest data from Django
      await fetchEvents();
    } catch (e) {

// STEP 4: REVERT OPTIMISTIC UPDATE on error
      if (currentState is EventLoaded) {

final revertedEvents = currentState.events.map((event) {
          if (event.id == eventId) {
            // Revert to original state
            return event.copyWith(isFavorite: !event.isFavorite);
          }
          return event;
        }).toList();
        
        emit(EventLoaded(
          events: revertedEvents,
          isAIRecommended: currentState.isAIRecommended,
        ));
      }
      
      // Don't throw - just log the error
      // UI already reverted, no need to show error state
      
    }
  }

  /// Fetch all favorite events from backend
  Future<void> fetchFavorites() async {
    emit(EventLoading());
    
    try {

final favorites = await _apiService.fetchFavorites();
      
      if (favorites.isEmpty) {
        
        emit(EventEmpty());
        return;
      }

emit(EventLoaded(events: favorites));
    } catch (e) {
      
      emit(EventError(message: 'Failed to load favorites'));
    }
  }
}
