import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gfaa/features/admin/data/admin_stats.dart';
import 'package:gfaa/features/auth/data/profile.dart';
import 'package:gfaa/features/auth/presentation/login_screen.dart';
import 'package:gfaa/features/checkins/data/mood.dart';
import 'package:gfaa/features/community/data/community_post.dart';
import 'package:gfaa/features/community/presentation/community_compose_screen.dart';
import 'package:gfaa/features/journal/presentation/journal_entry_screen.dart';
import 'package:gfaa/features/messages/data/daily_message.dart';
import 'package:gfaa/features/messages/data/message_with_state.dart';
import 'package:gfaa/features/messages/presentation/message_filter.dart';
import 'package:gfaa/features/practitioners/data/delivery_option.dart';
import 'package:gfaa/features/practitioners/data/practitioner.dart';
import 'package:gfaa/features/practitioners/data/profession.dart';
import 'package:gfaa/features/practitioners/presentation/practitioner_application_screen.dart';
import 'package:gfaa/features/practitioners/presentation/specialist_filter.dart';
import 'package:gfaa/features/support/data/bug_report.dart';
import 'package:gfaa/features/training/presentation/training_screen.dart';

void main() {
  testWidgets('LoginScreen renders email/password fields and a login button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Log in to your account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email address'), findsOneWidget);
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

  testWidgets('CommunityComposeScreen renders a new-post composer', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CommunityComposeScreen()),
      ),
    );

    expect(find.text('New post'), findsOneWidget);
    expect(find.text('Share something with the group…'), findsOneWidget);
  });

  testWidgets('PractitionerApplicationScreen renders the application form', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PractitionerApplicationScreen()),
      ),
    );

    expect(find.text('Apply to be listed'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Full name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Qualifications'), findsOneWidget);
    expect(find.text('Submit application'), findsOneWidget);
  });

  group('Profile.effectiveDisplayName', () {
    Profile profile({String? displayName, String? email}) => Profile(
          id: 'u1',
          role: 'user',
          email: email,
          displayName: displayName,
          fullName: null,
          onboardingAnswers: const {},
        );

    test('uses displayName when set', () {
      expect(
        profile(displayName: 'Sam', email: 'sam@example.com').effectiveDisplayName,
        'Sam',
      );
    });

    test('falls back to the email prefix when displayName is null', () {
      expect(
        profile(displayName: null, email: 'sam@example.com').effectiveDisplayName,
        'sam',
      );
    });

    test('falls back to "A member" when both are null', () {
      expect(profile(displayName: null, email: null).effectiveDisplayName, 'A member');
    });
  });

  test('PostStatus.fromKey round-trips every status key stored in the database', () {
    for (final status in PostStatus.values) {
      expect(PostStatus.fromKey(status.name), status);
    }
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

  test('PractitionerStatus.fromKey round-trips every status key stored in the database', () {
    for (final status in PractitionerStatus.values) {
      expect(PractitionerStatus.fromKey(status.name), status);
    }
  });

  test('Profession.fromKey round-trips every profession key stored in the database', () {
    for (final profession in Profession.values) {
      expect(Profession.fromKey(profession.key), profession);
    }
  });

  test('DeliveryOption.fromKey round-trips every delivery option key stored in the database', () {
    for (final option in DeliveryOption.values) {
      expect(DeliveryOption.fromKey(option.key), option);
    }
  });

  group('SpecialistFilter', () {
    Practitioner practitioner({
      String id = 'p1',
      String fullName = 'Dr. Jane Doe',
      Profession profession = Profession.psychologist,
      String? expertise,
      String state = 'NSW',
      String location = 'Sydney',
      List<DeliveryOption> deliveryOptions = const [DeliveryOption.online],
    }) {
      return Practitioner(
        id: id,
        userId: 'u-$id',
        fullName: fullName,
        email: 'jane@example.com',
        phone: '0400000000',
        profession: profession,
        qualifications: 'PhD Psychology',
        expertise: expertise,
        state: state,
        location: location,
        deliveryOptions: deliveryOptions,
        website: null,
        status: PractitionerStatus.approved,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    test('empty filter matches everyone', () {
      expect(const SpecialistFilter().matches(practitioner()), isTrue);
    });

    test('state filter excludes a different state', () {
      const filter = SpecialistFilter(state: 'VIC');
      expect(filter.matches(practitioner(state: 'NSW')), isFalse);
      expect(filter.matches(practitioner(state: 'VIC')), isTrue);
    });

    test('profession filter excludes a different profession', () {
      const filter = SpecialistFilter(profession: Profession.counsellor);
      expect(filter.matches(practitioner(profession: Profession.psychologist)), isFalse);
      expect(filter.matches(practitioner(profession: Profession.counsellor)), isTrue);
    });

    test('delivery option filter matches on any overlap', () {
      const filter = SpecialistFilter(deliveryOptions: {DeliveryOption.telephone, DeliveryOption.online});
      expect(filter.matches(practitioner(deliveryOptions: const [DeliveryOption.online])), isTrue);
      expect(filter.matches(practitioner(deliveryOptions: const [DeliveryOption.faceToFace])), isFalse);
    });

    test('query matches name, profession, expertise, or location case-insensitively', () {
      final target = practitioner(fullName: 'Dr. Jane Doe', expertise: 'Bereavement counselling');
      expect(const SpecialistFilter(query: 'jane').matches(target), isTrue);
      expect(const SpecialistFilter(query: 'BEREAVEMENT').matches(target), isTrue);
      expect(const SpecialistFilter(query: 'sydney').matches(target), isTrue);
      expect(const SpecialistFilter(query: 'nonexistent').matches(target), isFalse);
    });
  });

  test('AdminStats.fromMap reads every field returned by admin_dashboard_stats()', () {
    final stats = AdminStats.fromMap({
      'total_users': 42,
      'total_practitioners': 5,
      'pending_practitioners': 2,
      'pending_posts': 3,
      'new_users_this_week': 7,
      'checkins_this_week': 19,
      'open_bug_reports': 4,
    });
    expect(stats.totalUsers, 42);
    expect(stats.totalPractitioners, 5);
    expect(stats.pendingPractitioners, 2);
    expect(stats.pendingPosts, 3);
    expect(stats.newUsersThisWeek, 7);
    expect(stats.checkinsThisWeek, 19);
    expect(stats.openBugReports, 4);
  });

  test('BugReportStatus.fromKey round-trips every status key stored in the database', () {
    for (final status in BugReportStatus.values) {
      expect(BugReportStatus.fromKey(status.key), status);
    }
  });
}
