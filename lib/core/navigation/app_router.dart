import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_tap/features/auth/login_screen.dart';
import 'package:ui_tap/features/auth/register_screen.dart';
import 'package:ui_tap/features/profile/profile_screen.dart';
import 'package:ui_tap/features/splash/splash_screen.dart';
import '../../data/services/token_storage.dart';
import '../../features/bookings/bookings_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
// TODO: Import your actual screens
// import '../features/home/home_screen.dart';

/// App router with authentication flow
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _authGuard,
    routes: [
      // Splash screen (initial route)
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication routes (no auth required)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Protected routes (require authentication)
      GoRoute(
        path: '/home',
        builder: (context, state) => BookingSearchScreen(), // Replace with actual HomeScreen
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  /// Auth guard - redirects based on authentication status
  static Future<String?> _authGuard(BuildContext context, GoRouterState state) async {
    final location = state.uri.toString();

    // Splash screen - let it handle navigation
    if (location == '/') {
      return null;
    }

    // Auth routes - accessible without login
    final authRoutes = ['/login', '/register'];
    final isAuthRoute = authRoutes.contains(location);

    // Check if user is authenticated
    final isLoggedIn = await TokenStorage.isLoggedIn();

    print('🔐 Auth Guard: location=$location, isLoggedIn=$isLoggedIn');

    // If trying to access protected route without auth → redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      print('❌ Not authenticated, redirecting to /login');
      return '/login';
    }

    // If authenticated and trying to access auth routes → redirect to home
    if (isLoggedIn && isAuthRoute) {
      print('✅ Already authenticated, redirecting to /home');
      return '/home';
    }

    // Allow navigation
    return null;
  }
}

/// Placeholder for home screen
class _HomeScreenPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to UI Tap!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('You are authenticated'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Go to Profile'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await TokenStorage.clearAll();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}