import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A picture taken or chosen, as taken: the server crops it to a
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

