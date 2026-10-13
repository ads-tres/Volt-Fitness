import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../auth/session_controller.dart';
import 'organization.dart';

/// The gym the member is acting in, sent as `X-Organization-ID`. It is only
/// context for the API, which checks the member really belongs to it.
final selectedOrganizationProvider = Provider<Organization?>(
  (ref) => switch (ref.watch(sessionControllerProvider)) {
    SignedIn(:final organization) => organization,
    SignedOut() => null,
  },
);
