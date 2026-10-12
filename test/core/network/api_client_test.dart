import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/session_controller.dart';
import 'package:gym_mobile/core/auth/token_store.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/localization/locale_controller.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/tenant/selected_organization.dart';

import '../../support/test_doubles.dart';

Future<Failure> failureOf(Future<Object?> call) async {
  try {
    await call;
  } on Failure catch (failure) {
    return failure;
  }
  fail('Expected the call to throw a Failure');
}

void main() {
  group('Every request', () {
    test('carries the device, app, language and a new request ID', () async {
      final adapter = StubAdapter((_) => jsonResponse(200, {'data': <String, Object?>{}}));
      final container = await containerWithAdapter(adapter);
      final api = container.read(apiClientProvider);

      await api.get('/me');
      await api.get('/me');

      final headers = adapter.requests.first.headers;
      expect(headers[Headers.acceptHeader], 'application/json');
      expect(headers['Accept-Language'], 'en');
      expect(headers['X-Device-ID'], 'installation-1');
      expect(headers['X-App-Version'], '1.0.0');
      expect(headers['X-App-Build'], '7');
      expect(headers['X-Platform'], 'android');
      expect(headers['X-Request-ID'], isA<String>());
      expect(headers['X-Request-ID'], isNot(adapter.requests.last.headers['X-Request-ID']));
    });

    test('has no token or gym before sign-in', () async {
      final adapter = StubAdapter((_) => jsonResponse(200, null));
      final container = await containerWithAdapter(adapter);

      await container.read(apiClientProvider).get('/app-config');

      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
      expect(adapter.requests.single.headers.containsKey('X-Organization-ID'), isFalse);
    });

    test('carries the token, the selected gym and the chosen language', () async {
      final adapter = StubAdapter((_) => jsonResponse(200, null));
      final container = await containerWithAdapter(adapter, token: 'token-1');
      container.read(selectedOrganizationProvider.notifier).select('01K7Z6ABCDEFGHJKMNPQRSTVWX');
      await container.read(localeControllerProvider.notifier).select(const Locale('am'));

      await container.read(apiClientProvider).get('/me');

      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'], 'Bearer token-1');
      expect(headers['X-Organization-ID'], '01K7Z6ABCDEFGHJKMNPQRSTVWX');
      expect(headers['Accept-Language'], 'am');
    });

    test('gets an Idempotency-Key only when the caller passes one', () async {
      final adapter = StubAdapter((_) => jsonResponse(201, null));
      final container = await containerWithAdapter(adapter, token: 'token-1');
      final api = container.read(apiClientProvider);

      await api.post('/payments/attempts', body: {'plan_id': 'p1'}, idempotencyKey: 'key-1');
      await api.post('/auth/logout');

      expect(adapter.requests.first.headers['Idempotency-Key'], 'key-1');
      expect(adapter.requests.last.headers.containsKey('Idempotency-Key'), isFalse);
    });
  });

  group('A 401', () {
    test('ends the session and forgets the token', () async {
      final adapter = StubAdapter((_) => jsonResponse(401, {'message': 'Unauthenticated.', 'code': 'UNAUTHENTICATED'}));
      final container = await containerWithAdapter(adapter, token: 'revoked-token');
      expect(container.read(sessionControllerProvider), SessionStatus.signedIn);

      final failure = await failureOf(container.read(apiClientProvider).get('/me'));
      await pumpEventQueue();

      expect(failure, isA<UnauthenticatedFailure>());
      expect(container.read(sessionControllerProvider), SessionStatus.signedOut);
      expect(container.read(tokenStoreProvider).token, isNull);
    });

    test('for a token that was already replaced leaves the new session alone', () async {
      late ProviderContainer container;
      final adapter = StubAdapter((_) async {
        // The member signed in again while this old request was in flight.
        await container.read(sessionControllerProvider.notifier).signIn('new-token');
        return jsonResponse(401, {'message': 'Unauthenticated.'});
      });
      container = await containerWithAdapter(adapter, token: 'old-token');

      await failureOf(container.read(apiClientProvider).get('/me'));
      await pumpEventQueue();

      expect(container.read(sessionControllerProvider), SessionStatus.signedIn);
      expect(container.read(tokenStoreProvider).token, 'new-token');
    });
  });

  group('Errors become failures', () {
    test('422 keeps the code, the field errors and the request ID', () async {
      final adapter = StubAdapter(
        (_) => jsonResponse(422, {
          'message': 'The code you entered is incorrect.',
          'code': 'OTP_INVALID',
          'errors': {
            'code': ['The code you entered is incorrect.'],
          },
          'request_id': 'request-1',
        }),
      );
      final container = await containerWithAdapter(adapter);

      final failure = await failureOf(container.read(apiClientProvider).post('/auth/otp/verify'));

      expect(
        failure,
        isA<ValidationFailure>()
            .having((f) => f.code, 'code', 'OTP_INVALID')
            .having((f) => f.message, 'message', 'The code you entered is incorrect.')
            .having((f) => f.fieldErrors, 'fieldErrors', {
              'code': ['The code you entered is incorrect.'],
            })
            .having((f) => f.requestId, 'requestId', 'request-1'),
      );
    });

    test('429 reads how long to wait', () async {
      final adapter = StubAdapter(
        (_) => jsonResponse(
          429,
          {'message': 'Too Many Attempts.', 'code': 'RATE_LIMITED'},
          headers: {
            'retry-after': ['30'],
          },
        ),
      );
      final container = await containerWithAdapter(adapter);

      final failure = await failureOf(container.read(apiClientProvider).post('/auth/otp/request'));

      expect(failure, isA<RateLimitedFailure>().having((f) => f.retryAfter, 'retryAfter', const Duration(seconds: 30)));
    });

    test('426 asks for an app update', () async {
      final adapter = StubAdapter((_) => jsonResponse(426, {'code': 'APP_UPDATE_REQUIRED'}));
      final container = await containerWithAdapter(adapter);

      expect(await failureOf(container.read(apiClientProvider).get('/me')), isA<UpdateRequiredFailure>());
    });

    test('an HTML error page from a proxy is a server failure with our request ID', () async {
      final adapter = StubAdapter(
        (_) => ResponseBody.fromString(
          '<html>502 Bad Gateway</html>',
          502,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        ),
      );
      final container = await containerWithAdapter(adapter);

      final failure = await failureOf(container.read(apiClientProvider).get('/me'));

      expect(failure, isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 502));
      expect(failure.code, isNull);
      expect(failure.requestId, adapter.requests.single.headers['X-Request-ID']);
    });

    test('no connection is a network failure', () async {
      final adapter = StubAdapter((_) => throw const SocketException('Connection refused'));
      final container = await containerWithAdapter(adapter);

      expect(await failureOf(container.read(apiClientProvider).get('/me')), isA<NetworkFailure>());
    });
  });
}
