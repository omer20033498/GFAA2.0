import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/daily_message.dart';
import '../data/message_repository.dart';
import '../data/message_with_state.dart';

final messageRepositoryProvider = Provider((ref) => MessageRepository());

/// User-facing: messages merged with this user's save/favourite state. A
/// plain fetch, refreshed via `ref.invalidate` after any action and via
/// pull-to-refresh — same reasoning as journaling/check-ins (no realtime
/// subscription; see project memory for why).
final messagesWithStateProvider = FutureProvider<List<MessageWithState>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final repository = ref.watch(messageRepositoryProvider);
  final messages = await repository.fetchMessages();
  final states = await repository.fetchUserMessageStates(userId);
  return [
    for (final message in messages)
      MessageWithState(
        message: message,
        saved: states[message.id]?.saved ?? false,
        favourited: states[message.id]?.favourited ?? false,
      ),
  ];
});

/// Admin-facing: just the raw sent history, no per-user state needed.
final sentMessagesProvider = FutureProvider<List<DailyMessage>>((ref) {
  return ref.watch(messageRepositoryProvider).fetchMessages();
});
