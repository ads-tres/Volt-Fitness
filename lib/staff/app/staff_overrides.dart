import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/network/api_client.dart';
import '../../core/time/clock.dart';
import '../core/desk_session.dart';
import '../fake_front_desk.dart';

/// What the front desk app replaces in the shared core: its own fake for
/// dev builds, and a revoked token ending the desk's session.
final List<Override> staffOverrides = [
  fakeBackendProvider.overrideWith((ref) => FakeFrontDesk(now: ref.watch(clockProvider))),
  onUnauthorizedProvider.overrideWith(
    (ref) =>
        () => unawaited(ref.read(deskSessionProvider.notifier).signOut()),
  ),
];
