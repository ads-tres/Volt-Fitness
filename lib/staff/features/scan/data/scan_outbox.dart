import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/json.dart';
import '../../../../core/storage/preferences_store.dart';
import '../../../../core/time/clock.dart' show clockProvider;
import '../../../../core/utils/uuid.dart';
import '../../../core/desk_session.dart';
import '../../today/data/today_check_ins.dart';
import 'check_in_repository.dart';

/// A scan the desk couldn't send, kept until it can. It keeps its own
/// Idempotency-Key, so sending it twice never makes two check-ins, and the
/// gym, branch and time it was scanned at, so the API judges it as of then.
final class PendingScan {
  const PendingScan({
    required this.id,
    required this.payload,
    required this.gymSlug,
    required this.branchId,
    required this.scannedAt,
    required this.idempotencyKey,
  });

  final String id;
  final String payload;
  final String gymSlug;
  final int branchId;

  /// In UTC.
  final DateTime scannedAt;
  final String idempotencyKey;

  Map<String, Object?> toJson() => {
    'id': id,
    'payload': payload,
    'gym': gymSlug,
    'branch_id': branchId,
    'scanned_at': scannedAt.toUtc().toIso8601String(),
    'idempotency_key': idempotencyKey,
  };

  static PendingScan fromJson(Map<String, dynamic> json) => PendingScan(
    id: json.field<String>('id'),
    payload: json.field<String>('payload'),
    gymSlug: json.field<String>('gym'),
    branchId: json.field<int>('branch_id'),
    scannedAt: DateTime.parse(json.field<String>('scanned_at')).toUtc(),
    idempotencyKey: json.field<String>('idempotency_key'),
  );
}

final class OutboxState {
  const OutboxState({this.pending = const [], this.dropped = 0, this.isSending = false});

  /// Oldest first, the order they are sent in.
  final List<PendingScan> pending;

  /// Scans the API refused to take, such as ones over a day old. They
  /// can't be sent again, so they are let go and counted.
  final int dropped;
  final bool isSending;

  OutboxState copyWith({List<PendingScan>? pending, int? dropped, bool? isSending}) => OutboxState(
    pending: pending ?? this.pending,
    dropped: dropped ?? this.dropped,
    isSending: isSending ?? this.isSending,
  );
}

/// The scans waiting for the internet, kept on the phone under
/// `desk.outbox` (QR codes expire, so this is no secret; signing out wipes
/// it with the rest of the desk's keys). [flush] sends them oldest first and
/// stops at the first failure that a later try could get past.
final class ScanOutbox extends Notifier<OutboxState> {
  static const storageKey = '${DeskSessionController.prefix}outbox';

  @override
  OutboxState build() {
    ref.listen(deskSessionProvider, (_, session) {
      if (session is DeskSignedOut) state = const OutboxState();
    });
    return OutboxState(pending: _read());
  }

  PreferencesStore get _store => ref.read(preferencesStoreProvider);

  List<PendingScan> _read() {
    final stored = _store.getString(storageKey);
    if (stored == null) return const [];
    try {
      return [
        for (final item in jsonDecode(stored) as List<dynamic>)
          if (item is Map<String, dynamic>) PendingScan.fromJson(item),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> _save(List<PendingScan> pending) async {
    state = state.copyWith(pending: pending);
    if (pending.isEmpty) {
      await _store.remove(storageKey);
    } else {
      await _store.setString(storageKey, jsonEncode([for (final scan in pending) scan.toJson()]));
    }
  }

  /// Keeps [payload], scanned now at the desk's gym and branch.
  Future<PendingScan> add(String payload, {String? idempotencyKey}) async {
    final session = ref.read(deskSessionProvider);
    if (session is! DeskSignedIn || session.gym == null || session.branch == null) {
      throw StateError('No branch is chosen');
    }
    final scan = PendingScan(
      id: uuidV4(),
      payload: payload,
      gymSlug: session.gym!.slug,
      branchId: session.branch!.id,
      scannedAt: ref.read(clockProvider)().toUtc(),
      idempotencyKey: idempotencyKey ?? uuidV4(),
    );
    await _save([...state.pending, scan]);
    return scan;
  }

  /// Sends what is waiting, oldest first. Each answer, let in or turned
  /// away, takes its scan off the list. A network or server failure stops
  /// here, to try again later; a refusal lets that scan go. Returns how many
  /// were sent.
  Future<int> flush() async {
    if (state.isSending || state.pending.isEmpty) return 0;
    state = state.copyWith(isSending: true);
    var sent = 0;
    var dropped = 0;
    try {
      for (final scan in state.pending) {
        try {
          await ref.read(checkInRepositoryProvider).scan(
            scan.payload,
            idempotencyKey: scan.idempotencyKey,
            scannedAt: scan.scannedAt,
            gymSlug: scan.gymSlug,
            branchId: scan.branchId,
          );
          sent++;
        } on ValidationFailure {
          dropped++;
        } on NotFoundFailure {
          dropped++;
        } on ForbiddenFailure {
          dropped++;
        } on Failure {
          break;
        }
        await _save(state.pending.where((waiting) => waiting.id != scan.id).toList());
      }
    } finally {
      state = state.copyWith(isSending: false, dropped: state.dropped + dropped);
    }
    if (sent > 0) unawaited(ref.read(todayProvider.notifier).refresh());
    return sent;
  }

  /// Clears the count of scans let go, once the desk has seen it.
  void dismissDropped() => state = state.copyWith(dropped: 0);
}

final scanOutboxProvider = NotifierProvider<ScanOutbox, OutboxState>(ScanOutbox.new);
