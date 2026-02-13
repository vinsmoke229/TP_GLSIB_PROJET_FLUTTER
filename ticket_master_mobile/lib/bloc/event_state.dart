part of 'event_cubit.dart';

/// ============================================================================
/// EVENT STATES - Django REST API Integration
/// ============================================================================

abstract class EventState {}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<EventModel> events;
  final bool isAIRecommended;

  EventLoaded({
    required this.events,
    this.isAIRecommended = false,
  });
}

class EventDetailLoaded extends EventState {
  final EventModel event;

  EventDetailLoaded({required this.event});
}

class EventEmpty extends EventState {}

class EventError extends EventState {
  final String message;

  EventError({required this.message});
}
