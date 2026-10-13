import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/profile.dart';
import '../../../core/auth/profile_json.dart';
import '../../../core/device/app_info.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';

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

/// Phone sign-in and the session on the server. Every method throws a
/// [Failure] when the call doesn't succeed.
final class AuthRepository {
  AuthRepository(this._api, this._appInfo);

  final ApiClient _api;
  final AppInfo _appInfo;

  Future<OtpChallenge> requestCode(String phone) async {
    final data = _data(await _api.post('/auth/otp/request', body: {'phone': phone}));
    return _read(
      () => OtpChallenge(
        expiresIn: Duration(seconds: data['expires_in'] as int),
        resendIn: Duration(seconds: data['resend_in'] as int),
      ),
    );
  }

  /// Also registers this phone in the member's device list.
  Future<SignInResult> verifyCode({required String phone, required String code}) async {
    final data = _data(
      await _api.post(
        '/auth/otp/verify',
        body: {
          'phone': phone,
          'code': code,
          'device': {
            'device_id': _appInfo.installationId,
            'device_name': _appInfo.deviceName,
            'platform': _appInfo.platform,
            'app_version': _appInfo.version,
            'app_build': int.tryParse(_appInfo.buildNumber),
          },
        },
      ),
    );
    return _read(() => SignInResult(token: data['token'] as String, profile: profileFromJson(data)));
  }

  Future<Profile> fetchProfile() async {
    final data = _data(await _api.get('/me'));
    return _read(() => profileFromJson(data));
  }

  /// Revokes this phone's token and QR credentials on the server.
  Future<void> signOut() => _api.post('/auth/logout');

  static Map<String, dynamic> _data(Object? json) => switch (json) {
    {'data': final Map<String, dynamic> data} => data,
    _ => throw const UnexpectedFailure(cause: FormatException('Response has no "data" object')),
  };

  /// A response the app can't read is the API breaking the contract, not
  /// something the member can fix; it surfaces as an unexpected failure.
  static T _read<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException catch (error) {
      throw UnexpectedFailure(cause: error);
    } on TypeError catch (error) {
      throw UnexpectedFailure(cause: error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(appInfoProvider)),
);
