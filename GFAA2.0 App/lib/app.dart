import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/home/placeholder_home_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class GfaaApp extends StatelessWidget {
  const GfaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GFAA',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Routes to login, onboarding, or a role's home based on auth + profile
/// state. Per CLAUDE.md: only `user`-role accounts see onboarding; admin
/// and practitioner accounts go straight to their own dashboard.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => _ErrorScreen(message: '$error'),
      data: (state) {
        // Opening the password-reset email link reopens the app with a
        // recovery session and this event, regardless of whatever the user
        // was previously signed into. Route to the reset screen unconditionally
        // rather than falling through to the normal session/role routing below.
        if (state.event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }
        if (state.session == null) return const LoginScreen();

        final profileAsync = ref.watch(profileProvider);
        return profileAsync.when(
          loading: () => const _LoadingScreen(),
          error: (error, _) => _ErrorScreen(message: '$error'),
          data: (profile) {
            if (profile == null) return const _LoadingScreen();
            if (profile.role == 'user' && !profile.hasCompletedOnboarding) {
              return const OnboardingScreen();
            }
            return switch (profile.role) {
              'admin' => const PlaceholderHomeScreen(title: 'Admin Dashboard'),
              'practitioner' => const PlaceholderHomeScreen(title: 'Practitioner Portal'),
              _ => const HomeScreen(),
            };
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
