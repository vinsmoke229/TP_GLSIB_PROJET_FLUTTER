import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:event_app/bloc/booking_cubit.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/data/event_model.dart';
import 'package:event_app/data/session_model.dart';
import 'package:event_app/data/ticket_model.dart';
import 'package:event_app/ui/pages/main_screen.dart';
import 'package:event_app/services/map_service.dart';
import 'package:event_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// EVENT DETAIL PAGE - Simplified & Stable
class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  EventModel? _event;
  List<TicketModel> _tickets = [];

  // Session selection state
  DateTime? _selectedDate;
  SessionModel? _selectedSession;
  final Map<int, int> _ticketQuantities = {};
  bool _isAboutExpanded = false;

  // GPS Navigation
  final MapService _mapService = MapService();
  double? _distanceToEvent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _event = EventModel.fromJson(args);
      _fetchDetailedEvent();
      context.read<BookingCubit>().loadTickets(_event!.id);
    }
  }

  Future<void> _fetchDetailedEvent() async {
    if (_event == null) return;

    try {
      final apiService = ApiService();
      final detailedEvent = await apiService.getEventById(_event!.id);

      if (mounted) {
        setState(() {
          _event = detailedEvent;

          if (_event!.sessions.isNotEmpty) {
            final firstSessionDate = _event!.sessions.first.dateOnly;
            _selectedDate = firstSessionDate;

            final sessionsForDate =
                _event!.getSessionsForDate(firstSessionDate);
            if (sessionsForDate.isNotEmpty) {
              _selectedSession = sessionsForDate.first;
            }
          } else {
            _selectedDate = _event!.date;
          }
        });

        _calculateDistanceToEvent();
      }
    } catch (e) {
      if (mounted && _event!.sessions.isEmpty) {
        setState(() {
          _selectedDate = _event!.date;
        });
      }
    }
  }

  Future<void> _calculateDistanceToEvent() async {
    if (_event?.hasValidGPS == true) {
      try {
        final distance = await _mapService.getDistanceToDestination(
          destLat: _event!.latitude!,
          destLon: _event!.longitude!,
        );

        if (distance != null && mounted) {
          setState(() {
            _distanceToEvent = distance;
          });
        }
      } catch (e) {
        // Ignore distance calculation errors
      }
    }
  }

  double get _totalPrice {
    double total = 0;
    for (var entry in _ticketQuantities.entries) {
      final ticket = _tickets.firstWhere((t) => t.id == entry.key);
      total += ticket.prix * entry.value;
    }
    return total;
  }

  int get _totalQuantity {
    return _ticketQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  void _incrementQuantity(int ticketId) {
    setState(() {
      _ticketQuantities[ticketId] = (_ticketQuantities[ticketId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(int ticketId) {
    setState(() {
      final current = _ticketQuantities[ticketId] ?? 0;
      if (current > 0) {
        _ticketQuantities[ticketId] = current - 1;
        if (_ticketQuantities[ticketId] == 0) {
          _ticketQuantities.remove(ticketId);
        }
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(),
                _buildOrganizerCard(),
                _buildAboutSection(),
                _buildQuickInfoGrid(),
                _buildRatingsSection(),
                _buildSessionSelector(),
                _buildTicketSelector(),
                _buildGallerySection(),
                _buildLocationSection(),
                _buildRecommendations(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: _event!.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.greyTextColor.withValues(alpha: 0.2),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLightColor,
                  child: const Icon(Icons.event,
                      size: 80, color: AppColors.primaryColor),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _event!.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _event!.isFavorite
                              ? Colors.red
                              : AppColors.textPrimaryColor,
                        ),
                        onPressed: () async {
                          await context
                              .read<EventCubit>()
                              .toggleFavorite(_event!.id);
                          setState(() {
                            _event = _event!
                                .copyWith(isFavorite: !_event!.isFavorite);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _event!.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _event!.titre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&q=80',
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLightColor,
                  child:
                      const Icon(Icons.business, color: AppColors.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EventMaster Lomé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people,
                        size: 14, color: AppColors.textSecondaryColor),
                    SizedBox(width: 4),
                    Text(
                      '12.5K followers',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side:
                    const BorderSide(color: AppColors.primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    const aboutText =
        'Vivez une soirée inoubliable sous les étoiles lors de cet événement spectaculaire. '
        'Rejoignez-nous pour une nuit de performances incroyables, de délicieux repas et d\'une compagnie merveilleuse.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos de l\'événement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isAboutExpanded ? aboutText : aboutText.substring(0, 100) + '...',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isAboutExpanded = !_isAboutExpanded;
              });
            },
            child: Text(
              _isAboutExpanded ? 'Lire moins' : 'Lire la suite',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de l\'événement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  FontAwesomeIcons.calendar,
                  'Date',
                  DateFormat('MMM d, yyyy').format(_event!.date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  FontAwesomeIcons.clock,
                  'Heure',
                  _event!.timeRange.isNotEmpty 
                      ? _event!.timeRange 
                      : DateFormat('HH:mm').format(_event!.date),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLightColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évaluations & Avis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '4.9',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return const Icon(Icons.star,
                          color: Colors.amber, size: 20);
                    }),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Basé sur 2 847 avis',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSelector() {
    if (_event == null) {
      return const SizedBox.shrink();
    }

    final availableDates =
        _event!.sessions.isNotEmpty ? _event!.availableDates : [_event!.date];

    final List<SessionModel> sessionsForDate =
        _selectedDate != null && _event!.sessions.isNotEmpty
            ? _event!.getSessionsForDate(_selectedDate!)
            : [];

    final hasRealSessions = _event!.sessions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionner Date & Heure',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSimpleDateList(availableDates),
          const SizedBox(height: 24),
          if (hasRealSessions &&
              _selectedDate != null &&
              sessionsForDate.isNotEmpty) ...[
            const Text(
              'Horaires Disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildTimeSlotGrid(sessionsForDate),
          ] else if (hasRealSessions && _selectedDate == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLightColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: AppColors.primaryColor, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sélectionnez une date pour voir les horaires disponibles',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!hasRealSessions) ...[
            const Text(
              'Horaires Disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildDefaultTimeSlot(),
          ],
          if (_selectedSession == null && hasRealSessions) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Veuillez sélectionner une date et une heure',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleDateList(List<DateTime> availableDates) {
    if (availableDates.isEmpty) return const SizedBox.shrink();

    final monthNames = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected =
              _selectedDate != null && _isSameDay(_selectedDate!, date);
          final isToday = _isSameDay(DateTime.now(), date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;

                final sessions = _event!.getSessionsForDate(date);
                if (sessions.isNotEmpty) {
                  _selectedSession = sessions.first;
                }
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primaryColor, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthNames[date.month - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE', 'fr_FR').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<SessionModel> sessions) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sessions.map((session) {
        final isSelected = _selectedSession?.id == session.id;
        final isLowStock = session.isLowStock;
        final isSoldOut = session.isSoldOut;

        return GestureDetector(
          onTap: isSoldOut
              ? null
              : () {
                  setState(() {
                    _selectedSession = session;
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSoldOut
                  ? AppColors.greyTextColor.withValues(alpha: 0.1)
                  : isSelected
                      ? AppColors.primaryColor
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSoldOut
                    ? AppColors.greyTextColor.withValues(alpha: 0.3)
                    : isSelected
                        ? AppColors.primaryColor
                        : AppColors.greyTextColor.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isSoldOut
                      ? AppColors.greyTextColor
                      : isSelected
                          ? Colors.white
                          : AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  session.formattedTime,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSoldOut
                        ? AppColors.greyTextColor
                        : isSelected
                            ? Colors.white
                            : AppColors.textPrimaryColor,
                    decoration: isSoldOut ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isLowStock && !isSoldOut) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${session.placesDisponibles}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDefaultTimeSlot() {
    final defaultTime = _event!.timeRange.isNotEmpty
        ? _event!.timeRange
        : DateFormat('HH:mm').format(_event!.date);
    final isSelected = _selectedDate != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = _event!.date;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.greyTextColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              defaultTime,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSelector() {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is TicketsLoaded) {
          _tickets = state.tickets;

          return Container(
            margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Tickets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...state.tickets
                    .map((ticket) => _buildTicketTier(ticket))
                    .toList(),
              ],
            ),
          );
        }

        if (state is BookingLoading) {
          return Container(
            margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }

        // Handle error state
        if (state is BookingError) {
          return Container(
            margin: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange.shade700, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Aucun ticket disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTicketTier(TicketModel ticket) {
    final quantity = _ticketQuantities[ticket.id] ?? 0;
    final isLowStock = ticket.stock < 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0
              ? AppColors.primaryColor
              : AppColors.greyTextColor.withValues(alpha: 0.2),
          width: quantity > 0 ? 2 : 1,
        ),
        boxShadow: [
          if (quantity > 0)
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(ticket.prix)} FCFA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 0
                          ? () => _decrementQuantity(ticket.id)
                          : null,
                      icon: const Icon(Icons.remove, size: 20),
                      color: quantity > 0
                          ? AppColors.primaryColor
                          : AppColors.greyTextColor,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < ticket.stock
                          ? () => _incrementQuantity(ticket.id)
                          : null,
                      icon: const Icon(Icons.add, size: 20),
                      color: quantity < ticket.stock
                          ? AppColors.primaryColor
                          : AppColors.greyTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isLowStock ? Icons.warning_amber : Icons.check_circle,
                size: 14,
                color: isLowStock ? Colors.orange : AppColors.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                isLowStock
                    ? 'Seulement ${ticket.stock} restant${ticket.stock > 1 ? 's' : ''} !'
                    : '${ticket.stock} disponible${ticket.stock > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isLowStock ? Colors.orange : AppColors.textSecondaryColor,
                  fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    final galleryImages = [
      'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400&q=80',
      'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&q=80',
      'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&q=80',
      'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=400&q=80',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Galerie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: galleryImages[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.greyTextColor.withValues(alpha: 0.2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.primaryLightColor,
                    child:
                        const Icon(Icons.image, color: AppColors.primaryColor),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasGPS = _event?.hasValidGPS == true;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localisation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _event!.lieu,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                          if (_distanceToEvent != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  size: 12,
                                  color: AppColors.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_distanceToEvent!.toStringAsFixed(1)} km de vous',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: hasGPS
                      ? () async {
                          try {
                            await _mapService.openMapsLocation(
                              lat: _event!.latitude!,
                              lon: _event!.longitude!,
                              locationName: _event!.lieu,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Impossible d\'ouvrir la carte: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.greyTextColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: hasGPS
                          ? Border.all(
                              color:
                                  AppColors.primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasGPS ? Icons.map : Icons.location_off,
                            size: 40,
                            color: hasGPS
                                ? AppColors.primaryColor
                                : AppColors.greyTextColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasGPS
                                ? 'Appuyer pour voir sur la carte'
                                : 'GPS Non Disponible',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasGPS
                                  ? AppColors.primaryColor
                                  : AppColors.greyTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasGPS
                        ? () async {
                            try {
                              await _mapService.openMapsItinerary(
                                destLat: _event!.latitude!,
                                destLon: _event!.longitude!,
                                destName: _event!.lieu,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Impossible d\'ouvrir les directions: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.directions, size: 20),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasGPS
                          ? AppColors.primaryColor
                          : AppColors.greyTextColor.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        if (state is! EventLoaded) {
          return const SizedBox.shrink();
        }

        final similarEvents = state.events
            .where((e) => e.category == _event!.category && e.id != _event!.id)
            .take(5)
            .toList();

        if (similarEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vous allez adorer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: similarEvents.length,
                  itemBuilder: (context, index) {
                    final event = similarEvents[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/detail',
                          arguments: event.toJson(),
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: event.image,
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.greyTextColor
                                      .withValues(alpha: 0.2),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.primaryLightColor,
                                  child: const Icon(Icons.event,
                                      color: AppColors.primaryColor),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.titre,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d').format(event.date),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar() {
    final hasRealSessions = _event!.sessions.isNotEmpty;
    final isSessionSelected =
        hasRealSessions ? _selectedSession != null : _selectedDate != null;
    final canPurchase = _totalQuantity > 0 && isSessionSelected;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Prix Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(_totalPrice)} FCFA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (_totalQuantity > 0)
                      Text(
                        '$_totalQuantity billet${_totalQuantity > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BlocConsumer<BookingCubit, BookingState>(
                  listener: (context, state) {
                    if (state is BookingSuccess) {
                      // PRODUCTION: Immediately refresh balance from PostgreSQL
                      context.read<AuthCubit>().refreshUser();
                      _showSuccessDialog(state.booking);
                    } else if (state is BookingError) {
                      if (state.message.contains('Insufficient balance') ||
                          state.message.contains('solde insuffisant') ||
                          state.message.contains('Solde insuffisant')) {
                        _showInsufficientFundsSheet();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    final user = context.read<AuthCubit>().currentUser;
                    final hasBalance =
                        user != null && user.solde >= _totalPrice;

                    return SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canPurchase && state is! BookingLoading
                            ? () {
                                if (!hasBalance) {
                                  _showInsufficientFundsSheet();
                                } else {
                                  _handlePurchase();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPurchase
                              ? AppColors.primaryColor
                              : AppColors.greyTextColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.greyTextColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: state is BookingLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _totalQuantity == 0
                                    ? 'Sélectionner Billets'
                                    : !isSessionSelected
                                        ? 'Choisir Date & Heure'
                                        : !hasBalance
                                            ? 'Recharger'
                                            : 'Acheter',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePurchase() {
    if (_ticketQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un billet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Only check session selection if event has sessions
    final hasSessions = _event?.sessions.isNotEmpty ?? false;
    if (hasSessions && _selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date et une heure'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Purchase tickets (sessionId is optional - null for events without sessions)
    for (var entry in _ticketQuantities.entries) {
      context.read<BookingCubit>().purchaseTicket(
            ticketId: entry.key,
            quantity: entry.value,
            sessionId: _selectedSession?.id, // null si pas de sessions
          );
    }
  }

  void _showInsufficientFundsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final user = context.read<AuthCubit>().currentUser;
          final currentBalance = user?.solde ?? 0.0;
          final needed = _totalPrice - currentBalance;
          final hasSufficientFunds = currentBalance >= _totalPrice;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.greyTextColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLightColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasSufficientFunds
                                ? Icons.check_circle
                                : Icons.account_balance_wallet_rounded,
                            size: 40,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        if (!hasSufficientFunds)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.warning_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      hasSufficientFunds
                          ? 'Solde Suffisant !'
                          : 'Solde Insuffisant',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: hasSufficientFunds
                            ? AppColors.primaryColor
                            : AppColors.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (hasSufficientFunds)
                      const Text(
                        'Votre solde a été rechargé avec succès. Vous pouvez maintenant acheter vos billets !',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryColor,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'Votre solde actuel est de '),
                            TextSpan(
                              text:
                                  '${NumberFormat('#,###', 'fr_FR').format(currentBalance)} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryColor,
                              ),
                            ),
                            const TextSpan(text: '. Vous avez besoin de '),
                            TextSpan(
                              text:
                                  '${NumberFormat('#,###', 'fr_FR').format(_totalPrice)} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const TextSpan(
                                text: ' pour finaliser cette commande.'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (hasSufficientFunds)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handlePurchase();
                          },
                          icon: const Icon(Icons.shopping_cart, size: 22),
                          label: const Text(
                            'Acheter maintenant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLightColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Montant à recharger',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  '+${NumberFormat('#,###', 'fr_FR').format(needed)} FCFA',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Recharge Rapide',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await context
                                      .read<AuthCubit>()
                                      .rechargeWallet(needed);
                                  setModalState(() {});
                                  if (mounted) {
                                    final user =
                                        context.read<AuthCubit>().currentUser;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Portefeuille rechargé ! Nouveau solde : ${NumberFormat('#,###', 'fr_FR').format(user?.solde ?? 0)} FCFA',
                                        ),
                                        backgroundColor: AppColors.primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Erreur de recharge : ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.bolt, size: 22),
                              label: Text(
                                'Recharger ${NumberFormat('#,###', 'fr_FR').format(needed)} FCFA',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickRechargeButton(
                                    5000, setModalState),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickRechargeButton(
                                    10000, setModalState),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickRechargeButton(
                                    25000, setModalState),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickRechargeButton(
                                    50000, setModalState),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (!hasSufficientFunds)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Plus tard',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickRechargeButton(int amount, StateSetter setModalState) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await context.read<AuthCubit>().rechargeWallet(amount.toDouble());
            setModalState(() {});
            if (mounted) {
              final user = context.read<AuthCubit>().currentUser;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Portefeuille rechargé ! Nouveau solde : ${NumberFormat('#,###', 'fr_FR').format(user?.solde ?? 0)} FCFA',
                  ),
                  backgroundColor: AppColors.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur de recharge : ${e.toString()}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          '+${NumberFormat('#,###', 'fr_FR').format(amount)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(dynamic booking) {
    final sessionTime = _selectedSession != null
        ? _selectedSession!.formattedTime
        : DateFormat('HH:mm').format(_event!.date);
    final sessionDate = _selectedDate != null
        ? DateFormat('EEEE, MMMM d, yyyy', 'fr_FR').format(_selectedDate!)
        : DateFormat('EEEE, MMMM d, yyyy', 'fr_FR').format(_event!.date);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLightColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Achat réussi !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vous avez acheté avec succès $_totalQuantity billet${_totalQuantity > 1 ? 's' : ''} pour ${_event!.titre}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            sessionDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sessionTime,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainScreen(initialIndex: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Tickets',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
