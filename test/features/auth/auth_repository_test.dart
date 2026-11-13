import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/features/auth/data/auth_repository.dart';

import '../../support/test_doubles.dart';

void main() {
  test('asks the API to send a code', () async {
    final adapter = StubAdapter((_) => jsonResponse(202, {'message': 'If this number is registered…'}));
    final container = await containerWithAdapter(adapter);

    final challenge = await container.read(authRepositoryProvider).requestCode('+251922345678');

    final request = adapter.requests.single;
    expect((request.method, request.path), ('POST', '/auth/sms-codes'));
    expect(request.data, {'phone': '+251922345678'});
    expect(challenge.resendIn, const Duration(minutes: 1));
  });

  test('signs in with the code, then lists the gyms with the new token, each by its slug', () async {
    final adapter = StubAdapter(
      (request) => switch (request.path) {
        '/auth/sms-tokens' => jsonResponse(201, {
          'data': {
            'token': '42|secret',
            'user': {'id': 7, 'name': 'Tigist Haile', 'email': null, 'phone': '+251922345678'},
          },
        }),
        '/me/gyms' => jsonResponse(200, {
          'data': [
            {'slug': 'demo-gym', 'name': 'Demo Gym', 'member': {'id': 2}, 'membership': null},
          ],
        }),
        _ => jsonResponse(404, {'message': 'Not found.'}),
      },
    );
    final container = await containerWithAdapter(adapter);

    final result = await container.read(authRepositoryProvider).verifyCode(phone: '+251922345678', code: '123456');

    final [signIn, gyms] = adapter.requests;
    expect(signIn.data, {'phone': '+251922345678', 'code': '123456', 'device_name': 'samsung SM-J600G'});
    expect(gyms.headers['Authorization'], 'Bearer 42|secret');
    expect(result.token, '42|secret');
    expect(result.profile.user.id, '7');
    expect(result.profile.user.firstName, 'Tigist');
    expect(result.profile.organizations.single.id, 'demo-gym');
    expect(result.profile.organizations.single.name, 'Demo Gym');
  });

  test('a wrong code fails on the code field', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(422, {
        'message': 'The code is wrong or has expired.',
        'errors': {
          'code': ['The code is wrong or has expired.'],
        },
      }),
    );
    final container = await containerWithAdapter(adapter);

    await expectLater(
      container.read(authRepositoryProvider).verifyCode(phone: '+251922345678', code: '000000'),
      throwsA(isA<ValidationFailure>().having((f) => f.fieldErrors.keys, 'fields', contains('code'))),
    );
  });

  test('signs out by revoking this phone\'s token', () async {
    final adapter = StubAdapter((_) => jsonResponse(204, null));
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));

    await container.read(authRepositoryProvider).signOut();

    expect((adapter.requests.single.method, adapter.requests.single.path), ('DELETE', '/auth/tokens/current'));
  });
}
