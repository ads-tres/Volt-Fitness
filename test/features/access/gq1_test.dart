import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/access/domain/access_credential.dart';
import 'package:gym_mobile/features/access/domain/gq1.dart';

/// The test vectors from the backend contract doc. If these pass here and
/// in the Laravel tests, the app and the scanner agree on every code.
void main() {
  final secret = List<int>.generate(32, (i) => i);
  const credentialId = '01K7Z3M6Q8V2N4R5T9W1X0Y2AB';

  test('codes match the contract test vectors', () {
    expect(Gq1.code(secret, credentialId, 59726400), '5365BDE868B40851');
    expect(Gq1.code(secret, credentialId, 59726401), 'E3A7DC2867D3DA18');
    expect(Gq1.code(secret, credentialId, 59728319), '2B9CBB9F484077FF', reason: 'last step of a UTC day');
    expect(Gq1.code(secret, credentialId, 59728320), '317000CADC5ED3B9', reason: 'first step of the next day');
  });

  test('the payload carries the credential, step and code', () {
    expect(
      Gq1.payload(secret, credentialId, 59726400),
      'GQ1:01K7Z3M6Q8V2N4R5T9W1X0Y2AB:59726400:5365BDE868B40851',
    );
  });

  test('a step lasts 30 seconds', () {
    expect(Gq1.stepAt(DateTime.utc(2026, 10, 12, 8)), 59726400);
    expect(Gq1.stepAt(DateTime.utc(2026, 10, 12, 8, 0, 29)), 59726400);
    expect(Gq1.stepAt(DateTime.utc(2026, 10, 12, 8, 0, 30)), 59726401);
    expect(Gq1.secondsLeft(DateTime.utc(2026, 10, 12, 8)), 30);
    expect(Gq1.secondsLeft(DateTime.utc(2026, 10, 12, 8, 0, 29)), 1);
  });

  test('a credential reads the hex secret the API sends', () {
    final credential = AccessCredential.fromHex(
      id: credentialId,
      secretHex: '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f',
    );
    expect(credential.secret, secret);
    expect(credential.payloadAt(DateTime.utc(2026, 10, 12, 8)), endsWith(':5365BDE868B40851'));
    expect(() => AccessCredential.fromHex(id: credentialId, secretHex: 'abc'), throwsFormatException);
  });
}
