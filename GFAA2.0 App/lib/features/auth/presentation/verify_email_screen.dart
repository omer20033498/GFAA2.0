import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gfaa_logo.dart';
import 'login_screen.dart';

/// Shown right after registration. Supabase has sent a confirmation email;
/// the user verifies via the link in that email, then comes back and logs
/// in. There's no in-app deep-link handling yet, so this is a manual
/// "go check your email, then log in" step rather than an automatic
/// hand-off back into the app.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GfaaLogo(),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.softSage,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Check your email', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                const Text(
                  "We've sent you a verification link. Once you've confirmed your "
                  'email, come back and log in.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  ),
                  child: const Text('Go to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
