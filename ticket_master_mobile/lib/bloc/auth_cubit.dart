import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:event_app/services/api_service.dart';
import 'package:event_app/data/user_model.dart';

part 'auth_state.dart';

/// ============================================================================
/// AUTH CUBIT - Django REST API Integration
/// ============================================================================
/// Features:
/// - JWT Authentication
/// - Login/Register with Django backend
/// - Secure token storage
/// - User session management
/// ============================================================================

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService;

  AuthCubit(this._apiService) : super(AuthInitial());

  /// Check if user is authenticated on app start
  /// PRODUCTION: Fetches REAL user data from PostgreSQL via JWT
  /// Returns true if authenticated, false otherwise
  Future<bool> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final isAuthenticated = await _apiService.isAuthenticated();

      if (isAuthenticated) {
        try {
          // PRODUCTION: Fetch REAL user data from Django/PostgreSQL
          // This returns the actual balance (FCFA) and user ID from the database
          final user = await _apiService.getCurrentUser();

          emit(AuthAuthenticated(user: user));
          return true;
        } catch (e) {
          // SECURITY: If getCurrentUser fails with 401, token is invalid

          if (e.toString().contains('401') ||
              e.toString().contains('Unauthorized')) {
            await _apiService.logout();
            emit(AuthUnauthenticated());
            return false;
          }

          // Other errors: Still logout for safety

          await _apiService.logout();
          emit(AuthUnauthenticated());
          return false;
        }
      } else {
        emit(AuthUnauthenticated());
        return false;
      }
    } catch (e) {
      emit(AuthUnauthenticated());
      return false;
    }
  }

  /// Login with email and password
  /// UNIVERSAL: Works for ANY user in PostgreSQL database
  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    try {
      final result = await _apiService.login(email, password);
      final user = result['user'] as UserModel;

      emit(AuthAuthenticated(user: user));

      // NAVIGATION: Handled by LoginPage listener
      // - If setup complete → /home
      // - If setup not complete → /setup
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(message: errorMessage));

      // Return to unauthenticated state after showing error
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthUnauthenticated());
    }
  }

  /// Backward compatibility: signIn
  Future<void> signIn(String email, String password) async {
    return login(email, password);
  }

  /// Sign in as guest (test account)
  Future<void> signInAsGuest() async {
    return login('test@eventapp.com', 'Test123456!');
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String username,
    required String email,
    required String telephone,
    required String password,
    // Backward compatibility: accept name as single field
    String? name,
  }) async {
    emit(AuthLoading());

    try {
// If name is provided instead of nom/prenom, split it
      String finalNom = nom;
      String finalPrenom = prenom;

      if (name != null && name.isNotEmpty) {
        final parts = name.split(' ');
        finalPrenom = parts.first;
        finalNom = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;
      }

      final result = await _apiService.register(
        nom: finalNom,
        prenom: finalPrenom,
        username: username,
        email: email,
        telephone: telephone,
        password: password,
      );

      final user = result['user'] as UserModel;

      emit(AuthAuthenticated(user: user));

      // NAVIGATION: Handled by RegisterPage listener
      // - Always go to /setup for personalization
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(message: errorMessage));

      // Return to unauthenticated state after showing error
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthUnauthenticated());
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _apiService.logout();

      emit(AuthUnauthenticated());
    } catch (e) {
      // Force logout anyway
      emit(AuthUnauthenticated());
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      // Don't change state on refresh error
    }
  }

  /// Get current user (if authenticated)
  UserModel? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  // ========================================
  // SETUP/PERSONALIZATION METHODS (NEW)
  // ========================================

  /// Complete user setup/personalization (NON-BLOCKING)
  /// Strategy: Try backend update, but ALWAYS succeed locally
  Future<void> completeSetup({
    required String city,
    required List<String> interests,
    required List<String> goals,
    required List<int> followedOrganizers,
  }) async {
    try {
// Get current user ID
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Try to update backend (non-blocking)
      final updatedUser = await _apiService.completeSetup(
        userId: user.id,
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
      );

// Merge with current user data (in case backend returned minimal data)
      final finalUser = user.copyWith(
        city: updatedUser.city ?? city,
        interests: updatedUser.interests.isNotEmpty
            ? updatedUser.interests
            : interests,
        goals: updatedUser.goals.isNotEmpty ? updatedUser.goals : goals,
        followedOrganizers: updatedUser.followedOrganizers.isNotEmpty
            ? updatedUser.followedOrganizers
            : followedOrganizers,
        isSetupComplete: true,
      );

      emit(AuthAuthenticated(user: finalUser));
    } catch (e) {
// DON'T THROW - Mark setup as complete locally and continue
      final user = currentUser;
      if (user != null) {
        final updatedUser = user.copyWith(
          city: city,
          interests: interests,
          goals: goals,
          followedOrganizers: followedOrganizers,
          isSetupComplete: true,
        );

        emit(AuthAuthenticated(user: updatedUser));
      } else {
        // Even this fails, we don't throw - just log it
      }
    }
  }

  /// Check if setup is complete
  bool isSetupComplete() {
    return _apiService.isSetupComplete();
  }

  // ========================================
  // WALLET METHODS (NEW)
  // ========================================

  /// Recharge wallet with specified amount
  /// PRODUCTION: Immediately syncs balance from PostgreSQL after recharge
  Future<void> rechargeWallet(
    double amount, {
    String? moyenPaiement,
    String? description,
  }) async {
    try {
// FLEXIBLE AUTH CHECK: Use ApiService.currentUser if Cubit state is unreliable
      UserModel? user;

      final currentState = state;
      if (currentState is AuthAuthenticated) {
        user = currentState.user;
      } else {
        // Fallback: Try to get user from ApiService directly

        try {
          user = await _apiService.getCurrentUser();
        } catch (e) {
          throw Exception('Please login to recharge your wallet');
        }
      }

      if (user == null || user.id == 0) {
        throw Exception('Session expired. Please login again.');
      }

// Call API to recharge (returns updated user with new balance)
      final updatedUser = await _apiService.rechargeWallet(
        amount,
        moyenPaiement: moyenPaiement,
        description: description,
      );

      // CRITICAL: Verify identity is preserved
      if (updatedUser.id != user.id) {
        throw Exception('User identity corrupted during recharge');
      }

// CRITICAL: Emit new state with updated user (preserves all fields)
      emit(AuthAuthenticated(user: updatedUser));

      // PRODUCTION: Immediately fetch fresh balance from PostgreSQL

      try {
        final freshUser = await _apiService.getCurrentUser();

        emit(AuthAuthenticated(user: freshUser));
      } catch (e) {
        // Keep the updated user from recharge response
      }
    } catch (e) {
      throw Exception('Failed to recharge wallet: $e');
    }
  }

  /// Get current wallet balance
  double get walletBalance {
    final user = currentUser;
    return user?.solde ?? 0.0;
  }
}
