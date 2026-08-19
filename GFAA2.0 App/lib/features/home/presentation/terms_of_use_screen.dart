import 'package:flutter/material.dart';

import 'static_content_screen.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticContentScreen(
      title: 'Terms of Use',
      paragraphs: [
        'Before you proceed to use our services, please read the following '
            'terms and conditions carefully:',
        '1. Acceptance of Terms — By accessing or using GFAA, you agree to '
            'be bound by these Terms of Use. If you do not agree with any '
            'part of these terms, you may not use our services.',
        '2. Description of Service — GFAA provides users with a platform '
            'for grief support, including but not limited to access to '
            'grief counsellors, support groups, educational resources, and '
            'a community forum for sharing experiences and insights.',
        '3. Not a Replacement for Professional Advice — GFAA is intended to '
            'provide support, resources, and community for individuals '
            'experiencing grief. However, it is not a substitute for '
            'professional health or mental health advice, diagnosis, or '
            'treatment. The information provided on GFAA is for '
            'informational purposes only and should not be considered '
            'medical advice. If you are experiencing severe distress or '
            'mental health concerns, we strongly advise you to seek '
            'assistance from qualified professionals such as counsellors, '
            'therapists, or healthcare providers.',
        '4. User Eligibility — Users must be at least 18 years of age to '
            'use GFAA. By using our services, you warrant that you are of '
            'legal age to form a binding contract.',
        '5. User Account — To access certain features of GFAA, you may be '
            'required to create a user account. You agree to provide '
            'accurate, current, and complete information during the '
            'registration process and to update such information to keep '
            'it accurate, current, and complete.',
      ],
    );
  }
}
