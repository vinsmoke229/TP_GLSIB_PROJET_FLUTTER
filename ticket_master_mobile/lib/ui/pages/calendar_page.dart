import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/app/resources/constant/named_routes.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/data/event_model.dart';
import 'package:event_app/ui/widgets/card_event_this_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// CALENDAR PAGE - Events by Month
/// ============================================================================
/// Features:
/// - Dynamic monthly grouping
/// - Scrollable month headers
/// - Filter by date
/// - Professional calendar UI
/// ============================================================================

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    // Initialize to current month
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    // Fetch events when page loads
    context.read<EventCubit>().fetchEvents();
  }

  /// Navigate to previous month
  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  /// Navigate to next month
  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  /// Get events for current month
  List<EventModel> _getEventsForMonth(List<EventModel> events) {
    return events.where((event) {
      return event.date.year == _currentMonth.year &&
             event.date.month == _currentMonth.month;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildMonthNavigator(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendrier',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Parcourir les événements par mois',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              context.read<EventCubit>().fetchEvents();
            },
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build month navigator with arrows
  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous month button
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.primaryColor,
                size: 28,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            
            // Current month display
            Text(
              DateFormat.yMMMM('fr_FR').format(_currentMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            
            // Next month button
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.primaryColor,
                size: 28,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build events list
  Widget _buildEventsList() {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        if (state is EventLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        } else if (state is EventError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.greyTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<EventCubit>().fetchEvents();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is EventLoaded) {
          final monthEvents = _getEventsForMonth(state.events);
          
          if (monthEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppColors.greyTextColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun événement en ${DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Utilisez les flèches pour changer de mois',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.greyTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: monthEvents.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  NamedRoutes.detailScreen,
                  arguments: monthEvents[index].toJson(),
                ),
                child: CardEventThisMonth(eventModel: monthEvents[index]),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
