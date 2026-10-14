import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_store.dart';

/// Whether this install has been through the welcome pages. They show once,
/// before the first sign-in.
final class OnboardingController extends Notifier<bool> {
  static const _key = 'onboarding.done';

  @override
  bool build() => ref.watch(preferencesStoreProvider).getString(_key) == 'true';

  Future<void> complete() async {
    await ref.read(preferencesStoreProvider).setString(_key, 'true');
    state = true;
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingController, bool>(OnboardingController.new);
