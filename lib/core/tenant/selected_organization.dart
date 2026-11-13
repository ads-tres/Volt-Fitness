import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../auth/session_controller.dart';
import 'organization.dart';

/// The gym the member is acting in. Its slug goes in the path of every gym
/// call (`/me/gyms/{slug}/…`); the API checks the member belongs to it.
final selectedOrganizationProvider = Provider<Organization?>(
  (ref) => switch (ref.watch(sessionControllerProvider)) {
    SignedIn(:final organization) => organization,
    SignedOut() => null,
  },
);
