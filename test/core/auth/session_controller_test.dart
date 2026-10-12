import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/session_controller.dart';

import '../../support/test_doubles.dart';

void main() {
  test('a stored token restores the session, and signing out deletes it', () async {
    final secureStore = InMemorySecureStore();
    final container = ProviderContainer.test(
      overrides: await testOverrides(token: 'stored-token', secureStore: secureStore),
    );
    expect(container.read(sessionControllerProvider), SessionStatus.signedIn);

    await container.read(sessionControllerProvider.notifier).signOut();

    expect(container.read(sessionControllerProvider), SessionStatus.signedOut);
    expect(secureStore.values, isEmpty);
  });

  test('signing in keeps the token in secure storage', () async {
    final secureStore = InMemorySecureStore();
    final container = ProviderContainer.test(overrides: await testOverrides(secureStore: secureStore));
    expect(container.read(sessionControllerProvider), SessionStatus.signedOut);

    await container.read(sessionControllerProvider.notifier).signIn('new-token');

    expect(container.read(sessionControllerProvider), SessionStatus.signedIn);
    expect(secureStore.values, {'auth.token': 'new-token'});
  });
}
