import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

/// [data] as a QR code, dark on white with the standard quiet zone, so any
/// scanner reads it.
class QrCodeView extends StatefulWidget {
  const QrCodeView({super.key, required this.data, required this.size, required this.semanticLabel});

  final String data;
  final double size;
  final String semanticLabel;

  @override
  State<QrCodeView> createState() => _QrCodeViewState();
}

class _QrCodeViewState extends State<QrCodeView> {
  late QrImage _image = _encode(widget.data);

  @override
  void didUpdateWidget(QrCodeView old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _image = _encode(widget.data);
  }

  static QrImage _encode(String data) =>
      QrImage(QrCode(payload: QrPayload.fromString(data), errorCorrectLevel: QrErrorCorrectLevel.medium));

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    image: true,
    child: SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _QrPainter(_image)),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  /// Modules of white around the code that scanners expect.
  static const _quietZone = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final modules = image.moduleCount;
    final cell = size.width / (modules + 2 * _quietZone);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final dark = Path();
    for (var row = 0; row < modules; row++) {
      for (var col = 0; col < modules; col++) {
        if (image.isDark(row, col)) {
          // A hair of overlap avoids seams between neighbouring modules.
          dark.addRect(Rect.fromLTWH((col + _quietZone) * cell, (row + _quietZone) * cell, cell + 0.3, cell + 0.3));
        }
      }
    }
    canvas.drawPath(dark, Paint()..color = const Color(0xFF111111));
  }

  @override
  bool shouldRepaint(_QrPainter old) => !identical(old.image, image);
}
