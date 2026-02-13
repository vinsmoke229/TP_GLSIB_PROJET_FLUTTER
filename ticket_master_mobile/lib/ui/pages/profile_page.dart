import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:event_app/bloc/booking_cubit.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/ui/pages/recharge_wallet_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// PROFILE PAGE - Professional High-Density Design
/// ============================================================================
/// Features:
/// - Hero header with cover image and avatar
/// - Real-time stats (Likes, Tickets, Following)
/// - Wallet integration
/// - Organized settings sections (Personal, Preferences, Information)
/// - Action menu with logout
/// - Emerald Green theme
/// ============================================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load data for stats
    context.read<EventCubit>().fetchEvents();
    context.read<BookingCubit>().loadUserBookings();
  }

  // CRITICAL: Get balance from current auth state (reactive)
  double get _balance {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      return state.user.solde;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Use BlocBuilder to rebuild when auth state changes
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroHeader(
                    user?.prenom ?? 'Utilisateur', user?.email ?? ''),
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildWalletSection(),
                const SizedBox(height: 24),
                _buildPersonalSection(),
                const SizedBox(height: 24),
                _buildPreferencesSection(),
                const SizedBox(height: 24),
                _buildInformationSection(),
                const SizedBox(height: 32),
                _buildAppVersion(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hero Header with Cover Image and Avatar
  Widget _buildHeroHeader(String name, String email) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80',
              ),
              fit: BoxFit.cover,
            ),
            color: AppColors.primaryColor.withValues(alpha: 0.3),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),

        // Transparent AppBar with menu
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _showActionMenu,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Avatar overlapping
        Positioned(
          top: 150,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: AppColors.primaryLightColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Stats Row (Likes, My Tickets, Following)
  Widget _buildStatsRow() {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, eventState) {
        return BlocBuilder<BookingCubit, BookingState>(
          builder: (context, bookingState) {
            final likesCount = eventState is EventLoaded
                ? eventState.events.where((e) => e.isFavorite).length
                : 0;

            final ticketsCount = bookingState is UserBookingsLoaded
                ? bookingState.bookings.length
                : 0;

            return Container(
              margin: const EdgeInsets.fromLTRB(24, 120, 24, 0),
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(likesCount.toString(), 'J\'aime'),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.greyTextColor.withValues(alpha: 0.2),
                  ),
                  _buildStatItem(ticketsCount.toString(), 'Mes Billets'),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.greyTextColor.withValues(alpha: 0.2),
                  ),
                  _buildStatItem('12', 'Abonnements'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// Wallet Section
  Widget _buildWalletSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryColor, Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mon Portefeuille',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'TMoney',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${NumberFormat('#,###', 'fr_FR').format(_balance)} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _showRechargeDialog,
                icon: const Icon(Icons.add_circle, size: 20),
                label: const Text('Recharger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryColor,
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

  /// PERSONAL Section
  Widget _buildPersonalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'PERSONNEL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Localisation',
                  subtitle: 'Changer de ville',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Paramètres de localisation bientôt disponibles !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Mes Billets',
                  subtitle: 'Tous les billets de vos achats',
                  onTap: () {
                    Navigator.pushNamed(context, '/tickets');
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Support',
                  subtitle: 'Obtenez de l\'aide rapidement',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support bientôt disponible !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PREFERENCES Section
  Widget _buildPreferencesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Compte',
                  subtitle: 'Modifier le profil / Se déconnecter',
                  onTap: _showAccountOptions,
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Notifications push et par e-mail',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Paramètres de notification bientôt disponibles !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.credit_card_outlined,
                  title: 'Méthodes de paiement',
                  subtitle: 'Ajouter ou modifier des méthodes de paiement',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Méthodes de paiement bientôt disponibles !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres supplémentaires',
                  subtitle: 'Langue / Thème',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Paramètres supplémentaires bientôt disponibles !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// INFORMATION Section
  Widget _buildInformationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  subtitle: 'En savoir plus sur EventMaster',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.help_center_outlined,
                  title: 'Centre d\'aide',
                  subtitle: 'FAQs et articles de support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Centre d\'aide bientôt disponible !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.star_outline,
                  title: 'Évaluer notre application',
                  subtitle: 'Partager vos commentaires',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Merci pour votre soutien !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.security_outlined,
                  title: 'Sécurité',
                  subtitle: 'Paramètres de confidentialité et de sécurité',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Paramètres de sécurité bientôt disponibles !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 68),
                _buildSettingsTile(
                  icon: Icons.share_outlined,
                  title: 'Inviter des amis',
                  subtitle: 'Partager EventMaster avec des amis',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Fonction d\'invitation bientôt disponible !'),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Settings Tile Widget
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLightColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// App Version
  Widget _buildAppVersion() {
    return const Center(
      child: Text(
        'App version 1.01.0',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondaryColor,
        ),
      ),
    );
  }

  /// Action Menu (3-dots)
  void _showActionMenu() {
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
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.share,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              title: const Text('Partager mon profil'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partage du profil bientôt disponible !'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              title: const Text('Edit profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Modification du profil bientôt disponible !'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Account Options
  void _showAccountOptions() {
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
              leading: const Icon(Icons.edit, color: AppColors.primaryColor),
              title: const Text('Modifier le Profil'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Modification du profil bientôt disponible !'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Recharge Dialog (Navigate to recharge page)
  void _showRechargeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RechargeWalletPage(),
      ),
    );
  }

  /// About Dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About EventMaster'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EventMaster',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.01.0'),
            SizedBox(height: 16),
            Text(
              'Découvrez et réservez des événements incroyables dans votre ville.'
              ' Des concerts aux conférences, trouvez votre prochaine expérience inoubliable avec EventMaster.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '© 2026 EventMaster. Tous droits réservés.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Handle Logout
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Logout using AuthCubit
      context.read<AuthCubit>().logout();

      // Clear entire navigation stack and go to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}
