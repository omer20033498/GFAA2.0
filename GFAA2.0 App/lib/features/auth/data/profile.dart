class Profile {
  const Profile({
    required this.id,
    required this.role,
    required this.email,
    required this.displayName,
    required this.fullName,
    required this.onboardingAnswers,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      role: map['role'] as String,
      email: map['email'] as String?,
      displayName: map['display_name'] as String?,
      fullName: map['full_name'] as String?,
      onboardingAnswers: Map<String, dynamic>.from(
        map['onboarding_answers'] as Map? ?? const {},
      ),
    );
  }

  final String id;
  final String role;
  final String? email;

  /// Preferred name — shown anywhere the app displays the user's name.
  final String? displayName;

  /// Full name — records only, never shown in the UI.
  final String? fullName;
  final Map<String, dynamic> onboardingAnswers;

  bool get hasCompletedOnboarding => onboardingAnswers.isNotEmpty;
}
