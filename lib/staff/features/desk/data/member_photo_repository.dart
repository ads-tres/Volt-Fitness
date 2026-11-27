import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/photos/photo_picker.dart';
import '../../../core/desk_session.dart';

/// A member's photo, taken or removed at the desk (`PUT` and `DELETE
/// /organizations/{gym}/members/{id}/photo`, the API's ADR 0036). It is kept
/// at every gym where the member's phone is registered. Every call throws a
/// [Failure] when it fails; a picture the server refuses is a
/// [ValidationFailure] on `photo`.
final class MemberPhotoRepository {
  const MemberPhotoRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  String _path(int memberId) => deskPath(_session(), '/members/$memberId/photo');

  Future<void> upload(int memberId, PickedPhoto photo) async {
    await _api.put(
      _path(memberId),
      body: FormData.fromMap({'photo': MultipartFile.fromBytes(photo.bytes, filename: photo.name)}),
    );
  }

  Future<void> remove(int memberId) => _api.delete(_path(memberId));
}

final memberPhotoRepositoryProvider = Provider<MemberPhotoRepository>(
  (ref) => MemberPhotoRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);
