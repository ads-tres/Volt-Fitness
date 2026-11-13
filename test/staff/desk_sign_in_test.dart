import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/features/auth/data/desk_auth_repository.dart';

import '../support/desk_driver.dart';
import '../support/test_doubles.dart';

void main() {
  test('signs in with phone and password, then reads the gyms with the new token', () async {
    final adapter = StubAdapter(
      (request) => switch (request.path) {
        '/auth/tokens' => jsonResponse(201, {
          'data': {
            'token': '9|desk',
            'user': {'id': 1, 'name': 'Demo Owner', 'email': null, 'phone': '+251911000001'},
          },
        }),
        _ => jsonResponse(200, {
          'data': {
            'user': {'id': 1, 'name': 'Demo Owner', 'email': null, 'phone': '+251911000001'},
            'staff': [
              {
                'organization': {'slug': 'demo-gym', 'name': 'Demo Gym'},
                'role': 'owner',
                'works_at_all_branches': true,
              },
            ],
          },
        }),
      },
    );
    final container = await containerWithAdapter(adapter);

    final signedIn = await container.read(deskAuthRepositoryProvider).signIn(phone: '+251911000001', password: 'secret');

    final [tokens, me] = adapter.requests;
    expect(tokens.data, {'phone': '+251911000001', 'password': 'secret', 'device_name': 'samsung SM-J600G'});
    expect(me.headers['Authorization'], 'Bearer 9|desk');
    expect(signedIn.name, 'Demo Owner');
    expect(signedIn.gyms.single.slug, 'demo-gym');
    expect(signedIn.gyms.single.worksAtAllBranches, isTrue);
  });

  testWidgets('a wrong password shows the API\'s words', (tester) async {
    await startDesk(tester);

    await signInAtDesk(tester, password: 'wrong');

    expect(find.text('These credentials do not match our records.'), findsOneWidget);
  });

  testWidgets('staff at one gym choose the branch, and the scanner says where it is', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester);

    expect(find.text('Which branch is this desk at?'), findsOneWidget);
    await tester.tap(find.text('Bole Branch'));
    await tester.pumpAndSettle();

    expect(find.text('Bole Branch · Demo Gym'), findsOneWidget);
  });

  testWidgets('staff at two gyms choose the gym; one branch there is chosen for them', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester, phone: '0911 00 00 02');

    expect(find.text('Choose the gym'), findsOneWidget);
    await tester.tap(find.text('Demo Gym'));
    await tester.pumpAndSettle();

    expect(find.text('Main Branch · Demo Gym'), findsOneWidget);
  });

  testWidgets('signing out from the menu returns to sign-in', (tester) async {
    await startDesk(tester);
    await signInAtDesk(tester);
    await tester.tap(find.text('Main Branch'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to the front desk'), findsOneWidget);
  });
}
