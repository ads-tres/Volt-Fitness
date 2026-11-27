import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/photos/photo_picker.dart';
import '../../../core/tenant/selected_organization.dart';

export '../../../core/photos/photo_picker.dart';

/// The member's photo, kept at every gym where their phone is registered
/// (`PUT` and `DELETE /me/photo`). Its link (`photo_url` in `GET /me/gyms`)
/// works for 10 minutes, so it is read when shown and never stored. Every
/// call throws a [Failure] when it fails; a picture the server refuses is a
/// [ValidationFailure] on `photo`.
final class MyPhotoRepository {
  const MyPhotoRepository(this._api, this._gym);

  final ApiClient _api;
  final String? Function() _gym;

  /// The photo's link at the selected gym, or null without a photo.
  Future<String?> url() async {
    final response = await _api.get('/me/gyms');
    return readResponse(() {
      final gyms = (response! as Map<String, dynamic>).objects('data');
      final gym = gyms.where((gym) => gym.optional<String>('slug') == _gym()).firstOrNull ?? gyms.firstOrNull;
      return gym?.optional<Map<String, dynamic>>('member')?.optional<String>('photo_url');
    });
  }

  Future<void> upload(PickedPhoto photo) async {
    await _api.put('/me/photo', body: FormData.fromMap({'photo': MultipartFile.fromBytes(photo.bytes, filename: photo.name)}));
  }

  Future<void> remove() => _api.delete('/me/photo');
}

final myPhotoRepositoryProvider = Provider<MyPhotoRepository>(
  (ref) => MyPhotoRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);

/// The photo's link, loaded when a screen shows it; refreshed after a change.
final myPhotoUrlProvider = FutureProvider.autoDispose<String?>((ref) {
  ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
  return ref.watch(myPhotoRepositoryProvider).url();
});
