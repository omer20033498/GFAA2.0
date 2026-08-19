import 'package:flutter/material.dart';

import 'static_content_screen.dart';

class AboutGfaaScreen extends StatelessWidget {
  const AboutGfaaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticContentScreen(
      title: 'About GFAA',
      draftNotice: 'Placeholder copy — GFAA can revise this whenever needed.',
      paragraphs: [
        'Grief First Aid Australia (GFAA) exists to make grief support easier '
            'to reach, whatever that support looks like for you — a private '
            "space to write down what you're feeling, a daily reminder that "
            "you're not alone, a community of people who understand, or a "
            'direct line to a qualified grief professional.',
        "Grief doesn't follow a schedule, and it doesn't look the same for "
            'two people. This app was built around that — no clinical '
            'language, no pressure to feel a certain way by a certain time, '
            'just practical, trauma-informed support you can return to '
            'whenever you need it.',
        'GFAA is not a replacement for professional care. Where you need '
            'more than the app can offer, Find a Specialist connects you '
            'with real practitioners who can help.',
      ],
    );
  }
}
