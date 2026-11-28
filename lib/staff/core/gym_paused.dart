import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure_messages.dart';
import 'desk_session.dart';

/// Whether the desk's gym is paused by the platform (the API's ADR 0043):
/// as `GET /me` said at sign-in, then as the gym's own routes answer. The
/// inbox and Today, which the desk reloads every few minutes, report each
/// answer, so the banner comes and goes without signing in again.
final class DeskGymPaused extends Notifier<bool> {
  @override
  bool build() => switch (ref.watch(deskSessionProvider)) {
    DeskSignedIn(gym: final gym?) => gym.paused,
    _ => false,
  };

  /// [failure] is what a gym route threw, or null when it answered.
  void report(Object? failure) {
    if (failure == null) {
      state = false;
    } else if (isGymPaused(failure)) {
      state = true;
    }
  }
}

final deskGymPausedProvider = NotifierProvider<DeskGymPaused, bool>(DeskGymPaused.new);
