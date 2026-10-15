import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/tenant/selected_organization.dart';
import '../domain/access_credential.dart';
import 'access_repository.dart';

sealed class AccessCard {
  const AccessCard();
}

final class ActiveCard extends AccessCard {
  const ActiveCard(this.credential);

  final AccessCredential credential;
}

/// The credential was revoked on the server; [reason] says why.
final class RevokedCard extends AccessCard {
  const RevokedCard(this.reason);

  final String? reason;
}

/// The QR card for the selected gym. A stored credential shows at once and
/// works offline; the API is asked in the background whether it is still
/// active. Without one, a credential is created, which needs the internet.
final class AccessCardController extends AsyncNotifier<AccessCard> {
  @override
  Future<AccessCard> build() async {
    final organizationId = ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
    if (organizationId == null) throw const UnexpectedFailure();
    final stored = await ref.read(credentialStoreProvider).read(organizationId);
    if (stored != null) {
      unawaited(_confirm(organizationId, stored));
      return ActiveCard(stored);
    }
    return ActiveCard(await _issue(organizationId));
  }

  /// Moves the QR to this phone after another phone took it over. The
  /// other phone's code stops working.
  Future<void> useThisPhone() async {
    final organizationId = ref.read(selectedOrganizationProvider)?.id;
    if (organizationId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => ActiveCard(await _issue(organizationId)));
  }

  Future<AccessCredential> _issue(String organizationId) async {
    final credential = await ref.read(accessRepositoryProvider).issue();
    await ref.read(credentialStoreProvider).write(organizationId, credential);
    return credential;
  }

  Future<void> _confirm(String organizationId, AccessCredential stored) async {
    try {
      final status = await ref.read(accessRepositoryProvider).current();
      if (!ref.mounted) return;
      if (status == null || (status.isActive && status.credentialId != stored.id)) {
        // The API has no credential for this phone, or a newer one: the
        // stored code would be rejected, so set up a fresh one.
        final fresh = await _issue(organizationId);
        if (ref.mounted) state = AsyncData(ActiveCard(fresh));
      } else if (!status.isActive) {
        await ref.read(credentialStoreProvider).delete(organizationId);
        if (ref.mounted) state = AsyncData(RevokedCard(status.revokedReason));
      }
    } on Failure {
      // Offline or failing: keep showing the stored code.
    }
  }
}

final accessCardProvider = AsyncNotifierProvider<AccessCardController, AccessCard>(AccessCardController.new);
