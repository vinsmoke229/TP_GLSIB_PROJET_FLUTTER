import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/ui/widgets/app_logo.dart';
import 'package:event_app/services/dio_client.dart';
import 'package:event_app/services/api_service.dart';
import 'package:flutter/material.dart';

class InitialSplashPage extends StatefulWidget {
  const InitialSplashPage({super.key});

  @override
  State<InitialSplashPage> createState() => _InitialSplashPageState();
}

class _InitialSplashPageState extends State<InitialSplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final dioClient = DioClient();
      final token = await dioClient.getToken();
      
      if (token == null || token.isEmpty) {
        _navigateToOnboarding();
        return;
      }

      final apiService = ApiService();
      final user = await apiService.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout');
        },
      );
      
      if (user.id > 0) {
        _navigateToHome();
      } else {
        _navigateToOnboarding();
      }
    } catch (e) {
      _navigateToOnboarding();
    }
  }
  
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }
  
  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // EventMaster Logo
            AppLogo(size: 80),
            SizedBox(height: 24),
            
            // "Tickets" text
            Text(
              'Tickets',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),
            
            // Tagline
            Text(
              'Vos événements à portée de main',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryColor,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 40),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
