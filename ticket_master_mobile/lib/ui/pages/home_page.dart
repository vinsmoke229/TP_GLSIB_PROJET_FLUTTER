import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/app/resources/constant/named_routes.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/data/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedTimeframe;

  @override
  void initState() {
    super.initState();
    context.read<EventCubit>().fetchEvents();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Use backend search for real-time results
    if (_searchQuery.isNotEmpty) {
      context.read<EventCubit>().searchEvents(_searchQuery);
    } else {
      // If search is empty, fetch all events
      context.read<EventCubit>().fetchEvents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            _buildSearchBar(),
            _buildTimeFilters(),
            _buildCategoriesRow(),
            _buildDiscoveryCard(),
            _buildPopularSection(),
          ],
        ),
      ),
    );
  }

  /// 1. HEADER & GLOBAL SEARCH - Sliver App Bar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      pinned: false,
      floating: true,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  // Notification icon with badge
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Notifications bientôt disponibles !'),
                              backgroundColor: AppColors.primaryColor,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimaryColor,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
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
    );
  }

  /// Search Bar with Filter
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          height: 50,
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
              const SizedBox(width: 16),
              const Icon(Icons.search, color: AppColors.textSecondaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher des événements...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.greyTextColor.withValues(alpha: 0.2),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primaryColor),
                onPressed: () {
                  _showFilterBottomSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. QUICK TIME-FILTERS (3 Cards)
  Widget _buildTimeFilters() {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(top: 24),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          children: [
            _buildTimeFilterCard(
              'Cette semaine',
              Icons.calendar_today,
              LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.8)
                ],
              ),
              Colors.white,
            ),
            const SizedBox(width: 12),
            _buildTimeFilterCard(
              'Nouveaux spectacles',
              Icons.fiber_new,
              const LinearGradient(
                colors: [Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
              ),
              AppColors.textPrimaryColor,
            ),
            const SizedBox(width: 12),
            _buildTimeFilterCard(
              'Soirée',
              Icons.nightlight_round,
              const LinearGradient(
                colors: [Color(0xFF2D3748), Color(0xFF1A202C)],
              ),
              Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterCard(
      String title, IconData icon, Gradient gradient, Color textColor) {
    final isSelected = _selectedTimeframe == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframe = isSelected ? null : title;
        });
        _applyFilters();
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: textColor, size: 28),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. CATEGORIES ROW
  Widget _buildCategoriesRow() {
    final categories = [
      {
        'name': 'Tous',
        'image':
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&q=80'
      },
      {
        'name': 'Tourisme',
        'image':
            'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=200&q=80'
      },
      {
        'name': 'Musique',
        'image':
            'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=200&q=80'
      },
      {
        'name': 'Tech',
        'image':
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=200&q=80'
      },
      {
        'name': 'Sport',
        'image':
            'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=200&q=80'
      },
      {
        'name': 'Art',
        'image':
            'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=200&q=80'
      },
      {
        'name': 'Gastronomie',
        'image':
            'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=200&q=80'
      },
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              'Catégories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory =
                          category['name'] == 'All' ? null : category['name'];
                    });
                    _applyFilters();
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primaryColor, width: 3)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: category['image']!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.greyTextColor
                                    .withValues(alpha: 0.2),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primaryLightColor,
                                child: const Icon(Icons.category,
                                    color: AppColors.primaryColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
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
  }

  /// 4. DISCOVERY PROMOTIONAL CARD
  Widget _buildDiscoveryCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.explore,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Trouvez votre prochaine\ngrande expérience',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Parcourez les événements et découvrez ce qui vous passionne',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/discovery');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Commencez à explorer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. POPULAR EVENTS (Vertical List)
  Widget _buildPopularSection() {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        if (state is EventLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
            ),
          );
        }

        if (state is EventError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.greyTextColor),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<EventCubit>().fetchEvents(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is EventLoaded) {
          final popularEvents = context
              .read<EventCubit>()
              .getPopularEvents(state.events, limit: 20);

          if (popularEvents.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Aucun événement trouvé'),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Événements populaires',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/discovery');
                          },
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildPopularEventCard(popularEvents[index - 1]);
              },
              childCount: popularEvents.length + 1,
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildPopularEventCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NamedRoutes.detailScreen,
          arguments: event.toJson(),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: event.image,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.greyTextColor.withValues(alpha: 0.2),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLightColor,
                  child: const Icon(Icons.event,
                      size: 40, color: AppColors.primaryColor),
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.titre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await context
                                .read<EventCubit>()
                                .toggleFavorite(event.id);
                          },
                          child: Icon(
                            event.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: event.isFavorite
                                ? Colors.red
                                : AppColors.textSecondaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        const Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.textSecondaryColor),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(event.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (event.timeRange.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: AppColors.textSecondaryColor),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  /// Filter Bottom Sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Tous',
                'Musique',
                'Tech',
                'Sport',
                'Art',
                'Gastronomie',
                'Tourisme'
              ].map((cat) {
                final isSelected =
                    _selectedCategory == (cat == 'Tous' ? null : cat);
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat == 'Tous' ? null : cat;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.primaryColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? Colors.white : AppColors.textPrimaryColor,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Période',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Tous',
                'Cette Semaine',
                'Nouveaux Spectacles',
                'Soirée Tardive'
              ].map((time) {
                final isSelected =
                    _selectedTimeframe == (time == 'Tous' ? null : time);
                return FilterChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeframe = time == 'Tous' ? null : time;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.primaryColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? Colors.white : AppColors.textPrimaryColor,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedTimeframe = null;
                    _searchController.clear();
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Clear All Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
