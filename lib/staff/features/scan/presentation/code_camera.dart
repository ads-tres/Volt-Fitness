import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/l10n.dart';

/// The camera that reads QR codes. Behind this interface so tests can hand
/// the scanner codes without a camera.
abstract interface class CodeCamera {
  /// The live camera, calling [onCode] with the text of each QR code seen.
  Widget build(BuildContext context, void Function(String code) onCode);
}

/// The phone's camera, through mobile_scanner.
final class PhoneCamera implements CodeCamera {
  const PhoneCamera();

  @override
  Widget build(BuildContext context, void Function(String code) onCode) => _PhoneCameraView(onCode: onCode);
}

class _PhoneCameraView extends StatefulWidget {
  const _PhoneCameraView({required this.onCode});

  final void Function(String code) onCode;

  @override
  State<_PhoneCameraView> createState() => _PhoneCameraViewState();
}

class _PhoneCameraViewState extends State<_PhoneCameraView> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      for (final barcode in capture.barcodes) {
        if (barcode.rawValue case final code?) widget.onCode(code);
      }
    },
    errorBuilder: (context, error) => _CameraProblem(
      message: error.errorCode == MobileScannerErrorCode.permissionDenied
          ? context.l10n.deskCameraDenied
          : context.l10n.deskCameraFailed,
    ),
  );
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
}

final codeCameraProvider = Provider<CodeCamera>((ref) => const PhoneCamera());
