import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/app/resources/constant/named_routes.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/data/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// EXPLORE PAGE - Search & Categories Discovery
/// ============================================================================
/// Features:
/// - Real-time search with Django backend
/// - Popular search chips (Concerts, Festivals, Tech, Cinema)
/// - Visual categories grid with Unsplash images
/// - Event results display
/// - Emerald Green theme
/// ============================================================================

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Start with all events
    context.read<EventCubit>().fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<EventCubit>().fetchEvents();
      setState(() {
        _isSearching = false;
      });
    } else {
      context.read<EventCubit>().searchEvents(query);
      setState(() {
        _isSearching = true;
      });
    }
  }

  void _searchByTag(String tag) {
    _searchController.text = tag;
    _performSearch(tag);
  }

  void _searchByCategory(String category) {
    context.read<EventCubit>().fetchEventsByCategory(category);
    setState(() {
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isSearching) ...[
                      _buildPopularSearches(),
                      _buildCategoriesGrid(),
                    ],
                    _buildSearchResults(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Explorer',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          IconButton(
            onPressed: () {
              // Filter options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filtres avancés bientôt disponibles !'),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            icon: const Icon(
              Icons.tune,
              color: AppColors.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  hintText: 'Search events, artists, venues...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _performSearch(value);
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Popular Searches
  Widget _buildPopularSearches() {
    // CRITICAL: Use real keywords from Django database
    final popularTags = ['Music', 'Tech', 'Art', 'Sport', 'Food', 'Tourism'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularTags.map((tag) {
              return GestureDetector(
                onTap: () => _searchByTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Categories Grid
  Widget _buildCategoriesGrid() {
    final categories = [
      {
        'name': 'Musique',
        'image': 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80',
        'category': 'Music',  // CRITICAL: Match Django type_evenement exactly
      },
      {
        'name': 'Tech',
        'image': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80',
        'category': 'Tech',  // CRITICAL: Match Django type_evenement exactly
      },
      {
        'name': 'Sport',
        'image': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&q=80',
        'category': 'Sport',  // CRITICAL: Match Django type_evenement exactly
      },
      {
        'name': 'Art',
        'image': 'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=800&q=80',
        'category': 'Art',  // CRITICAL: Match Django type_evenement exactly
      },
      {
        'name': 'Gastronomie',
        'image': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80',
        'category': 'Food',  // CRITICAL: Match Django type_evenement exactly
      },
      {
        'name': 'Tourisme',
        'image': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&q=80',
        'category': 'Tourism',  // CRITICAL: Match Django type_evenement exactly
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcourir par Catégorie',
            style: TextStyle(
              fontSize: 18,
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(
                category['name']!,
                category['image']!,
                category['category']!,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Category Card
  Widget _buildCategoryCard(String name, String imageUrl, String category) {
    return GestureDetector(
      onTap: () => _searchByCategory(category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.greyTextColor.withValues(alpha: 0.2),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLightColor,
                  child: const Icon(
                    Icons.category,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              
              // Dark Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              
              // Category Name
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search Results
  Widget _buildSearchResults() {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        if (state is EventLoading) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
          );
        }

        if (state is EventError) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
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
            ),
          );
        }

        if (state is EventEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLightColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off,
                      size: 50,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucun événement trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Essayez de rechercher avec des mots-clés différents',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is EventLoaded && _isSearching) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.events.length} Results',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.events.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(state.events[index]);
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Event Card
  Widget _buildEventCard(EventModel event) {
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
            // Image
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
                            DateFormat('MMM d, yyyy').format(event.date),
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
                    
                    // Price
                    const Text(
                      'From 25 000 FCFA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
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
}
