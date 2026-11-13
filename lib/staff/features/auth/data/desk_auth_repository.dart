import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/app_info.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../core/desk_session.dart';

final class DeskSignIn {
  const DeskSignIn({required this.token, required this.name, required this.gyms});

  final String token;
  final String name;
  final List<DeskGym> gyms;
}

/// Staff sign-in with the phone and password from their SMS invite. Every
/// call throws a [Failure] when it fails.
final class DeskAuthRepository {
  const DeskAuthRepository(this._api, this._appInfo);

  final ApiClient _api;
  final AppInfo _appInfo;

  /// Exchanges the phone and password for a token, then reads the gyms the
  /// staff member works at with it. A wrong password fails on `phone`.
  Future<DeskSignIn> signIn({required String phone, required String password}) async {
    final data = dataObject(
      await _api.post('/auth/tokens', body: {'phone': phone, 'password': password, 'device_name': _appInfo.deviceName}),
    );
    final token = readResponse(() => data.field<String>('token'));
    final me = dataObject(await _api.get('/me', token: token));
    return readResponse(
      () => DeskSignIn(
        token: token,
        name: me.field<Map<String, dynamic>>('user').optional<String>('name') ?? '',
        gyms: [for (final staff in me.objects('staff')) deskGymFromJson(staff)],
      ),
    );
  }

  Future<void> signOut() => _api.delete('/auth/tokens/current');
}

final deskAuthRepositoryProvider = Provider<DeskAuthRepository>(
  (ref) => DeskAuthRepository(ref.watch(apiClientProvider), ref.watch(appInfoProvider)),
);
