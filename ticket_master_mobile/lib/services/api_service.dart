import 'package:dio/dio.dart';
import 'package:event_app/services/dio_client.dart';
import 'package:event_app/data/user_model.dart';
import 'package:event_app/data/event_model.dart';
import 'package:event_app/data/ticket_model.dart';
import 'package:event_app/data/achat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final DioClient _dioClient = DioClient();

  Dio get _dio => _dioClient.dio;

  // CRITICAL: Store current user globally for access across all methods
  UserModel? _currentUser;

  /// Get the currently authenticated user (cached)
  UserModel? get currentUser => _currentUser;

  /// Set the current user (called after login/register)
  void _setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  /// Clear the current user (called on logout)
  void _clearCurrentUser() {
    _currentUser = null;
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final cleanIdentifier = identifier.trim().toLowerCase();
      final cleanPassword = password.trim();
      // CRITICAL: Sanitize endpoint URL
      final endpoint = '/auth/login/utilisateur/'.trim();
      final response = await _dio.post(
        endpoint,
        data: {
          'identifiant':
              cleanIdentifier, // SANITIZED: lowercase, trimmed - peut être email ou username
          'mot_de_passe': cleanPassword, // SANITIZED: trimmed
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // CRITICAL: NO Authorization header on login
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      // Handle non-200 responses
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMsg = response.data?['error']?.toString() ??
            response.data?['message']?.toString() ??
            'Login failed';
        throw Exception(errorMsg);
      }

      // Extract token
      final token = response.data['token']?.toString().trim();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token received');
      }

      // DEBUG: Log raw response

      // Flexible user data extraction - Django might use 'user' or 'utilisateur'
      final userData = (response.data['user'] ?? response.data['utilisateur'])
          as Map<String, dynamic>?;

      if (userData == null) {
        throw Exception('Invalid response format: missing user data');
      }

// Parse user FIRST before using it
      final user = UserModel.fromJson(userData);

      // CRITICAL: Validate user ID
      if (user.id == 0) {
        throw Exception(
            'Invalid user ID received from server. Please contact support.');
      }

      // CRITICAL: Store auth data atomically (prevents database lock)
      await _dioClient.saveAuthData(token, user.id);

      // CRITICAL: Cache user globally for other methods
      _setCurrentUser(user);

      return {
        'token': token,
        'user': user,
      };
    } on DioException catch (e) {
      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server response timeout. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Cannot connect to server. Please check if Django is running.');
      }

      throw _handleError(e, 'Login failed');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String username,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      // UNIVERSAL INPUT SANITIZATION
      // Clean all inputs to avoid invisible spaces/casing issues
      final cleanNom = nom.trim();
      final cleanPrenom = prenom.trim();
      final cleanUsername = username.trim().toLowerCase();
      final cleanEmail = email.trim().toLowerCase();
      final cleanTelephone = telephone.trim();
      final cleanPassword = password.trim();

      final response = await _dio.post(
        '/utilisateurs/',
        data: {
          'nom': cleanNom, // SANITIZED: trimmed
          'prenom': cleanPrenom, // SANITIZED: trimmed
          'nom_utilisateur': cleanUsername, // SANITIZED: lowercase, trimmed
          'email': cleanEmail, // SANITIZED: lowercase, trimmed
          'tel': cleanTelephone, // SANITIZED: trimmed
          'mot_de_passe': cleanPassword, // SANITIZED: trimmed
          'mot_de_passe_confirmation': cleanPassword, // Django requirement
        },
      );
      
      final token = response.data['token']?.toString();
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token received from server');
      }

      // Flexible user data extraction - Django might use 'user' or 'utilisateur'
      final userData = (response.data['user'] ?? response.data['utilisateur'])
          as Map<String, dynamic>?;

      if (userData == null) {
        throw Exception('Invalid response format: missing user data');
      }

      // Parse user FIRST before using it
      final user = UserModel.fromJson(userData);

      // CRITICAL: Validate user ID
      if (user.id == 0) {
        throw Exception(
            'Invalid user ID received from server. Please contact support.');
      }

      // CRITICAL: Store auth data atomically (prevents database lock)
      await _dioClient.saveAuthData(token, user.id);

      // CRITICAL: Cache user globally for other methods
      _setCurrentUser(user);

      return {
        'token': token,
        'user': user,
      };
    } on DioException catch (e) {
      throw _handleError(e, 'Registration failed');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Logout user and clear token
  Future<void> logout() async {
    await _dioClient.deleteToken();
    await _dioClient.deleteUserId(); // CRITICAL: Clear user ID too
    _clearCurrentUser();
  }

  /// Get current authenticated user
  /// GET /api/utilisateurs/{id}/ (NOT /auth/me/ which returns 404)
  Future<UserModel> getCurrentUser() async {
    try {
      // CRITICAL: Get stored user ID
      final userId = await _dioClient.getUserId();

      if (userId == null || userId == 0) {
        throw Exception('No user ID found. Please login again.');
      }

      final response = await _dio.get('/utilisateurs/$userId/');
      final user = UserModel.fromJson(response.data);

      // Cache the user globally
      _setCurrentUser(user);

      return user;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get user info');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _dioClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<List<EventModel>> fetchEvents() async {
    try {
      final response = await _dio.get('/evenements/');

      // Handle Django Pagination
      final dynamic data = response.data;
      List<dynamic> eventsJson;

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response
        eventsJson = data['results'] as List<dynamic>;
      } else if (data is List) {
        // Direct list response
        eventsJson = data;
      } else {
        // Unexpected format

        eventsJson = [];
      }

      final events =
          eventsJson.map((json) => EventModel.fromJson(json)).toList();

      return events;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load events');
    }
  }

  /// Search events by query
  /// GET /api/evenements/rechercher/?q={query}
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final response = await _dio.get(
        '/evenements/rechercher/',
        queryParameters: {'q': query},
      );

      // Handle Django Pagination
      final dynamic data = response.data;
      List<dynamic> eventsJson;

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response
        eventsJson = data['results'] as List<dynamic>;
      } else if (data is List) {
        // Direct list response
        eventsJson = data;
      } else {
        eventsJson = [];
      }

      final events =
          eventsJson.map((json) => EventModel.fromJson(json)).toList();

      return events;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to search events');
    }
  }

  /// Fetch events by category
  /// GET /api/evenements/?type_evenement={category}
  Future<List<EventModel>> fetchEventsByCategory(String category) async {
    try {
      final response = await _dio.get(
        '/evenements/',
        queryParameters: {'type_evenement': category},
      );

      // Handle Django Pagination
      final dynamic data = response.data;
      List<dynamic> eventsJson;

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response
        eventsJson = data['results'] as List<dynamic>;
      } else if (data is List) {
        // Direct list response
        eventsJson = data;
      } else {
        // Unexpected format
        eventsJson = [];
      }

      final events =
          eventsJson.map((json) => EventModel.fromJson(json)).toList();

      return events;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load events by category');
    }
  }

  /// Get single event by ID
  /// GET /api/evenements/{id}/
  Future<EventModel> getEventById(int eventId) async {
    try {
      final response = await _dio.get('/evenements/$eventId/');
      final event = EventModel.fromJson(response.data);

      return event;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load event');
    }
  }

  /// Fetch tickets for an event
  /// GET /api/evenements/{id}/tickets/
  Future<List<TicketModel>> fetchTickets(int eventId) async {
    try {
      final response = await _dio.get(
        '/evenements/$eventId/tickets/',
      );

      // Handle Django Pagination
      final dynamic data = response.data;
      List<dynamic> ticketsJson;

      if (data is Map<String, dynamic>) {
        // Check for 'tickets' field first (custom backend format)
        if (data.containsKey('tickets')) {
          ticketsJson = data['tickets'] as List<dynamic>;
        }
        // Check for 'results' field (Django pagination)
        else if (data.containsKey('results')) {
          ticketsJson = data['results'] as List<dynamic>;
        } else {
          ticketsJson = [];
        }
      } else if (data is List) {
        ticketsJson = data;
      } else {
        ticketsJson = [];
      }

      final tickets =
          ticketsJson.map((json) => TicketModel.fromJson(json)).toList();

      return tickets;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load tickets');
    }
  }

  // ========================================
  // WALLET METHODS
  // ========================================

  /// Get wallet balance (from current user)
  Future<double> getWalletBalance() async {
    try {
      final user = await getCurrentUser();
      return user.solde;
    } catch (e) {
      return 0.0;
    }
  }

  /// Recharge wallet
  /// POST /api/utilisateurs/{id}/recharger/
  Future<UserModel> rechargeWallet(
    double amount, {
    String? moyenPaiement,
    String? description,
  }) async {
    try {
      // CRITICAL: Get current user ID with fallback recovery
      int? userId = _currentUser?.id;

      // SAFETY CHECK: If cached user is invalid, try to recover from storage
      if (userId == null || userId == 0) {
// Try to get user ID from secure storage
        userId = await _dioClient.getUserId();

        if (userId == null || userId == 0) {
          throw Exception('Session expiré.Veuillez vous reconnecter.');
        }

// Try to refresh current user from backend
        try {
          final recoveredUser = await getCurrentUser();
          _setCurrentUser(recoveredUser);
          userId = recoveredUser.id;
        } catch (e) {}
      }

      // CRITICAL: Ensure we have a valid current user before proceeding
      if (_currentUser == null) {
        throw Exception('Session expiré.Veuillez vous reconnecter.');
      }

      final response = await _dio.post(
        '/utilisateurs/$userId/recharger/',
        data: {
          'montant': amount,
          'moyen_paiement': moyenPaiement ?? 'mobile_money',
          'description': description ?? 'Rechargement de compte',
        },
      );
      final responseData = response.data as Map<String, dynamic>;
      final dynamic balanceValue = responseData['nouveau_solde'] ??
          responseData['solde'] ??
          responseData['balance'] ??
          responseData['new_balance'];

      if (balanceValue == null) {
        // Fallback: Try to parse as full user object
        final user = UserModel.fromJson(responseData);

        // If parsed user has valid ID, use it
        if (user.id > 0) {
          _setCurrentUser(user);

          return user;
        }

        // Otherwise, keep existing user and just update balance
      }

      // Parse the new balance safely
      final double newBalance =
          double.tryParse(balanceValue?.toString() ?? '0') ?? 0.0;

// CRITICAL: Validate the new balance
      if (newBalance == 0.0 && amount > 0) {}

      // CRITICAL: Create updated user using copyWith to preserve ALL existing fields
      final updatedUser = _currentUser!.copyWith(solde: newBalance);

      // CRITICAL: Verify identity is preserved
      if (updatedUser.id != _currentUser!.id) {
        throw Exception('User identité corrompue lors du rechargement');
      }

      // Cache the updated user
      _setCurrentUser(updatedUser);

      return updatedUser;
    } on DioException catch (e) {
      throw _handleError(e, 'Fai to recharge wallet');
    } catch (e) {
      throw Exception('Échec du rechargement du portefeuille: $e');
    }
  }

  // ========================================
  // PURCHASE METHODS
  // ========================================

  /// Purchase ticket
  /// POST /api/achats/
  /// PRODUCTION SECURITY: id_utilisateur extracted from JWT token by Django
  /// Django returns wrapped response: {"message": "...", "achat": {...}}
  /// NEW: Supports optional session ID for dynamic calendar system
  Future<AchatModel> purchaseTicket({
    required int idTicket,
    required int quantite,
    int? idSession, // NEW: Optional session ID
  }) async {
    try {
      if (idSession != null) {}

      // PRODUCTION SECURITY: Build request WITHOUT id_utilisateur
      // Django extracts user ID from JWT token in Authorization header
      final requestData = {
        'id_ticket': idTicket,
        'quantite': quantite,
      };

      // Add session ID if provided
      if (idSession != null) {
        requestData['id_session'] = idSession;
      }

      final response = await _dio.post(
        '/achats/',
        data: requestData,
      );

      // CRITICAL: Django wraps response in {"message": "...", "achat": {...}}
      // Unwrap the 'achat' object before parsing
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        // Check if response is wrapped
        if (responseData.containsKey('achat')) {
          final achatData = responseData['achat'] as Map<String, dynamic>;
          final achat = AchatModel.fromJson(achatData);

          return achat;
        }

        // Fallback: Direct parsing (if Django changes format)

        final achat = AchatModel.fromJson(responseData);

        return achat;
      }

      throw Exception('Invalid response format from server');
    } on DioException catch (e) {
// Handle specific error: Insufficient balance
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          final errorMsg = errorData['error'] as String;
          if (errorMsg.toLowerCase().contains('solde') ||
              errorMsg.toLowerCase().contains('insufficient')) {
            throw Exception('Solde insuffisant. Rechargez votre portefeuille.');
          }
        }
      }

      throw _handleError(e, 'Failed to purchase ticket');
    } catch (e) {
      throw Exception('Échec de l\'achat du billet: $e');
    }
  }

  /// Fetch user's purchases (achats)
  /// GET /api/achats/
  Future<List<AchatModel>> fetchUserAchats() async {
    try {
      final response = await _dio.get('/achats/');

      // Handle Django Pagination
      final dynamic data = response.data;
      List<dynamic> achatsJson;

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response
        achatsJson = data['results'] as List<dynamic>;
      } else if (data is List) {
        // Direct list response
        achatsJson = data;
      } else {
        // Unexpected format

        achatsJson = [];
      }

      final achats =
          achatsJson.map((json) => AchatModel.fromJson(json)).toList();

      return achats;
    } on DioException catch (e) {
      throw _handleError(e, 'Échec du chargement des billets');
    }
  }

  /// Get achat by ID with QR code
  /// GET /api/achats/{id}/
  Future<AchatModel> getAchatById(int id) async {
    try {
      final response = await _dio.get('/achats/$id/');

      return AchatModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load ticket details');
    }
  }

  /// Get achat details by QR code without validating
  /// GET /api/achats/details/{code_qr}/
  Future<Map<String, dynamic>> getAchatByQrCode(String codeQr) async {
    try {
      final response = await _dio.get('/achats/details/$codeQr/');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Échec du chargement du billet par code QR');
    }
  }

  /// Validate ticket by QR code (mark as used) /// POST /api/achats/validate/{code_qr}/
  Future<Map<String, dynamic>> validateTicket(String codeQr) async {
    try {
      final response = await _dio.post('/achats/validate/$codeQr/');

      final data = response.data as Map<String, dynamic>;

      // Check if validation was successful
      if (data['success'] == false) {
        throw Exception(data['error'] ?? 'Validation failed');
      }

      return data;
    } on DioException catch (e) {
      // Handle specific error cases
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e, 'Échec de la validation du billet');
    }
  }

  // ========================================
  // AI METHODS (Mock for now)
  // ========================================

  /// Get AI recommendations
  /// TODO: Implement real AI endpoint when available
  Future<List<EventModel>> getAIRecommendations() async {
    // For now, return all events
    // Later: GET /api/ai/recommendations/
    return await fetchEvents();
  }

  /// Ask AI a question
  /// TODO: Implement real AI endpoint when available
  Future<String> askAI(String question) async {
    // For now, return mock response
    // Later: POST /api/ai/ask/
    return 'Voici une réponse simulée de l\'IA pour votre question: "$question"';
  }

  // ========================================
  // FAVORITES METHODS
  // ========================================

  /// Toggle favorite status
  /// POST /api/favorites/toggle/
  Future<void> toggleFavorite(int eventId) async {
    try {
      await _dio.post(
        '/favorites/toggle/',
        data: {'id_evenement': eventId},
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Échec de la mise à jour des favoris');
    }
  }

  /// Fetch user's favorite events
  /// GET /api/favorites/
  Future<List<EventModel>> fetchFavorites() async {
    try {
      final response = await _dio.get('/favorites/');

      // Handle Django Pagination
      final dynamic data = response.data;
      List<dynamic> eventsJson;

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response
        eventsJson = data['results'] as List<dynamic>;
      } else if (data is List) {
        // Direct list response
        eventsJson = data;
      } else {
        // Unexpected format

        eventsJson = [];
      }

      final events =
          eventsJson.map((json) => EventModel.fromJson(json)).toList();

      return events;
    } on DioException catch (e) {
      throw _handleError(e, 'Échec du chargement des favoris');
    }
  }

  /// Check if event is favorite (local check)
  bool isFavorite(int eventId) {
    return false; // Placeholder
  }

  /// Fetch AI recommendation for current user
  /// GET /api/ai/recommend/
  Future<Map<String, dynamic>> fetchAiRecommendation() async {
    try {
      final response = await _dio.get('/ai/recommend/');

      final data = response.data;

      if (data is Map<String, dynamic>) {
// CRITICAL: Django sends "titre" not "event_title"
        final eventId =
            data['event_id'] as int? ?? data['id_evenement'] as int? ?? 0;
        final eventTitle = data['titre']?.toString() ??
            data['event_title']?.toString() ??
            data['titre_evenement']?.toString() ??
            'Événement recommandé';
        final reason = data['reason']?.toString() ??
            data['raison']?.toString() ??
            'Cet événement pourrait vous intéresser.';

        return {
          'event_id': eventId,
          'event_title': eventTitle,
          'reason': reason,
        };
      }

      throw Exception('Format de réponse invalide pour la recommandation IA');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 ||
          e.response?.statusCode == 500 ||
          e.response?.statusCode == null) {
        return await _getFallbackRecommendation();
      }

      throw _handleError(e, 'Échec du chargement de la recommandation IA');
    } catch (e) {
      return await _getFallbackRecommendation();
    }
  }

  Future<Map<String, dynamic>> _getFallbackRecommendation() async {
    try {
      final favorites = await fetchFavorites();

      if (favorites.isNotEmpty) {
        final event = favorites.first;

        return {
          'event_id': event.id,
          'event_title': event.titre,
          'reason': 'Événement populaire parmi vos favoris',
        };
      }
    } catch (e) {}
    try {
      final events = await fetchEvents();

      if (events.isNotEmpty) {
        final event = events.first;

        return {
          'event_id': event.id,
          'event_title': event.titre,
          'reason': 'Événement populaire du moment',
        };
      }
    } catch (e) {}

    // Ultimate fallback: Return empty recommendation

    throw Exception('Aucun événement disponible pour le moment.');
  }

  /// PATCH /api/utilisateurs/{id}/

  Future<UserModel> completeSetup({
    required int userId,
    required String city,
    required List<String> interests,
    required List<String> goals,
    required List<int> followedOrganizers,
  }) async {
    try {
      final response = await _dio.patch(
        '/utilisateurs/$userId/',
        data: {
          'adresse': city, // City devient l'adresse de l'utilisateur
        },
      );

      final user = UserModel.fromJson(response.data);

// Store additional data locally (interests, goals, etc.)
      await _storeSetupDataLocally(
        userId: userId,
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
      );

      // Return updated user with setup complete flag
      return user.copyWith(
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
        isSetupComplete: true,
      );
    } on DioException catch (e) {
// DON'T BLOCK USER - Store locally and continue
      await _storeSetupDataLocally(
        userId: userId,
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
      );
      return UserModel(
        id: userId,
        nom: '',
        prenom: '',
        email: '',
        solde: 0.0,
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
        isSetupComplete: true,
      );
    } catch (e) {
// Still don't block - store locally
      await _storeSetupDataLocally(
        userId: userId,
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
      );

      return UserModel(
        id: userId,
        nom: '',
        prenom: '',
        email: '',
        solde: 0.0,
        city: city,
        interests: interests,
        goals: goals,
        followedOrganizers: followedOrganizers,
        isSetupComplete: true,
      );
    }
  }

  /// Store setup data locally using SharedPreferences
  Future<void> _storeSetupDataLocally({
    required int userId,
    required String city,
    required List<String> interests,
    required List<String> goals,
    required List<int> followedOrganizers,
  }) async {
    try {
      // Use SharedPreferences for simple local storage
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('setup_city_$userId', city);
      await prefs.setStringList('setup_interests_$userId', interests);
      await prefs.setStringList('setup_goals_$userId', goals);
      await prefs.setString(
          'setup_organizers_$userId', followedOrganizers.join(','));
      await prefs.setBool('setup_complete_$userId', true);
    } catch (e) {
      // Even this fails, we continue - it's just preferences
    }
  }

  /// Check if setup is complete (from current user)
  bool isSetupComplete() {
    // This should be checked from the current user's isSetupComplete field
    return false; // Placeholder - will be checked via getCurrentUser()
  }

  Exception _handleError(DioException error, String defaultMessage) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      // Extract error message from response with flexible parsing
      String errorMessage = defaultMessage;

      if (data is Map) {
        // Try standard error fields first
        if (data.containsKey('error')) {
          final errorValue = data['error'];
          errorMessage = errorValue?.toString() ?? defaultMessage;
        } else if (data.containsKey('detail')) {
          final detailValue = data['detail'];
          errorMessage = detailValue?.toString() ?? defaultMessage;
        } else if (data.containsKey('message')) {
          final messageValue = data['message'];
          errorMessage = messageValue?.toString() ?? defaultMessage;
        } else {
          final errorParts = <String>[];

          for (final entry in data.entries) {
            final key = entry.key;
            final value = entry.value;

            if (value is List && value.isNotEmpty) {
              // Join list items: ["error1", "error2"] -> "error1, error2"
              final messages = value
                  .map((v) => v?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .join(', ');
              if (messages.isNotEmpty) {
                // Format: "email: Already exists"
                errorParts.add('$key: $messages');
              }
            } else if (value != null) {
              // Single value error
              final message = value.toString();
              if (message.isNotEmpty) {
                errorParts.add('$key: $message');
              }
            }
          }

          if (errorParts.isNotEmpty) {
            errorMessage = errorParts.join('\n');
          }
        }
      } else if (data is String) {
        errorMessage = data;
      }

      return Exception(errorMessage);
    }

    // Network error
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception(
          'Échec de la connexion. Veuillez vérifier votre connexion Internet.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception(
          'Impossible de se connecter au serveur. Veuillez vérifier si le backend est en cours d’exécution.');
    }
    return Exception(defaultMessage);
  }
}
