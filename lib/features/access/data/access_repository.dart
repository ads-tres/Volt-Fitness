import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/tenant/gym_path.dart';
import '../../../core/tenant/selected_organization.dart';
import '../domain/access_credential.dart';

/// The QR credential endpoints (`/me/gyms/{gym}/access-credential`). Both
/// throw a [Failure] when the call fails.
final class AccessRepository {
  AccessRepository(this._api, this._gym);

  final ApiClient _api;

  /// The selected gym's slug.
  final String? Function() _gym;

  /// Creates a credential for this phone in the selected gym. The API
  /// revokes the member's previous one, on any phone, and sends the secret
  /// only now, as base64 of its 32 bytes.
  Future<AccessCredential> issue() async {
    final data = dataObject(await _api.post(gymPath(_gym(), '/access-credential')));
    return readResponse<AccessCredential>(
      () => AccessCredential.fromHex(
        id: data.field<String>('credential_id'),
        secretHex: _hex(base64.decode(data.field<String>('secret'))),
        algorithm: data.field<String>('algorithm'),
      ),
    );
  }

  /// This phone's credential in the selected gym, or null if it has none.
  Future<CredentialStatus?> current() async {
    try {
      final data = dataObject(await _api.get(gymPath(_gym(), '/access-credential')));
      return readResponse<CredentialStatus>(
        () => CredentialStatus(
          credentialId: data.field<String>('credential_id'),
          isActive: data.field<String>('status') == 'active',
          revokedReason: data.optional<String>('revoked_reason'),
        ),
      );
    } on NotFoundFailure {
      return null;
    }
  }
}

String _hex(List<int> bytes) => [for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0')].join();

final accessRepositoryProvider = Provider<AccessRepository>(
  (ref) => AccessRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);

/// The credential secrets, one per gym, in secure storage. The key follows
/// the user-data naming, so signing out deletes them.
final class CredentialStore {
  CredentialStore(this._secure);

  static const _key = '${userDataPrefix}access_credentials';

  final SecureStore _secure;

  Future<AccessCredential?> read(String organizationId) async {
    final entry = (await _all())[organizationId];
    if (entry is! Map<String, dynamic>) return null;
    try {
      return AccessCredential.fromHex(
        id: entry.field<String>('id'),
        secretHex: entry.field<String>('secret'),
        algorithm: entry.field<String>('algorithm'),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String organizationId, AccessCredential credential) async {
    final all = await _all();
    all[organizationId] = {'id': credential.id, 'secret': credential.secretHex, 'algorithm': credential.algorithm};
    await _secure.write(_key, jsonEncode(all));
  }

  Future<void> delete(String organizationId) async {
    final all = await _all()
      ..remove(organizationId);
    await _secure.write(_key, jsonEncode(all));
  }

  Future<Map<String, dynamic>> _all() async {
    final stored = await _secure.read(_key);
    if (stored == null) return {};
    try {
      return jsonDecode(stored) as Map<String, dynamic>;
    } on FormatException {
      return {};
    }
  }
}

final credentialStoreProvider = Provider<CredentialStore>((ref) => CredentialStore(ref.watch(secureStoreProvider)));
