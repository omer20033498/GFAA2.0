import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gfaa/features/auth/presentation/login_screen.dart';
import 'package:gfaa/features/checkins/data/mood.dart';
import 'package:gfaa/features/journal/presentation/journal_entry_screen.dart';
import 'package:gfaa/features/training/presentation/training_screen.dart';

void main() {
  testWidgets('LoginScreen renders email/password fields and a login button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
  });

  testWidgets('TrainingScreen renders all three rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TrainingScreen()),
    );

    expect(find.text('For individuals'), findsOneWidget);
    expect(find.text('For workplaces'), findsOneWidget);
    expect(find.text('For instructors'), findsOneWidget);
    expect(find.text('Learn more'), findsNWidgets(3));
  });

  testWidgets('JournalEntryScreen renders a new-entry composer', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: JournalEntryScreen()),
      ),
    );

    expect(find.text('New entry'), findsOneWidget);
    expect(find.text("Write what's on your mind..."), findsOneWidget);
  });

  test('Mood.fromKey round-trips every mood key stored in the database', () {
    for (final mood in Mood.values) {
      expect(Mood.fromKey(mood.key), mood);
    }
  });

  test('Mood levels are 1-5 and strictly increasing struggling to great', () {
    final levels = Mood.values.map((mood) => mood.level).toList();
    expect(levels, [1, 2, 3, 4, 5]);
  });
}
