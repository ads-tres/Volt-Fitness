import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/token_store.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';

import '../support/test_doubles.dart';

void main() {
  const demoGym = DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: 'receptionist', worksAtAllBranches: false);
  const main = DeskBranch(id: 1, name: 'Main Branch');

  test('the desk opens where it was left, and signing out forgets it', () async {
    final secureStore = InMemorySecureStore();
    final preferences = InMemoryPreferencesStore();
    Future<ProviderContainer> start() async => ProviderContainer.test(
      overrides: await testOverrides(secureStore: secureStore, preferences: preferences),
    );

    final first = await start();
    await first.read(deskSessionProvider.notifier).signIn(token: '9|desk', name: 'Selam', gyms: [demoGym]);
    await first.read(deskSessionProvider.notifier).selectBranch(main);

    final again = await start();
    expect(
      again.read(deskSessionProvider),
      isA<DeskSignedIn>()
          .having((session) => session.gym?.slug, 'gym', 'demo-gym')
          .having((session) => session.branch?.name, 'branch', 'Main Branch'),
    );

    await again.read(deskSessionProvider.notifier).signOut();
    expect(again.read(deskSessionProvider), isA<DeskSignedOut>());
    expect(again.read(tokenStoreProvider).token, isNull);
    expect(preferences.values.keys.where((key) => key.startsWith('desk.')), isEmpty);
  });

  test('changing the branch keeps the gym; choosing again forgets both', () async {
    final container = ProviderContainer.test(overrides: await testOverrides());
    final desk = container.read(deskSessionProvider.notifier);
    await desk.signIn(token: '9|desk', name: 'Selam', gyms: [demoGym, demoGym]);
    expect((container.read(deskSessionProvider) as DeskSignedIn).gym, isNull, reason: 'two gyms: a choice');

    await desk.selectGym(demoGym);
    await desk.selectBranch(main);
    await desk.chooseAgain();
    expect((container.read(deskSessionProvider) as DeskSignedIn).gym?.slug, 'demo-gym');
    expect((container.read(deskSessionProvider) as DeskSignedIn).branch, isNull);

    await desk.chooseAgain(gym: true);
    expect((container.read(deskSessionProvider) as DeskSignedIn).gym, isNull);
  });
}
