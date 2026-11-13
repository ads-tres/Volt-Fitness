import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/token_store.dart';
import '../../core/network/json.dart';
import '../../core/storage/preferences_store.dart';

/// A gym the staff member works at, as `GET /me` lists it.
final class DeskGym {
  const DeskGym({required this.slug, required this.name, required this.role, required this.worksAtAllBranches});

  final String slug;
  final String name;

  /// `owner`, `manager`, `receptionist`, `trainer` or `accountant`.
  final String role;
  final bool worksAtAllBranches;
}

/// The branch whose door this phone is at.
final class DeskBranch {
  const DeskBranch({required this.id, required this.name});

  final int id;
  final String name;
}

sealed class DeskSession {
  const DeskSession();
}

final class DeskSignedOut extends DeskSession {
  const DeskSignedOut();
}

/// Signed in, and, once chosen, at a gym and one of its branches.
final class DeskSignedIn extends DeskSession {
  const DeskSignedIn({required this.name, required this.gyms, this.gym, this.branch});

  final String name;
  final List<DeskGym> gyms;
  final DeskGym? gym;
  final DeskBranch? branch;

  DeskSignedIn copyWith({DeskGym? gym, DeskBranch? branch, bool clearGym = false, bool clearBranch = false}) =>
      DeskSignedIn(
        name: name,
        gyms: gyms,
        gym: clearGym ? null : (gym ?? this.gym),
        branch: clearGym || clearBranch ? null : (branch ?? this.branch),
      );
}

/// Who is signed in on this front desk phone, at which gym and branch. The
/// token is in secure storage; the rest is remembered in preferences, so the
/// desk opens straight on the scanner. A staff member at one gym gets it
/// chosen for them.
final class DeskSessionController extends Notifier<DeskSession> {
  /// Every key the front desk keeps starts with this; signing out deletes them.
  static const prefix = 'desk.';
  static const _key = '${prefix}session';

  @override
  DeskSession build() {
    final token = ref.watch(tokenStoreProvider).token;
    final stored = ref.watch(preferencesStoreProvider).getString(_key);
    if (token == null || stored == null) return const DeskSignedOut();
    try {
      return _fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on Object {
      return const DeskSignedOut();
    }
  }

  Future<void> signIn({required String token, required String name, required List<DeskGym> gyms}) async {
    await ref.read(tokenStoreProvider).save(token);
    await _save(DeskSignedIn(name: name, gyms: gyms, gym: gyms.length == 1 ? gyms.single : null));
  }

  Future<void> selectGym(DeskGym gym) async {
    if (state case final DeskSignedIn session) await _save(session.copyWith(gym: gym, clearBranch: true));
  }

  Future<void> selectBranch(DeskBranch branch) async {
    if (state case final DeskSignedIn session) await _save(session.copyWith(branch: branch));
  }

  /// Back to choosing the branch, or the gym too when [gym] is true.
  Future<void> chooseAgain({bool gym = false}) async {
    if (state case final DeskSignedIn session) await _save(session.copyWith(clearGym: gym, clearBranch: true));
  }

  /// Ends the session on this phone. To end it on the server too, revoke
  /// the token first.
  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    await ref.read(preferencesStoreProvider).removePrefixed(prefix);
    state = const DeskSignedOut();
  }

  Future<void> _save(DeskSignedIn session) async {
    await ref.read(preferencesStoreProvider).setString(_key, jsonEncode(_toJson(session)));
    state = session;
  }

  static Map<String, Object?> _toJson(DeskSignedIn session) => {
    'name': session.name,
    'gyms': [for (final gym in session.gyms) _gymToJson(gym)],
    'gym': session.gym?.slug,
    'branch': switch (session.branch) {
      final branch? => {'id': branch.id, 'name': branch.name},
      null => null,
    },
  };

  static Map<String, Object?> _gymToJson(DeskGym gym) => {
    'organization': {'slug': gym.slug, 'name': gym.name},
    'role': gym.role,
    'works_at_all_branches': gym.worksAtAllBranches,
  };

  static DeskSignedIn _fromJson(Map<String, dynamic> json) {
    final gyms = [for (final gym in json.objects('gyms')) deskGymFromJson(gym)];
    final slug = json.optional<String>('gym');
    return DeskSignedIn(
      name: json.field<String>('name'),
      gyms: gyms,
      gym: gyms.where((gym) => gym.slug == slug).firstOrNull,
      branch: switch (json.optional<Map<String, dynamic>>('branch')) {
        final branch? => DeskBranch(id: branch.field<int>('id'), name: branch.field<String>('name')),
        null => null,
      },
    );
  }
}

/// One of `GET /me`'s `staff` entries.
DeskGym deskGymFromJson(Map<String, dynamic> json) {
  final organization = json.field<Map<String, dynamic>>('organization');
  return DeskGym(
    slug: organization.field<String>('slug'),
    name: organization.field<String>('name'),
    role: json.optional<String>('role') ?? 'receptionist',
    worksAtAllBranches: json.optional<bool>('works_at_all_branches') ?? false,
  );
}

final deskSessionProvider = NotifierProvider<DeskSessionController, DeskSession>(DeskSessionController.new);

/// The API path of [path] in the staff member's gym: `/organizations/{slug}{path}`.
String deskPath(DeskSession session, String path) => switch (session) {
  DeskSignedIn(gym: final gym?) => '/organizations/${Uri.encodeComponent(gym.slug)}$path',
  _ => throw StateError('No gym is chosen'),
};
