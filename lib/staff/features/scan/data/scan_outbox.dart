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

/// A scan the desk decided offline, kept until the server has answered for
/// it. Its [id] is made here and sent again after a lost answer, so the
/// server records it once.
final class PendingScan {
  const PendingScan({
    required this.id,
    required this.payload,
    required this.gymSlug,
    required this.branchId,
    required this.scannedAt,
    required this.letIn,
    this.reasonCode,
  });

  final String id;
  final String payload;
  final String gymSlug;
  final int branchId;

  /// In UTC.
  final DateTime scannedAt;

  /// What the door decided, and why not.
  final bool letIn;
  final String? reasonCode;

  /// As `POST check-ins/offline` takes it.
  Map<String, Object?> toApi() => {
    'id': id,
    'payload': payload,
    'branch_id': branchId,
    'scanned_at': scannedAt.toUtc().toIso8601String(),
    'decision': letIn ? 'allow' : 'deny',
    'reason_code': ?(letIn ? null : reasonCode),
  };

  Map<String, Object?> toJson() => {...toApi(), 'gym': gymSlug};

  static PendingScan fromJson(Map<String, dynamic> json) => PendingScan(
    id: json.field<String>('id'),
    payload: json.field<String>('payload'),
    gymSlug: json.field<String>('gym'),
    branchId: json.field<int>('branch_id'),
    scannedAt: DateTime.parse(json.field<String>('scanned_at')).toUtc(),
    letIn: json.field<String>('decision') == 'allow',
    reasonCode: json.optional<String>('reason_code'),
  );
}

final class OutboxState {
  const OutboxState({this.pending = const [], this.refused = 0, this.toReview = 0, this.isSending = false});

  /// Oldest first, the order they are sent in.
  final List<PendingScan> pending;

  /// Scans the server wouldn't record: a code that doesn't match its time,
  /// one over 3 days old, or at a branch the staff member doesn't work at.
  final int refused;

  /// Scans recorded as the door decided, where the server would have
  /// decided otherwise; staff review them in the panel.
  final int toReview;
  final bool isSending;

  OutboxState copyWith({List<PendingScan>? pending, int? refused, int? toReview, bool? isSending}) => OutboxState(
    pending: pending ?? this.pending,
    refused: refused ?? this.refused,
    toReview: toReview ?? this.toReview,
    isSending: isSending ?? this.isSending,
  );
}

/// The scans decided offline, kept on the phone under `desk.outbox` until
/// the server answers for each (signing out wipes them with the rest of the
/// desk's keys). [flush] sends them to `POST check-ins/offline`, oldest
/// first, up to 200 a request, and stops at the first failure a later try
/// could get past.
final class ScanOutbox extends Notifier<OutboxState> {
  static const storageKey = '${DeskSessionController.prefix}outbox';

  /// The most the server takes in one request.
  static const batchSize = 200;

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

  /// Keeps what the door decided for [payload], scanned now at the desk's
  /// gym and branch.
  Future<PendingScan> add(String payload, {required bool letIn, String? reasonCode}) async {
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
      letIn: letIn,
      reasonCode: reasonCode,
    );
    await _save([...state.pending, scan]);
    return scan;
  }

  /// Sends what is waiting and counts the answers. Returns how many the
  /// server recorded.
  Future<int> flush() async {
    if (state.isSending || state.pending.isEmpty) return 0;
    state = state.copyWith(isSending: true);
    var recorded = 0;
    var refused = 0;
    var toReview = 0;
    try {
      while (state.pending.isNotEmpty) {
        final gym = state.pending.first.gymSlug;
        final batch = state.pending.where((scan) => scan.gymSlug == gym).take(batchSize).toList();
        final List<OfflineScanAnswer> answers;
        try {
          answers = await ref.read(checkInRepositoryProvider).sendOffline(gym, batch);
        } on Failure {
          break;
        }
        final answered = <String>{};
        for (final answer in answers) {
          answered.add(answer.id);
          switch (answer.status) {
            case 'refused':
              refused++;
            case 'recorded' || 'already_recorded':
              recorded++;
              if (answer.serverDisagrees) toReview++;
          }
        }
        if (answered.isEmpty) break;
        await _save(state.pending.where((scan) => !answered.contains(scan.id)).toList());
      }
    } finally {
      state = state.copyWith(isSending: false, refused: state.refused + refused, toReview: state.toReview + toReview);
    }
    if (recorded > 0) unawaited(ref.read(todayProvider.notifier).refresh());
    return recorded;
  }

  /// Clears the counts once the desk has seen them.
  void dismissCounts() => state = state.copyWith(refused: 0, toReview: 0);
}

final scanOutboxProvider = NotifierProvider<ScanOutbox, OutboxState>(ScanOutbox.new);
