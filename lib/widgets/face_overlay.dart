import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../utils/constants.dart';

class FaceOverlay extends StatelessWidget {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final bool isFrontCamera;

  const FaceOverlay({
    super.key,
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    this.isFrontCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FacePainter(
        faces: faces,
        imageSize: imageSize,
        screenSize: screenSize,
        isFrontCamera: isFrontCamera,
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final bool isFrontCamera;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = AppColors.faceBox
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.faceBoxStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = AppColors.faceBoxFill
      ..style = PaintingStyle.fill;

    final cornerPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (final face in faces) {
      final rect = _transformRect(face.boundingBox, size);

      // Semi-transparent fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        fillPaint,
      );

      // Main rectangle border
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        boxPaint,
      );

      // Corner accents
      _drawCorners(canvas, rect, cornerPaint);

      // Face ID and attributes label
      _drawFaceLabel(canvas, face, rect);
    }
  }

  /// Draw stylized corners on the bounding box
  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    const cornerLen = 16.0;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLen), paint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLen), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLen, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLen), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLen, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLen), paint);
  }

  /// Draw face attributes label above the bounding box
  void _drawFaceLabel(Canvas canvas, Face face, Rect rect) {
    final List<String> labels = [];

    if (face.trackingId != null) {
      labels.add('ID:${face.trackingId}');
    }
    if (face.smilingProbability != null && face.smilingProbability! > 0.7) {
      labels.add('😊');
    }

    if (labels.isEmpty) return;

    final labelText = labels.join(' ');
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelY = rect.top - textPainter.height - 6;
    final labelX = rect.left;

    // Background pill
    final bgRect = Rect.fromLTWH(
      labelX - 4,
      labelY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = AppColors.primary.withOpacity(0.85),
    );

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  /// Transform bounding box from image coordinates to screen coordinates
  Rect _transformRect(Rect rect, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize.height;
    final scaleY = canvasSize.height / imageSize.width;

    double left, top, right, bottom;

    if (isFrontCamera) {
      left = canvasSize.width - rect.bottom * scaleX;
      right = canvasSize.width - rect.top * scaleX;
    } else {
      left = rect.top * scaleX;
      right = rect.bottom * scaleX;
    }

    top = rect.left * scaleY;
    bottom = rect.right * scaleY;

    return Rect.fromLTRB(
      left.clamp(0, canvasSize.width),
      top.clamp(0, canvasSize.height),
      right.clamp(0, canvasSize.width),
      bottom.clamp(0, canvasSize.height),
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.screenSize != screenSize;
  }
}
