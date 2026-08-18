import '../data/message_with_state.dart';

enum MessageFilter {
  all('All'),
  saved('Saved'),
  favourites('Favourites');

  const MessageFilter(this.label);

  final String label;
}

List<MessageWithState> applyMessageFilter(List<MessageWithState> messages, MessageFilter filter) {
  return switch (filter) {
    MessageFilter.all => messages,
    MessageFilter.saved => messages.where((item) => item.saved).toList(),
    MessageFilter.favourites => messages.where((item) => item.favourited).toList(),
  };
}
