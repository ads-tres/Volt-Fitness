import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../core/desk_session.dart';
import '../domain/door_list.dart';

/// The door list as signed: the list's exact JSON text, its Ed25519
/// signature and the key that made it.
typedef SignedDoorList = ({String list, String signature, String keyId});

/// The gym platform's door list public key, `key_id` and base64 key.
typedef DoorListKey = ({String keyId, String publicKey});

/// Why the desk has no door list to scan offline with.
enum DoorListProblem {
  /// The gym platform has no signing key yet (503).
  notSetUp,

  /// The list's signature didn't check out, or it was signed with another
  /// key than the one built into the app.
  badSignature,
}

final class DoorListRefused implements Exception {
  const DoorListRefused(this.problem);

  final DoorListProblem problem;
}

/// Downloads the door list, checks its signature and keeps it on the phone
/// (it holds day keys, so in secure storage, under the desk's prefix that
/// signing out wipes). A stored list is checked again whenever it is read.
final class DoorListRepository {
  DoorListRepository(this._api, this._session, this._secure, [this._builtInKey]);

  static const _listKey = '${DeskSessionController.prefix}door_list';
  static const _publicKeyKey = '${DeskSessionController.prefix}door_list_key';

  final ApiClient _api;
  final DeskSession Function() _session;
  final SecureStore _secure;

  /// The key this build trusts, from `--dart-define`; without one (dev
  /// builds) the gym platform's key is fetched once and kept.
  final DoorListKey? _builtInKey;

  /// Downloads a fresh list for [branchId], checks it and keeps it. Throws
  /// [DoorListRefused] when it can't be trusted or isn't set up, or a
  /// [Failure] when the call fails.
  Future<DoorList> download({int? branchId}) async {
    final Object? response;
    try {
      response = await _api.get(deskPath(_session(), '/door-list'), query: {'branch_id': ?branchId});
    } on ServerFailure catch (failure) {
      if (failure.statusCode == 503) throw const DoorListRefused(DoorListProblem.notSetUp);
      rethrow;
    }
    final data = dataObject(response);
    final signed = readResponse(
      () => (list: data.field<String>('list'), signature: data.field<String>('signature'), keyId: data.field<String>('key_id')),
    );
    final list = await _verified(signed, fetchKey: true);
    await _secure.write(_listKey, jsonEncode({'list': signed.list, 'signature': signed.signature, 'key_id': signed.keyId}));
    return list;
  }

  /// The list kept on the phone, if its signature still checks out.
  Future<DoorList?> stored() async {
    final stored = await _secure.read(_listKey);
    if (stored == null) return null;
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      return await _verified(
        (list: json.field<String>('list'), signature: json.field<String>('signature'), keyId: json.field<String>('key_id')),
        fetchKey: false,
      );
    } on Object {
      return null;
    }
  }

  Future<DoorList> _verified(SignedDoorList signed, {required bool fetchKey}) async {
    final key = await _keyFor(signed.keyId, fetch: fetchKey);
    if (key == null) throw const DoorListRefused(DoorListProblem.badSignature);
    final ok = await Ed25519().verify(
      utf8.encode(signed.list),
      signature: Signature(base64.decode(signed.signature), publicKey: SimplePublicKey(base64.decode(key.publicKey), type: KeyPairType.ed25519)),
    );
    if (!ok) throw const DoorListRefused(DoorListProblem.badSignature);
    return DoorList.parse(signed.list);
  }

  /// The key for [keyId]: the built-in one, which must match, or else the
  /// one fetched and kept, fetched again when the id changes.
  Future<DoorListKey?> _keyFor(String keyId, {required bool fetch}) async {
    if (_builtInKey case final builtIn?) return builtIn.keyId == keyId ? builtIn : null;
    final kept = await _secure.read(_publicKeyKey);
    if (kept != null) {
      final json = jsonDecode(kept) as Map<String, dynamic>;
      if (json['key_id'] == keyId) return (keyId: keyId, publicKey: json.field<String>('public_key'));
    }
    if (!fetch) return null;
    final data = dataObject(await _api.get(deskPath(_session(), '/door-list/public-key')));
    final key = readResponse(() => (keyId: data.field<String>('key_id'), publicKey: data.field<String>('public_key')));
    if (key.keyId != keyId) return null;
    await _secure.write(_publicKeyKey, jsonEncode({'key_id': key.keyId, 'public_key': key.publicKey}));
    return key;
  }
}

/// The key built into staging and prod: `--dart-define=DOOR_LIST_PUBLIC_KEY=…`
/// and `--dart-define=DOOR_LIST_KEY_ID=…`.
DoorListKey? builtInDoorListKey() {
  const publicKey = String.fromEnvironment('DOOR_LIST_PUBLIC_KEY');
  const keyId = String.fromEnvironment('DOOR_LIST_KEY_ID');
  return publicKey.isEmpty || keyId.isEmpty ? null : (keyId: keyId, publicKey: publicKey);
}

final doorListKeyProvider = Provider<DoorListKey?>((ref) => builtInDoorListKey());

final doorListRepositoryProvider = Provider<DoorListRepository>(
  (ref) => DoorListRepository(
    ref.watch(apiClientProvider),
    () => ref.read(deskSessionProvider),
    ref.watch(secureStoreProvider),
    ref.watch(doorListKeyProvider),
  ),
);
