import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/booking_cubit.dart';
import 'package:event_app/data/achat_model.dart';
import 'package:event_app/ui/widgets/ticket_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ============================================================================
/// MY TICKETS PAGE - Professional Ticket Management
/// ============================================================================
/// Features:
/// - Segmented filter: Upcoming / Past tickets
/// - Professional ticket cards with seat info
/// - QR Code bottom sheet with gate/row/seat
/// - Search functionality
/// - Emerald Green theme
/// ============================================================================

enum TicketFilter { upcoming, past }

class TicketsListPage extends StatefulWidget {
  const TicketsListPage({super.key});

  @override
  State<TicketsListPage> createState() => _TicketsListPageState();
}

class _TicketsListPageState extends State<TicketsListPage> {
  TicketFilter _selectedFilter = TicketFilter.upcoming;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<BookingCubit>().loadUserBookings();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AchatModel> _filterTickets(List<AchatModel> tickets) {
    // Apply search filter only
    var filtered = tickets.where((ticket) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return ticket.eventTitre.toLowerCase().contains(query) ||
          ticket.eventLieu.toLowerCase().contains(query);
    }).toList();

    // TRUST DJANGO ORDERING: No local sorting
    // Django sends data with order_by('-id_achat'), so newest is already first

if (filtered.isNotEmpty) {
      
      if (filtered.length > 1) {
        
      }
    }
    
    return filtered;
    
    // Original filter logic (DISABLED - showing all tickets for debugging)
    /*
    switch (_selectedFilter) {
      case TicketFilter.upcoming:
        return filtered.where((t) => t.isUpcoming).toList();
      case TicketFilter.past:
        return filtered.where((t) => t.isCompleted).toList();
    }
    */
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
            _buildSegmentedFilter(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildTicketsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with title, search, and menu
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'My Tickets',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
            icon: const Icon(
              Icons.search,
              color: AppColors.textPrimaryColor,
            ),
          ),
          IconButton(
            onPressed: () {
              _showOptionsMenu();
            },
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented Filter: Upcoming / Past
  Widget _buildSegmentedFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
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
        child: Row(
          children: [
            _buildFilterButton(
              'À venir',
              TicketFilter.upcoming,
              Icons.event_available,
            ),
            _buildFilterButton(
              'Billets Passés',
              TicketFilter.past,
              Icons.history,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, TicketFilter filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textSecondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tickets List
  Widget _buildTicketsList() {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (state is BookingError) {
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
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
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<BookingCubit>().loadUserBookings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is UserBookingsLoaded) {
          final filteredTickets = _filterTickets(state.bookings);

          if (state.bookings.isEmpty) {
            return _buildEmptyState();
          }

          if (filteredTickets.isEmpty) {
            return _buildNoResultsForFilter();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filteredTickets.length,
            itemBuilder: (context, index) {
              final ticket = filteredTickets[index];
              return TicketCard(
                ticket: ticket,
                onShowQRCode: () => _showQRCodeSheet(ticket),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

/// QR Code Bottom Sheet
  void _showQRCodeSheet(AchatModel ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyTextColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'QR Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.eventTitre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.greyTextColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ticket.qrCodeUrl != null && ticket.qrCodeUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ticket.qrCodeUrl!,
                          width: 220,
                          height: 220,
                          placeholder: (context, url) => const SizedBox(
                            width: 220,
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => QrImageView(
                            data: ticket.qrCode,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        )
                      : QrImageView(
                          data: ticket.qrCode,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                ),
                const SizedBox(height: 24),
                
                // Status badge if used
                if (ticket.estUtilise)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Ticket utilisé',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (ticket.dateUtilisation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Le ${DateFormat("dd/MM/yyyy à HH:mm").format(ticket.dateUtilisation!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                
                // Seat Details Row
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSeatInfo('GATE', ticket.gate),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                      ),
                      _buildSeatInfo('ROW', ticket.row),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                      ),
                      _buildSeatInfo('SEAT', ticket.seat),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Ticket info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Ticket Type', ticket.ticketType),
                      const SizedBox(height: 12),
                      _buildInfoRow('Quantity', '${ticket.quantite}'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Total Price', '${NumberFormat('#,###', 'fr_FR').format(ticket.montantTotal)} FCFA'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Booking ID', '#${ticket.id.toString().padLeft(6, '0')}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  /// Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.primaryLightColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 70,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Aucun Billet Trouvé',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Réservez votre premier événement et\nvos billets apparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.explore),
                label: const Text('Réserver un Événement'),
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
          ],
        ),
      ),
    );
  }

  /// No Results for Current Filter
  Widget _buildNoResultsForFilter() {
    String message = _selectedFilter == TicketFilter.upcoming
        ? 'Aucun billet à venir'
        : 'Aucun billet passé';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primaryLightColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off,
                size: 50,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = _selectedFilter == TicketFilter.upcoming
                      ? TicketFilter.past
                      : TicketFilter.upcoming;
                });
              },
              child: Text(
                'Afficher les Billets ${_selectedFilter == TicketFilter.upcoming ? "Passés" : "À venir"}',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search Dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher des Billets'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Entrez le nom de l\'événement ou le lieu...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  /// Options Menu
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.primaryColor),
              title: const Text('Actualiser'),
              onTap: () {
                Navigator.pop(context);
                context.read<BookingCubit>().loadUserBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.primaryColor),
              title: const Text('Télécharger Tous les Billets'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité de téléchargement bientôt disponible !'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
