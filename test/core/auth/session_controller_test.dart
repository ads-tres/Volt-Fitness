import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/session.dart';
import 'package:gym_mobile/core/auth/session_controller.dart';

import '../../support/test_doubles.dart';

void main() {
  test('a stored token and profile restore the session in the saved gym', () async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(signedInAs: memberOf([boleGym, kazanchisGym]), organizationId: kazanchisGym.id),
    );

    final session = container.read(sessionControllerProvider);

    expect(session, isA<SignedIn>().having((s) => s.organization?.name, 'gym', 'Kazanchis Fit Club'));
  });

  test('signing in to one gym selects it; several gyms wait for a choice', () async {
    final container = ProviderContainer.test(overrides: await testOverrides());
    final controller = container.read(sessionControllerProvider.notifier);

    await controller.signIn(token: 't1', profile: memberOf([boleGym]));
    expect((container.read(sessionControllerProvider) as SignedIn).organizationId, boleGym.id);

    await controller.signIn(token: 't2', profile: memberOf([boleGym, kazanchisGym]));
    expect((container.read(sessionControllerProvider) as SignedIn).organizationId, isNull);

    await controller.selectOrganization(kazanchisGym.id);
    expect((container.read(sessionControllerProvider) as SignedIn).organizationId, kazanchisGym.id);
  });

  test('a refreshed profile drops a gym the member left', () async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(signedInAs: memberOf([boleGym, kazanchisGym]), organizationId: kazanchisGym.id),
    );

    await container.read(sessionControllerProvider.notifier).updateProfile(memberOf([boleGym]));

    expect((container.read(sessionControllerProvider) as SignedIn).organizationId, boleGym.id);
  });

  test('signing out forgets the token, profile and gym', () async {
    final secureStore = InMemorySecureStore();
    final preferences = InMemoryPreferencesStore();
    final container = ProviderContainer.test(
      overrides: await testOverrides(
        signedInAs: memberOf([boleGym]),
        secureStore: secureStore,
        preferences: preferences,
      ),
    );

    await container.read(sessionControllerProvider.notifier).signOut();

    expect(container.read(sessionControllerProvider), isA<SignedOut>());
    expect(secureStore.values, isEmpty);
    expect(preferences.values.keys.where((key) => key.startsWith('session.')), isEmpty);
  });
}
