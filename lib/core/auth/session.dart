import '../tenant/organization.dart';
import 'profile.dart';

sealed class Session {
  const Session();
}

final class SignedOut extends Session {
  const SignedOut();
}

final class SignedIn extends Session {
  const SignedIn({required this.profile, this.organizationId});

  final Profile profile;

  /// The gym the member is acting in. Null until they pick one, which only
  /// happens when their number belongs to several gyms.
  final String? organizationId;

  Organization? get organization => profile.organization(organizationId);
}
