import 'daily_message.dart';

/// A daily message merged with the current user's save/favourite state —
/// there's no `user_messages` row at all until they interact with a
/// message for the first time, so this is always the "effective" state
/// (missing row == not saved, not favourited).
class MessageWithState {
  const MessageWithState({required this.message, required this.saved, required this.favourited});

  final DailyMessage message;
  final bool saved;
  final bool favourited;
}
