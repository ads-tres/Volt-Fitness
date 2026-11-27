import 'dart:convert';

import 'package:gym_mobile/core/photos/photo_picker.dart';

/// Stands in for the camera and gallery: hands over a 1×1 picture, or
/// [bytes] when a test needs another.
final class FakePicker implements PhotoPicker {
  FakePicker({List<int>? bytes}) : bytes = bytes ?? picture;

  static final picture = base64.decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  final List<int> bytes;

  @override
  Future<PickedPhoto?> take() async => (bytes: bytes, name: 'camera.png');

  @override
  Future<PickedPhoto?> choose() async => (bytes: bytes, name: 'gallery.png');
}
