import '../../../core/supabase/supabase_client.dart';
import '../../auth/data/auth_repository.dart';
import 'delivery_option.dart';
import 'practitioner.dart';
import 'profession.dart';

class PractitionerRepository {
  PractitionerRepository(this._authRepository);

  final AuthRepository _authRepository;

  /// Public directory. RLS already restricts general SELECT to
  /// approved-and-paid listings, but a practitioner also sees their *own*
  /// listing regardless of status (so their portal works) — that row must
  /// not leak into this general browse list, hence the explicit filter.
  Future<List<Practitioner>> fetchDirectory() async {
    final rows = await supabase
        .from('practitioners')
        .select()
        .eq('status', 'approved')
        .order('full_name');
    return rows.map(Practitioner.fromMap).toList();
  }

  /// Null if this account never applied.
  Future<Practitioner?> fetchMyApplication(String userId) async {
    final rows = await supabase.from('practitioners').select().eq('user_id', userId).limit(1);
    if (rows.isEmpty) return null;
    return Practitioner.fromMap(rows.first);
  }

  /// Admin moderation queue, one status at a time. Pending is oldest-first
  /// (FIFO); the others are newest-first.
  Future<List<Practitioner>> fetchByStatus(PractitionerStatus status) async {
    final rows = await supabase
        .from('practitioners')
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: status == PractitionerStatus.pending);
    return rows.map(Practitioner.fromMap).toList();
  }

  /// Every practitioner regardless of status, for admin's export — RLS's
  /// "admin sees everything" clause makes the plain unfiltered select work.
  Future<List<Practitioner>> fetchAll() async {
    final rows = await supabase.from('practitioners').select().order('created_at');
    return rows.map(Practitioner.fromMap).toList();
  }

  /// Creates the auth account *and* a pending practitioner application in
  /// one step, via sign-up metadata read by the `handle_new_user()` trigger
  /// (migration 0008) — not a separate authenticated insert, since there's
  /// no active session yet at this point (email confirmation is required
  /// before sign-in works in this project).
  Future<void> applyAsPractitioner({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required Profession profession,
    required String qualifications,
    required String? expertise,
    required String state,
    required String location,
    required List<DeliveryOption> deliveryOptions,
    required String? website,
  }) {
    return _authRepository.signUpWithMetadata(
      email: email,
      password: password,
      data: {
        'practitioner_application': true,
        'display_name': fullName,
        'full_name': fullName,
        'phone': phone,
        'profession': profession.key,
        'qualifications': qualifications,
        if (expertise != null && expertise.isNotEmpty) 'expertise': expertise,
        'state': state,
        'location': location,
        'delivery_options': deliveryOptions.map((option) => option.key).toList(),
        if (website != null && website.isNotEmpty) 'website': website,
      },
    );
  }

  /// The practitioner editing their own listing details. `status` isn't
  /// settable here — the DB trigger forces it to stay unchanged for
  /// non-admin callers regardless of what's sent.
  Future<void> updateListing({
    required String id,
    required String fullName,
    required String phone,
    required Profession profession,
    required String qualifications,
    required String? expertise,
    required String state,
    required String location,
    required List<DeliveryOption> deliveryOptions,
    required String? website,
  }) async {
    final updated = await supabase
        .from('practitioners')
        .update({
          'full_name': fullName,
          'phone': phone,
          'profession': profession.key,
          'qualifications': qualifications,
          'expertise': expertise,
          'state': state,
          'location': location,
          'delivery_options': deliveryOptions.map((option) => option.key).toList(),
          'website': website,
        })
        .eq('id', id)
        .select();
    if (updated.isEmpty) {
      throw StateError("Couldn't find that listing to update.");
    }
  }

  /// Admin-only (enforced by RLS + protect_practitioner_status trigger).
  /// Approving/suspending also syncs profiles.role server-side (see
  /// sync_practitioner_role trigger, migration 0008) — nothing extra to do
  /// here for that.
  Future<void> setStatus({required String id, required PractitionerStatus status}) async {
    final updated = await supabase
        .from('practitioners')
        .update({'status': status.name})
        .eq('id', id)
        .select();
    if (updated.isEmpty) {
      throw StateError("Couldn't find that application to update.");
    }
  }

  /// Updates just the public contact email shown in the directory listing —
  /// separate from the account's *login* email, which the caller updates
  /// via AuthRepository.updateEmail (Supabase's own confirmation flow).
  Future<void> updateContactEmail({required String id, required String email}) async {
    final updated = await supabase.from('practitioners').update({'email': email}).eq('id', id).select();
    if (updated.isEmpty) {
      throw StateError("Couldn't find that listing to update.");
    }
  }

  /// Admin-only (enforced by RLS). Removes the listing entirely — distinct
  /// from suspending, which keeps the record but hides it.
  Future<void> deleteListing(String id) async {
    final deleted = await supabase.from('practitioners').delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw StateError("Couldn't find that listing to delete.");
    }
  }
}
