import '../data/delivery_option.dart';
import '../data/practitioner.dart';
import '../data/profession.dart';

class SpecialistFilter {
  const SpecialistFilter({
    this.query = '',
    this.state,
    this.profession,
    this.deliveryOptions = const {},
  });

  final String query;
  final String? state;
  final Profession? profession;
  final Set<DeliveryOption> deliveryOptions;

  bool matches(Practitioner practitioner) {
    if (state != null && practitioner.state != state) return false;
    if (profession != null && practitioner.profession != profession) return false;
    if (deliveryOptions.isNotEmpty &&
        !deliveryOptions.any((option) => practitioner.deliveryOptions.contains(option))) {
      return false;
    }
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return true;
    final haystack = [
      practitioner.fullName,
      practitioner.profession.label,
      practitioner.expertise ?? '',
      practitioner.location,
    ].join(' ').toLowerCase();
    return haystack.contains(trimmedQuery);
  }
}

List<Practitioner> applySpecialistFilter(List<Practitioner> practitioners, SpecialistFilter filter) {
  return practitioners.where(filter.matches).toList();
}
