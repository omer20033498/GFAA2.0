import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gfaa/features/auth/presentation/login_screen.dart';
import 'package:gfaa/features/checkins/data/mood.dart';
import 'package:gfaa/features/journal/presentation/journal_entry_screen.dart';
import 'package:gfaa/features/messages/data/daily_message.dart';
import 'package:gfaa/features/messages/data/message_with_state.dart';
import 'package:gfaa/features/messages/presentation/message_filter.dart';
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

  group('applyMessageFilter', () {
    DailyMessage message(String id) =>
        DailyMessage(id: id, body: 'body $id', createdAt: DateTime(2026, 1, 1));

    final messages = [
      MessageWithState(message: message('1'), saved: true, favourited: false),
      MessageWithState(message: message('2'), saved: false, favourited: true),
      MessageWithState(message: message('3'), saved: true, favourited: true),
      MessageWithState(message: message('4'), saved: false, favourited: false),
    ];

    test('all returns every message unchanged', () {
      expect(applyMessageFilter(messages, MessageFilter.all), messages);
    });

    test('saved returns only saved messages', () {
      final result = applyMessageFilter(messages, MessageFilter.saved);
      expect(result.map((item) => item.message.id), ['1', '3']);
    });

    test('favourites returns only favourited messages', () {
      final result = applyMessageFilter(messages, MessageFilter.favourites);
      expect(result.map((item) => item.message.id), ['2', '3']);
    });
  });
}
