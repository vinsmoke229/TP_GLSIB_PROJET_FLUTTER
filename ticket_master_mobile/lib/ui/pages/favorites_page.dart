import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/app/resources/constant/named_routes.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/data/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// FAVORITES PAGE - Professional Design with Real-Time Sync
/// ============================================================================
/// Features:
/// - Segmented filter: All, Active, Inactive
/// - Real-time synchronization across app
/// - Professional card design with image, heart, rating
/// - Empty state with "Browse Events" button
/// - Emerald Green theme
/// ============================================================================

enum FavoriteFilter { all, active, inactive }

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  FavoriteFilter _selectedFilter = FavoriteFilter.all;

  @override
  void initState() {
    super.initState();
    // Fetch favorites from backend
    context.read<EventCubit>().fetchFavorites();
  }

  List<EventModel> _filterFavorites(List<EventModel> favorites) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case FavoriteFilter.all:
        return favorites;
      case FavoriteFilter.active:
        return favorites.where((e) => e.date.isAfter(now)).toList();
      case FavoriteFilter.inactive:
        return favorites.where((e) => e.date.isBefore(now)).toList();
    }
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
              child: _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with title and menu
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Favoris',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
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

  /// Segmented Filter: All, Active, Inactive
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
              'Tous',
              FavoriteFilter.all,
              Icons.grid_view,
            ),
            _buildFilterButton(
              'Actifs',
              FavoriteFilter.active,
              Icons.event_available,
            ),
            _buildFilterButton(
              'Inactifs',
              FavoriteFilter.inactive,
              Icons.event_busy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, FavoriteFilter filter, IconData icon) {
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
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Favorites List
  Widget _buildFavoritesList() {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        if (state is EventLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (state is EventError) {
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
                    context.read<EventCubit>().fetchFavorites();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is EventLoaded) {
          // fetchFavorites() already returns only favorites
          final filteredFavorites = _filterFavorites(state.events);

          if (state.events.isEmpty) {
            return _buildEmptyState();
          }

          if (filteredFavorites.isEmpty) {
            return _buildNoResultsForFilter();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteCard(filteredFavorites[index]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Favorite Event Card - Professional Design
  Widget _buildFavoriteCard(EventModel event) {
    final now = DateTime.now();
    final isActive = event.date.isAfter(now);
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NamedRoutes.detailScreen,
          arguments: event.toJson(),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with heart icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: event.image,
                    width: 120,
                    height: 140,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.greyTextColor.withValues(alpha: 0.2),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primaryLightColor,
                      child: const Icon(
                        Icons.event,
                        size: 40,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                
                // Heart icon (top-right of image)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await context.read<EventCubit>().toggleFavorite(event.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${event.titre} a été retiré des favoris'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                
                // Status badge (Active/Inactive)
                if (!isActive)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Passé',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.lieu,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.timeRange.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.timeRange,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      event.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Date
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy, hh:mm a').format(event.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Footer: Price and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        const Text(
                          'de 25 000 FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        
                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State - No Favorites Yet
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
                Icons.favorite_border,
                size: 70,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Aucun Favori',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Commencez à explorer et enregistrez les événements\nque vous aimez pour les voir ici',
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
                  // Navigate to Home tab (index 0)
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.explore),
                label: const Text('Parcourir les événements'),
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
    String message = '';
    switch (_selectedFilter) {
      case FavoriteFilter.active:
        message = 'Aucun événement actif dans vos favoris';
        break;
      case FavoriteFilter.inactive:
        message = 'Aucun événement passé dans vos favoris';
        break;
      default:
        message = 'Aucun favori trouvé';
    }

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
                  _selectedFilter = FavoriteFilter.all;
                });
              },
              child: const Text(
                'Show All',
                style: TextStyle(
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
              title: const Text('Rafraîchir'),
              onTap: () {
                Navigator.pop(context);
                context.read<EventCubit>().fetchFavorites();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort, color: AppColors.primaryColor),
              title: const Text('Trier par date'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonction de tri bientôt disponible !'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Effacer tous les favoris'),
              onTap: () {
                Navigator.pop(context);
                _showClearAllDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Clear All Favorites Dialog
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer tous les favoris ?'),
        content: const Text(
          'Cela supprimera tous les événements de vos favoris. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Get all favorite events and toggle them
              final state = context.read<EventCubit>().state;
              if (state is EventLoaded) {
                final favorites = state.events.where((e) => e.isFavorite).toList();
                for (var event in favorites) {
                  await context.read<EventCubit>().toggleFavorite(event.id);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tous les favoris ont été supprimés'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Effacer tout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
