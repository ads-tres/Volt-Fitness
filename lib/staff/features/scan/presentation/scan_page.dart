import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/time/clock.dart' show clockProvider;
import '../../../../core/utils/uuid.dart';
import '../../offline/data/door_list_controller.dart';
import '../../payments/presentation/take_payment_sheet.dart';
import '../data/check_in_repository.dart';
import '../data/scan_outbox.dart';
import '../domain/desk_check_in.dart';
import 'check_in_result.dart';
import 'code_camera.dart';
import 'desk_app_bar.dart';

/// Where the front desk scans members' QR codes. Each GQ1 code goes to the
/// API once; the answer fills the screen, then the camera is back. Without
/// internet the desk decides from its door list, as the server would, and
/// keeps the scan to send later.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  /// How long the answer stays up before scanning again.
  static const resultShownFor = Duration(seconds: 5);

  /// A code still in front of the camera isn't sent again within this time.
  static const sameCodeIgnoredFor = Duration(seconds: 15);

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  var _sending = false;
  DeskCheckIn? _result;
  Timer? _hideResult;
  String? _lastCode;
  DateTime? _lastCodeAt;

  @override
  void dispose() {
    _hideResult?.cancel();
    super.dispose();
  }

  Future<void> _onCode(String code) async {
    if (!code.startsWith('GQ1:') || _sending || _result != null) return;
    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastCodeAt!) < ScanPage.sameCodeIgnoredFor) return;
    _lastCode = code;
    _lastCodeAt = now;
    setState(() => _sending = true);
    final idempotencyKey = uuidV4();
    try {
      final checkIn = await ref.read(checkInRepositoryProvider).scan(code, idempotencyKey: idempotencyKey);
      unawaited(ref.read(scanOutboxProvider.notifier).flush());
      if (!mounted) return;
      setState(() => _result = checkIn);
      _hideResult = Timer(ScanPage.resultShownFor, _done);
    } on NetworkFailure {
      final now = ref.read(clockProvider)().toUtc();
      final decision = await ref.read(doorListProvider.notifier).decide(code);
      if (decision != null) {
        await ref
            .read(scanOutboxProvider.notifier)
            .add(code, letIn: decision.letIn, reasonCode: decision.reasonCode);
      }
      if (!mounted) return;
      setState(
        () => _result = decision == null
            ? DeskCheckIn(id: 0, letIn: false, reasonCode: noDoorList, checkedInAt: now, offline: true)
            : DeskCheckIn(
                id: 0,
                letIn: decision.letIn,
                reasonCode: decision.reasonCode,
                checkedInAt: now,
                memberName: decision.credential?.memberName,
                memberPhotoUrl: decision.credential?.photoUrl,
                planName: decision.day?.planName,
                offline: true,
              ),
      );
      _hideResult = Timer(ScanPage.resultShownFor, _done);
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Closes the result and takes what the member owes.
  void _takePayment(DeskCheckIn checkIn) {
    _done();
    unawaited(
      showTakePaymentSheet(
        context,
        (id: checkIn.memberId!, name: checkIn.memberName ?? '', phone: checkIn.memberPhone ?? ''),
        onPaid: () {},
      ),
    );
  }

  void _done() {
    _hideResult?.cancel();
    if (mounted) {
      setState(() => _result = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    return Scaffold(
      appBar: const DeskAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ref.watch(codeCameraProvider).build(context, _onCode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(l10n.deskPointCamera, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          if (_sending) const ColoredBox(color: Colors.black26, child: Center(child: CircularProgressIndicator())),
          if (result != null) CheckInResultView(checkIn: result, onDone: _done, onTakePayment: () => _takePayment(result)),
        ],
      ),
    );
  }
}
