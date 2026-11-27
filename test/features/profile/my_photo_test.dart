import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/profile/data/my_photo.dart';

import '../../support/test_doubles.dart';

void main() {
  test('reads the photo link at the selected gym, uploads a picture as photo, and removes it', () async {
    final adapter = StubAdapter(
      (request) => request.method == 'GET'
          ? jsonResponse(200, {
              'data': [
                {
                  'slug': 'kazanchis-fit-club',
                  'member': {'id': 9, 'full_name': 'Abebe Kebede', 'photo_url': 'https://cdn.test/kazanchis.jpg'},
                },
                {
                  'slug': 'bole-iron-gym',
                  'member': {'id': 7, 'full_name': 'Abebe Kebede', 'photo_url': 'https://cdn.test/bole.jpg'},
                },
              ],
            })
          : ResponseBody.fromString('', 204),
    );
    final container = await containerWithAdapter(adapter, signedInAs: memberOf([boleGym]));
    final photos = container.read(myPhotoRepositoryProvider);

    expect(await photos.url(), 'https://cdn.test/bole.jpg');
    await photos.upload((bytes: utf8.encode('picture'), name: 'IMG_0001.jpg'));
    await photos.remove();

    final upload = adapter.requests.singleWhere((request) => request.method == 'PUT');
    expect(upload.path, '/me/photo');
    final form = upload.data as FormData;
    expect(form.files.single.key, 'photo');
    expect(form.files.single.value.filename, 'IMG_0001.jpg');
    expect(adapter.requests.last.method, 'DELETE');
    expect(adapter.requests.last.path, '/me/photo');
  });
}
