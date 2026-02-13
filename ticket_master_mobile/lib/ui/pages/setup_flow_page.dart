import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// SETUP FLOW PAGE - 4-Step Personalization
/// ============================================================================
/// Features:
/// - Step 1: Location selection
/// - Step 2: Interests selection
/// - Step 3: Goals selection
/// - Step 4: Follow organizers
/// - Emerald Green theme
/// - Progress indicator
/// - Saves to UserModel
/// ============================================================================

class SetupFlowPage extends StatefulWidget {
  const SetupFlowPage({super.key});

  @override
  State<SetupFlowPage> createState() => _SetupFlowPageState();
}

class _SetupFlowPageState extends State<SetupFlowPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // User selections
  String _selectedCity = '';
  bool _isOtherCitySelected = false;
  final List<String> _selectedInterests = [];
  final List<String> _selectedGoals = [];
  final List<int> _followedOrganizers = [];

  // Location
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedCity.trim().isNotEmpty;
      case 1:
        return _selectedInterests.isNotEmpty;
      case 2:
        return _selectedGoals.isNotEmpty;
      case 3:
        return true; // Optional step
      default:
        return false;
    }
  }

  Future<void> _completeSetup() async {
    try {
      await context.read<AuthCubit>().completeSetup(
            city: _selectedCity,
            interests: _selectedInterests,
            goals: _selectedGoals,
            followedOrganizers: _followedOrganizers,
          );

      // CRITICAL: Mark setup as complete in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_setup_complete', true);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimaryColor),
                onPressed: _previousStep,
              )
            : null,
        title: _buildProgressIndicator(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildLocationStep(),
                _buildInterestsStep(),
                _buildGoalsStep(),
                _buildOrganizersStep(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index <= _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryColor
                : AppColors.greyTextColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  /// Step 1: Location
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Où êtes-vous situé ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nous vous montrerons les événements près de chez vous',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 40),

          // Popular cities
          const Text(
            'Villes populaires',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...['Lomé', 'Accra', 'Lagos', 'Abidjan', 'Dakar'].map((city) {
                return ActionChip(
                  label: Text(city),
                  onPressed: () {
                    setState(() {
                      _selectedCity = city;
                      _cityController.text = city;
                      _isOtherCitySelected = false;
                    });
                  },
                  backgroundColor:
                      _selectedCity == city && !_isOtherCitySelected
                          ? AppColors.primaryColor
                          : AppColors.backgroundColor,
                  labelStyle: TextStyle(
                    color: _selectedCity == city && !_isOtherCitySelected
                        ? Colors.white
                        : AppColors.textPrimaryColor,
                  ),
                );
              }),
              // Option "Autre"
              ActionChip(
                label: const Text('Autre'),
                onPressed: () {
                  setState(() {
                    _isOtherCitySelected = true;
                    _selectedCity = '';
                    _cityController.clear();
                  });
                },
                backgroundColor: _isOtherCitySelected
                    ? AppColors.primaryColor
                    : AppColors.backgroundColor,
                labelStyle: TextStyle(
                  color: _isOtherCitySelected
                      ? Colors.white
                      : AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),

          // Champ de saisie personnalisé (visible uniquement si "Autre" est sélectionné)
          if (_isOtherCitySelected) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _cityController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Entrez votre ville',
                hintText: 'Ex: Cotonou, Ouagadougou...',
                prefixIcon: const Icon(Icons.location_city,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.greyTextColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Step 2: Interests
  Widget _buildInterestsStep() {
    final interests = [
      {'name': 'Musique', 'icon': Icons.music_note},
      {'name': 'Sport', 'icon': Icons.sports_soccer},
      {'name': 'Technologie', 'icon': Icons.computer},
      {'name': 'Art', 'icon': Icons.palette},
      {'name': 'Gastronomie', 'icon': Icons.restaurant},
      {'name': 'Business', 'icon': Icons.business_center},
      {'name': 'Santé', 'icon': Icons.favorite},
      {'name': 'Éducation', 'icon': Icons.school},
      {'name': 'Voyage', 'icon': Icons.flight},
      {'name': 'Mode', 'icon': Icons.checkroom},
      {'name': 'Gaming', 'icon': Icons.sports_esports},
      {'name': 'Photographie', 'icon': Icons.camera_alt},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Sélectionnez vos centres d\'intérêt',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose at least one interest to personalize your experience',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: interests.length,
            itemBuilder: (context, index) {
              final interest = interests[index];
              final isSelected = _selectedInterests.contains(interest['name']);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest['name']);
                    } else {
                      _selectedInterests.add(interest['name'] as String);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        interest['icon'] as IconData,
                        size: 32,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        interest['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
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
        ],
      ),
    );
  }

  /// Step 3: Goals
  Widget _buildGoalsStep() {
    final goals = [
      {
        'title': 'Se faire de nouveaux amis',
        'description': 'Rencontrer des personnes partageant les mêmes idées',
        'icon': Icons.people,
      },
      {
        'title': 'Pratiquer un passe-temps',
        'description': 'Explorer vos passions',
        'icon': Icons.sports_basketball,
      },
      {
        'title': 'Construire un réseau professionnel',
        'description': 'Développer vos connexions professionnelles',
        'icon': Icons.work,
      },
      {
        'title': 'Apprendre de nouvelles compétences',
        'description': 'Élargir vos connaissances',
        'icon': Icons.lightbulb,
      },
      {
        'title': 'S\'amuser',
        'description': 'Profiter d\'expériences mémorables',
        'icon': Icons.celebration,
      },
      {
        'title': 'Rester actif',
        'description': 'Bouger et rester en bonne santé',
        'icon': Icons.fitness_center,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'What are you looking for?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select your goals to help us recommend the best events',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 40),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final isSelected = _selectedGoals.contains(goal['title']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGoals.remove(goal['title']);
                        } else {
                          _selectedGoals.add(goal['title'] as String);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLightColor
                            : AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              goal['icon'] as IconData,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal['title'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : AppColors.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal['description'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Step 4: Follow Organizers
  Widget _buildOrganizersStep() {
    final organizers = [
      {
        'id': 1,
        'name': 'EventMaster Lomé',
        'followers': '12.5K',
        'image':
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&q=80'
      },
      {
        'id': 2,
        'name': 'Tech Africa',
        'followers': '8.2K',
        'image':
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=200&q=80'
      },
      {
        'id': 3,
        'name': 'Music Festival Togo',
        'followers': '15.7K',
        'image':
            'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=200&q=80'
      },
      {
        'id': 4,
        'name': 'Sports Club Lomé',
        'followers': '6.3K',
        'image':
            'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=200&q=80'
      },
      {
        'id': 5,
        'name': 'Art Gallery Togo',
        'followers': '4.1K',
        'image':
            'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=200&q=80'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Follow Event Organizers',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Stay updated with your favorite organizers (optional)',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 40),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: organizers.length,
            itemBuilder: (context, index) {
              final organizer = organizers[index];
              final organizerId = organizer['id'] as int;
              final isFollowing = _followedOrganizers.contains(organizerId);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        organizer['image'] as String,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: AppColors.primaryLightColor,
                            child: const Icon(
                              Icons.business,
                              color: AppColors.primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organizer['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${organizer['followers']} followers',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (isFollowing) {
                              _followedOrganizers.remove(organizerId);
                            } else {
                              _followedOrganizers.add(organizerId);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? Colors.white
                              : AppColors.primaryColor,
                          foregroundColor: isFollowing
                              ? AppColors.primaryColor
                              : Colors.white,
                          side: BorderSide(
                            color: AppColors.primaryColor,
                            width: isFollowing ? 1.5 : 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isFollowing ? 'Abonné' : 'S\'abonner',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build footer with continue button
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _canContinue() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.greyTextColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentStep == 3 ? 'TERMINER LA CONFIGURATION' : 'CONTINUER',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
