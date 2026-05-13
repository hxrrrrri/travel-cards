import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/travel_cards/presentation/screens/create_travel_card_screen.dart';
import '../features/travel_cards/presentation/screens/travel_card_summary_screen.dart';
import '../features/discovery/presentation/screens/discovery_setup_screen.dart';
import '../features/map/presentation/screens/discovery_map_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authControllerProvider.notifier);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authControllerProvider).isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/auth';
      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/travel-cards/create', builder: (_, __) => const CreateTravelCardScreen()),
      GoRoute(
        path: '/travel-cards/:id',
        builder: (_, state) => TravelCardSummaryScreen(cardId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/travel-cards/:id/setup',
        builder: (_, state) => DiscoverySetupScreen(cardId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/travel-cards/:id/map',
        builder: (_, state) => DiscoveryMapScreen(cardId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}', style: const TextStyle(color: Colors.white))),
    ),
  );
});
