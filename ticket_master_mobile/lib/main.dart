import 'package:event_app/app/configs/theme.dart';
import 'package:event_app/app/resources/constant/named_routes.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:event_app/bloc/event_cubit.dart';
import 'package:event_app/bloc/booking_cubit.dart';
import 'package:event_app/services/api_service.dart';
import 'package:event_app/ui/pages/detail_page.dart';
import 'package:event_app/ui/pages/main_screen.dart';
import 'package:event_app/ui/pages/login_page.dart';
import 'package:event_app/ui/pages/register_page.dart';
import 'package:event_app/ui/pages/profile_page.dart';
import 'package:event_app/ui/pages/admin_seed_page.dart';
import 'package:event_app/ui/pages/tickets_list_page.dart';
import 'package:event_app/ui/pages/ticket_page.dart';
import 'package:event_app/ui/pages/transaction_history_page.dart';
import 'package:event_app/ui/pages/discovery_page.dart';
import 'package:event_app/ui/pages/explore_page.dart';
import 'package:event_app/ui/pages/favorites_page.dart';
import 'package:event_app/ui/pages/onboarding_page.dart';
import 'package:event_app/ui/pages/setup_flow_page.dart';
import 'package:event_app/ui/pages/initial_splash_page.dart';
import 'package:event_app/ui/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

/// ============================================================================
/// EVENTMASTER - MAIN ENTRY POINT
/// ============================================================================
/// Global Cubit Injection with MultiBlocProvider
/// Smart startup logic with professional splash screen
/// Complete routing table for all screens
/// French locale initialization for DateFormat
/// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Initialize French locale for DateFormat
  // This prevents LocaleDataException when using French month names
  await initializeDateFormatting('fr_FR', null);

runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Single instance of ApiService shared across all Cubits
    final apiService = ApiService();

    return MultiBlocProvider(
      providers: [
        // AuthCubit - Global authentication state
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(apiService),
        ),
        
        // EventCubit - Global events state (lazy load, fetched when needed)
        BlocProvider<EventCubit>(
          create: (context) => EventCubit(apiService),
        ),
        
        // BookingCubit - Global booking state
        BlocProvider<BookingCubit>(
          create: (context) => BookingCubit(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'EventMaster',
        debugShowCheckedModeBanner: false,
        theme: Themes.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const InitialSplashPage(),
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/setup': (context) => const SetupFlowPage(),
          '/home': (context) => const MainScreen(),
          '/profile': (context) => const ProfilePage(),
          '/admin': (context) => const AdminSeedPage(),
          '/tickets': (context) => const TicketsListPage(),
          '/history': (context) => const TransactionHistoryPage(),
          '/explore': (context) => const ExplorePage(),
          '/discovery': (context) => const DiscoveryPage(),
          '/favorites': (context) => const FavoritesPage(),
        },
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case NamedRoutes.detailScreen:
            case '/detail':
              return MaterialPageRoute(
                builder: (_) => const DetailPage(),
                settings: settings,
              );
            case NamedRoutes.ticketScreen:
              return MaterialPageRoute(
                builder: (context) => const TicketPage(),
                settings: settings,
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
