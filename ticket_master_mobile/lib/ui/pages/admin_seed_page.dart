import 'package:event_app/app/configs/colors.dart';
import 'package:flutter/material.dart';

/// ============================================================================
/// ADMIN SEED PAGE - DEPRECATED
/// ============================================================================
/// This page is no longer used. The app now uses MockDataService.
/// All Firebase seeding functionality has been removed.
/// ============================================================================

class AdminSeedPage extends StatelessWidget {
  const AdminSeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Page Admin'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Cette page est obsolète.\n\nL\'application utilise désormais MockDataService pour toutes les opérations de données.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
