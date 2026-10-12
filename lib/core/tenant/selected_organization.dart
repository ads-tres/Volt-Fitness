import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The gym the member is acting in, sent as `X-Organization-ID`. It is only
/// context for the API, which checks the member really belongs to it.
/// Chosen after sign-in (Phase 2); null until then.
final class SelectedOrganization extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? organizationId) => state = organizationId;
}

final selectedOrganizationProvider = NotifierProvider<SelectedOrganization, String?>(
  SelectedOrganization.new,
);
