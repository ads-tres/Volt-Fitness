import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/failure.dart';
import '../data/auth_repository.dart';

/// Revokes the session on the server, then forgets it on this phone. When
/// offline, the phone still signs out; the member can remove the device from
/// their device list later.
Future<void> signOut(WidgetRef ref) async {
  try {
    await ref.read(authRepositoryProvider).signOut();
  } on Failure {
    // Sign out locally regardless.
  }
  await ref.read(sessionControllerProvider.notifier).signOut();
}
