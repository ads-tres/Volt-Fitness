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

/// Phone sign-in and the session on the server. Every method throws a
/// [Failure] when the call doesn't succeed.
final class AuthRepository {
  AuthRepository(this._api, this._appInfo);

  final ApiClient _api;
  final AppInfo _appInfo;

  Future<OtpChallenge> requestCode(String phone) async {
    final data = dataObject(await _api.post('/auth/otp/request', body: {'phone': phone}));
    return readResponse(
      () => OtpChallenge(
        expiresIn: Duration(seconds: data.field<int>('expires_in')),
        resendIn: Duration(seconds: data.field<int>('resend_in')),
      ),
    );
  }

  /// Also registers this phone in the member's device list.
  Future<SignInResult> verifyCode({required String phone, required String code}) async {
    final data = dataObject(
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
    return readResponse(() => SignInResult(token: data.field<String>('token'), profile: profileFromJson(data)));
  }

  Future<Profile> fetchProfile() async {
    final data = dataObject(await _api.get('/me'));
    return readResponse(() => profileFromJson(data));
  }

  /// Revokes this phone's token and QR credentials on the server.
  Future<void> signOut() => _api.post('/auth/logout');

}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(appInfoProvider)),
);
