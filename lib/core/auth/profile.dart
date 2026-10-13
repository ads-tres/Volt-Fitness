import '../tenant/organization.dart';

/// The signed-in member and the gyms their phone number belongs to.
final class Profile {
  const Profile({required this.user, required this.organizations});

  final User user;
  final List<Organization> organizations;

  Organization? organization(String? id) {
    for (final organization in organizations) {
      if (organization.id == id) return organization;
    }
    return null;
  }
}

final class User {
  const User({required this.id, required this.phone, this.name});

  final String id;
  final String phone;
  final String? name;

  /// "Abebe" from "Abebe Kebede", for greetings.
  String? get firstName {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed.split(RegExp(r'\s+')).first;
  }
}
