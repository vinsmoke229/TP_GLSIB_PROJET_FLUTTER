import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:event_app/ui/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// SPLASH SCREEN - Professional Entry Point
/// ============================================================================
/// Features:
/// - EventMaster branding
/// - Elegant loading animation
/// - Smart routing (First time → Onboarding, Returning → Login/Home)
/// - Pure white background with Emerald accents
/// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup progress animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    // Navigate after animation
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      
      if (!mounted) return;
      
      if (isFirstTime) {
        // First time user → Show onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Returning user → Check persistent login
        await _checkPersistentLogin();
      }
    } catch (e) {
      // Server offline or connectivity error
      if (!mounted) return;
      _showServerOfflineScreen();
    }
  }

  /// Check for persistent login (Remember Me)
  Future<void> _checkPersistentLogin() async {
    try {

// Check auth status (will verify token and fetch user)
      await context.read<AuthCubit>().checkAuthStatus();
      
      if (!mounted) return;
      
      // Check the resulting state
      final authState = context.read<AuthCubit>().state;
      
      if (authState is AuthAuthenticated) {
        // Token valid, user authenticated

// CRITICAL: Vérifier si c'est la première connexion (lastLogin == null)
        // Seulement à la première connexion, on demande les préférences
        if (authState.user.lastLogin == null) {
          // Première connexion → Setup Flow
          
          Navigator.pushReplacementNamed(context, '/setup');
        } else {
          // Déjà connecté auparavant → Home
          
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // No token or token expired → Go to login
        
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      
      if (!mounted) return;
      // On error, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showServerOfflineScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ServerOfflineScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // EventMaster Logo
              const AppLogo(
                size: 120,
                showSubtitle: true,
              ),
              
              const Spacer(),
              
              // Loading progress bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.greyTextColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryColor,
                                  Color(0xFF059669),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// SERVER OFFLINE SCREEN - Connectivity Error Handler
/// ============================================================================
/// Shows when backend is unreachable with retry option
/// ============================================================================

class ServerOfflineScreen extends StatelessWidget {
  const ServerOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Server offline icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 60,
                  color: AppColors.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Server Offline',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Unable to connect to the server. Please check your internet connection or try again later.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Retry button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Go back to splash and retry
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SplashScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Retry Connection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
              
              // Continue offline button (optional)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    // Go to login page anyway
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryColor,
                    side: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue Anyway',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
