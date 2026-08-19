import 'delivery_option.dart';
import 'profession.dart';

enum PractitionerStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  suspended('Suspended');

  const PractitionerStatus(this.label);

  final String label;

  static PractitionerStatus fromKey(String key) => PractitionerStatus.values.byName(key);
}

class Practitioner {
  const Practitioner({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.profession,
    required this.qualifications,
    required this.expertise,
    required this.state,
    required this.location,
    required this.deliveryOptions,
    required this.website,
    required this.status,
    required this.createdAt,
  });

  factory Practitioner.fromMap(Map<String, dynamic> map) {
    return Practitioner(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      profession: Profession.fromKey(map['profession'] as String),
      qualifications: map['qualifications'] as String,
      expertise: map['expertise'] as String?,
      state: map['state'] as String,
      location: map['location'] as String,
      deliveryOptions: (map['delivery_options'] as List)
          .map((option) => DeliveryOption.fromKey(option as String))
          .toList(),
      website: map['website'] as String?,
      status: PractitionerStatus.fromKey(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final Profession profession;
  final String qualifications;
  final String? expertise;
  final String state;
  final String location;
  final List<DeliveryOption> deliveryOptions;
  final String? website;
  final PractitionerStatus status;
  final DateTime createdAt;
}
