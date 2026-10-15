import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/access_credential.dart';

/// The QR credential endpoints. Both throw a [Failure] when the call fails.
final class AccessRepository {
  AccessRepository(this._api);

  final ApiClient _api;

  /// Creates a credential for this phone in the selected gym. The API
  /// revokes the member's previous one there, and sends the secret only now.
  Future<AccessCredential> issue() async {
    final data = dataObject(await _api.post('/access/credentials'));
    return readResponse<AccessCredential>(
      () => AccessCredential.fromHex(
        id: data.field<String>('credential_id'),
        secretHex: data.field<String>('secret'),
        algorithm: data.field<String>('algorithm'),
      ),
    );
  }

  /// This phone's credential in the selected gym, or null if it has none.
  Future<CredentialStatus?> current() async {
    try {
      final data = dataObject(await _api.get('/access/credentials/current'));
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

final accessRepositoryProvider = Provider<AccessRepository>((ref) => AccessRepository(ref.watch(apiClientProvider)));

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
