import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/selected_organization.dart';

/// A picture the member took or chose, as taken: the server crops it to a
/// square, turns it upright and drops its location (the API's ADR 0036).
typedef PickedPhoto = ({List<int> bytes, String name});

/// Takes or chooses a picture. Behind an interface so tests feed their own.
abstract interface class PhotoPicker {
  Future<PickedPhoto?> take();
  Future<PickedPhoto?> choose();
}

/// The phone's camera app and gallery, through image_picker. No camera
/// permission of the app's own: the camera app asks.
final class DevicePhotoPicker implements PhotoPicker {
  const DevicePhotoPicker();

  @override
  Future<PickedPhoto?> take() => _pick(ImageSource.camera);

  @override
  Future<PickedPhoto?> choose() => _pick(ImageSource.gallery);

  static Future<PickedPhoto?> _pick(ImageSource source) async {
    // Kept small for a slow connection; the server keeps 512 px anyway.
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
    if (file == null) return null;
    return (bytes: await file.readAsBytes(), name: file.name);
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => const DevicePhotoPicker());

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
