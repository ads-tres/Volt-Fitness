import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/profile.dart';
import '../../../core/auth/profile_json.dart';
import '../../../core/device/app_info.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';

/// A code was sent. The member may ask for another after [resendIn].
final class OtpChallenge {
  const OtpChallenge({required this.expiresIn, required this.resendIn});

  final Duration expiresIn;
  final Duration resendIn;
}

final class SignInResult {
  const SignInResult({required this.token, required this.profile});

  final String token;
  final Profile profile;
}

/// Phone sign-in and the session on the server, as the API's members-app
/// contract has them. Every method throws a [Failure] when the call doesn't
/// succeed.
final class AuthRepository {
  AuthRepository(this._api, this._appInfo);

  /// How long a code works, and how often the API sends one to a number.
  static const codeLifetime = Duration(minutes: 10);
  static const resendAfter = Duration(minutes: 1);

  final ApiClient _api;
  final AppInfo _appInfo;

  /// The API answers every number the same, so nobody can find out who is
  /// a member; a number that isn't registered simply gets no SMS.
  Future<OtpChallenge> requestCode(String phone) async {
    await _api.post('/auth/sms-codes', body: {'phone': phone});
    return const OtpChallenge(expiresIn: codeLifetime, resendIn: resendAfter);
  }

  /// Signs in with the code, then reads the member's gyms with the new token.
  Future<SignInResult> verifyCode({required String phone, required String code}) async {
    final data = dataObject(
      await _api.post('/auth/sms-tokens', body: {'phone': phone, 'code': code, 'device_name': _appInfo.deviceName}),
    );
    final (token, user) = readResponse(
      () => (data.field<String>('token'), data.field<Map<String, dynamic>>('user')),
    );
    final gyms = await _gyms(token: token);
    return readResponse(() => SignInResult(token: token, profile: profileFromApi(user: user, gyms: gyms)));
  }

  Future<Profile> fetchProfile() async {
    final (me, gyms) = await (_api.get('/me'), _gyms()).wait;
    final user = dataObject(me);
    return readResponse(() => profileFromApi(user: user.field<Map<String, dynamic>>('user'), gyms: gyms));
  }

  /// Revokes this phone's token and its QR credentials on the server.
  Future<void> signOut() => _api.delete('/auth/tokens/current');

  Future<List<Map<String, dynamic>>> _gyms({String? token}) async {
    final response = await _api.get('/me/gyms', token: token);
    return readResponse(() => switch (response) {
      {'data': final List<dynamic> gyms} => [for (final gym in gyms) if (gym is Map<String, dynamic>) gym],
      _ => throw const FormatException('Response has no "data" list'),
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(appInfoProvider)),
);
