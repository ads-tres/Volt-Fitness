import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../data/check_in_repository.dart';
import '../domain/desk_check_in.dart';
import 'check_in_result.dart';
import 'code_camera.dart';
import 'desk_app_bar.dart';

/// Where the front desk scans members' QR codes. Each GQ1 code goes to the
/// API once; the answer fills the screen, then the camera is back.
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
    try {
      final checkIn = await ref.read(checkInRepositoryProvider).scan(code);
      if (!mounted) return;
      setState(() => _result = checkIn);
      _hideResult = Timer(ScanPage.resultShownFor, _done);
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _done() {
    _hideResult?.cancel();
    if (mounted) setState(() => _result = null);
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
          if (result != null) CheckInResultView(checkIn: result, onDone: _done),
        ],
      ),
    );
  }
}
