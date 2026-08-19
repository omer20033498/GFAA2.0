import 'package:flutter/material.dart';

import 'static_content_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticContentScreen(
      title: 'Privacy Policy',
      draftNotice: 'Draft placeholder — GFAA can revise this whenever needed.',
      paragraphs: [
        "GFAA takes your privacy seriously, especially given the personal "
            "nature of what people share here. This policy explains what we "
            "collect and how it's used.",
        'What we collect — your name, email address, and basic profile '
            'details when you register; the journal entries, mood check-ins, '
            'and community posts you choose to create; and, if you apply to '
            'be listed as a practitioner, the professional details you '
            'submit.',
        "Your journal entries and mood check-ins are private by default — "
            "no one else, including GFAA staff, can read them. Community "
            "posts are visible to other users once approved, the same way "
            "any post to a public forum would be.",
        "How it's used — to run the app itself (showing your entries back "
            'to you, connecting you with the community, sending you the '
            'daily message), and nothing beyond that. We do not sell your '
            'data to third parties.',
        'Your data is stored securely with our hosting provider, Supabase. '
            'You can update your name, email, or password at any time from '
            'Profile & Account, and you can request deletion of your '
            'account and all associated data from the same screen.',
        'Questions about this policy can be sent to GFAA directly — see '
            'About GFAA for contact details.',
      ],
    );
  }
}
