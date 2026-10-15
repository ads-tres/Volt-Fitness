import 'dart:async';
import 'dart:io' show HttpDate, HttpException;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_store.dart';
import 'local_date.dart';

/// The phone's clock. Tests replace it with a fixed time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today on this phone, for "days left" and "today" labels.
final todayProvider = Provider<LocalDate>((ref) => LocalDate.of(ref.watch(clockProvider)()));

/// The API's idea of now, which the QR codes are built from: a phone whose
/// clock is a few minutes off would otherwise show codes the scanner
/// rejects. Learned from the `Date` header of every response, and kept
/// across restarts so the QR works offline.
final class ServerClock {
  ServerClock(this._preferences, this._phoneNow)
    : _offset = Duration(milliseconds: int.tryParse(_preferences.getString(_key) ?? '') ?? 0);

  static const _key = 'clock.server_offset_ms';

  final PreferencesStore _preferences;
  final DateTime Function() _phoneNow;
  Duration _offset;

  DateTime now() => _phoneNow().add(_offset);

  void observe(DateTime serverTime) {
    final offset = serverTime.difference(_phoneNow());
    // The header has whole seconds, and the response took time to arrive.
    if ((offset - _offset).abs() < const Duration(seconds: 2)) return;
    _offset = offset;
    unawaited(_preferences.setString(_key, '${offset.inMilliseconds}'));
  }
}

final serverClockProvider = Provider<ServerClock>(
  (ref) => ServerClock(ref.watch(preferencesStoreProvider), ref.watch(clockProvider)),
);

/// Feeds every response's `Date` header to the [ServerClock].
final class ServerClockInterceptor extends Interceptor {
  ServerClockInterceptor(this._clock);

  final ServerClock _clock;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _observe(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response case final response?) _observe(response.headers);
    handler.next(err);
  }

  void _observe(Headers headers) {
    final date = headers.value('date');
    if (date == null) return;
    try {
      _clock.observe(HttpDate.parse(date));
    } on HttpException {
      // A malformed header teaches nothing.
    }
  }
}
