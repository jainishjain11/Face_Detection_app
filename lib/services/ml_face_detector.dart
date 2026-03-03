import 'dart:async';
import 'dart:ui' show Rect, Size;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  static final FaceDetectorService _instance = FaceDetectorService._internal();
  factory FaceDetectorService() => _instance;
  FaceDetectorService._internal();

  late final FaceDetector _detector;
  bool _isProcessing = false;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    _isInitialized = true;
  }

  bool get isProcessing => _isProcessing;

  /// Detect faces from a CameraImage (from camera stream)
  Future<List<Face>> detectFacesFromCameraImage(
    CameraImage cameraImage,
    CameraDescription cameraDescription,
  ) async {
    if (_isProcessing) return [];
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(cameraImage, cameraDescription);
      if (inputImage == null) return [];
      final faces = await _detector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('FaceDetector error: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  /// Detect faces from an InputImage (for captured images)
  Future<List<Face>> detectFaces(InputImage image) async {
    if (_isProcessing) return [];
    _isProcessing = true;
    try {
      final faces = await _detector.processImage(image);
      return faces;
    } catch (e) {
      print('FaceDetector error: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  /// Build InputImage from CameraImage
  InputImage? _buildInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    // Determine rotation based on camera orientation
    if (camera.lensDirection == CameraLensDirection.front) {
      switch (sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation270deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation90deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }
    } else {
      switch (sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }
    }

    // Get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Handle multi-plane images (YUV)
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void dispose() {
    if (_isInitialized) {
      _detector.close();
      _isInitialized = false;
    }
  }
}

// ──────────────── Face Info Model ────────────────

class FaceInfo {
  final int trackingId;
  final Rect boundingBox;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;

  FaceInfo({
    required this.trackingId,
    required this.boundingBox,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleY,
    this.headEulerAngleZ,
  });

  factory FaceInfo.fromFace(Face face) {
    return FaceInfo(
      trackingId: face.trackingId ?? -1,
      boundingBox: face.boundingBox,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      headEulerAngleY: face.headEulerAngleY,
      headEulerAngleZ: face.headEulerAngleZ,
    );
  }

  bool get isSmiling => (smilingProbability ?? 0) > 0.7;
  bool get leftEyeOpen => (leftEyeOpenProbability ?? 1) > 0.5;
  bool get rightEyeOpen => (rightEyeOpenProbability ?? 1) > 0.5;
}
