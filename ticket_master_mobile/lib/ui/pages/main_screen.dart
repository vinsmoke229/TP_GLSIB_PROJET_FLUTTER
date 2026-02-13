import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/ui/pages/home_page.dart';
import 'package:event_app/ui/pages/tickets_list_page.dart';
import 'package:event_app/ui/pages/explore_page.dart';
import 'package:event_app/ui/pages/discovery_page.dart';
import 'package:event_app/ui/pages/favorites_page.dart';
import 'package:event_app/ui/pages/profile_page.dart';
import 'package:event_app/services/api_service.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ============================================================================
/// MAIN SCREEN - 6-Tab Bottom Navigation Controller
/// ============================================================================
/// Features:
/// - 6-tab bottom navigation (Home, Tickets, Explore, Discovery, Favorites, Profile)
/// - Smooth transitions with IndexedStack
/// - AI Assistant FAB
/// - Professional navigation UX
/// ============================================================================

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Pages for each tab
  final List<Widget> _pages = const [
    HomePage(),
    TicketsListPage(),
    ExplorePage(),
    DiscoveryPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildAIAssistantFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Build Bottom Navigation Bar with 5 tabs
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.whiteColor,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.greyTextColor,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'Billets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search),
              label: 'Explorer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Découvrir',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  /// Build AI Assistant FAB
  Widget _buildAIAssistantFAB() {
    return FloatingActionButton(
      onPressed: _showAIRecommendationSheet,
      backgroundColor: AppColors.primaryColor,
      elevation: 4,
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showAIRecommendationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AIRecommendationBottomSheet(),
    );
  }
}

/// AI Recommendation Bottom Sheet Widget with Real API Integration
class _AIRecommendationBottomSheet extends StatefulWidget {
  @override
  State<_AIRecommendationBottomSheet> createState() =>
      _AIRecommendationBottomSheetState();
}

class _AIRecommendationBottomSheetState
    extends State<_AIRecommendationBottomSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _recommendation;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ApiService();
      final recommendation = await apiService.fetchAiRecommendation();

      if (mounted) {
        setState(() {
          _recommendation = recommendation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
                const SizedBox(height: 20),

                // AI Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLightColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Recommandation IA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Content based on state
                if (_isLoading)
                  _buildLoadingState()
                else if (_error != null)
                  _buildErrorState()
                else if (_recommendation != null)
                  _buildRecommendationContent()
                else
                  _buildEmptyState(),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Recherche de l\'événement parfait pour vous...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: AppColors.greyTextColor,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _fetchRecommendation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(
          Icons.search_off,
          size: 48,
          color: AppColors.greyTextColor,
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Aucune recommandation disponible pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecommendationContent() {
    final eventTitle = _recommendation!['event_title'] as String;
    final reason = _recommendation!['reason'] as String;
    final eventId = _recommendation!['event_id'] as int;

    return Column(
      children: [
        // Sparkle animation icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Transform.rotate(
                angle: value * 0.5,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Event title card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLightColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Événement recommandé',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                eventTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Reason with emerald green highlights
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryColor,
                height: 1.5,
              ),
              children: _buildReasonWithHighlights(reason),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.pop(context);
                    // Navigate to Discovery tab
                    final mainScreenState =
                        context.findAncestorStateOfType<_MainScreenState>();
                    mainScreenState?.setState(() {
                      mainScreenState._currentIndex = 3;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: const BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Commencer à Glisser',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!mounted) return;
                    Navigator.pop(context);

                    // STRATEGY: Try to find event in EventCubit first, then fetch from API
                    try {
                      if (!mounted) return;
                      final eventCubit = context.read<EventCubit>();
                      final currentState = eventCubit.state;

                      // Check if event is already loaded in EventCubit
                      if (currentState is EventLoaded) {
                        final event = currentState.events.firstWhere(
                          (e) => e.id == eventId,
                          orElse: () => currentState.events.first,
                        );

                        if (event.id == eventId) {
                          // Found exact match - navigate immediately
                          
                          if (!mounted) return;
                          Navigator.pushNamed(
                            context,
                            '/detail',
                            arguments: event.toJson(),
                          );
                          return;
                        }
                      }

                      // Event not in cache - fetch from API
                      
                      final apiService = ApiService();
                      final event = await apiService.getEventById(eventId);

// Navigate to detail page with real event data
                      if (!mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/detail',
                        arguments: event.toJson(),
                      );
                    } catch (e) {

// Show error snackbar
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Impossible de charger l\'événement'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Voir l\'\u00c9vénement',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build reason text with emerald green highlights for keywords
  List<TextSpan> _buildReasonWithHighlights(String reason) {
    final keywords = [
      'populaire',
      'favori',
      'recommandé',
      'préférences',
      'intéresser',
      'moment',
      'AI',
      'IA',
    ];

    final spans = <TextSpan>[];
    final words = reason.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isKeyword = keywords.any(
        (keyword) => word.toLowerCase().contains(keyword.toLowerCase()),
      );

      spans.add(
        TextSpan(
          text: word + (i < words.length - 1 ? ' ' : ''),
          style: TextStyle(
            color: isKeyword
                ? AppColors.primaryColor
                : AppColors.textSecondaryColor,
            fontWeight: isKeyword ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
    }

    return spans;
  }
}
