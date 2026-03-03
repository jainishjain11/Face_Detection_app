import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/ml_face_detector.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/face_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0; // 0 = back, 1 = front
  bool _isInitializing = true;
  bool _flashOn = false;

  List<Face> _detectedFaces = [];
  Size _imageSize = Size.zero;

  // FPS tracking
  int _frameCount = 0;
  double _fps = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  // Session tracking
  final _sessionStart = DateTime.now();
  int _maxFacesDetected = 0;
  final _firestoreService = FirestoreService();

  final FaceDetectorService _detector = FaceDetectorService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detector.initialize();
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() => _isInitializing = true);

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _isInitializing = false);
        return;
      }

      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _cameraController = controller;

    await controller.initialize();
    if (!mounted) return;

    await controller.startImageStream(_processCameraFrame);

    setState(() => _isInitializing = false);
  }

  void _processCameraFrame(CameraImage image) async {
    _updateFps();

    final camera = _cameras[_cameraIndex];
    final faces = await _detector.detectFacesFromCameraImage(image, camera);
    if (!mounted) return;

    setState(() {
      _detectedFaces = faces;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      if (faces.length > _maxFacesDetected) {
        _maxFacesDetected = faces.length;
      }
    });
  }

  void _updateFps() {
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;
    if (elapsed >= 1000) {
      setState(() {
        _fps = _frameCount * 1000 / elapsed;
        _frameCount = 0;
        _lastFpsUpdate = now;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    final newMode = _flashOn ? FlashMode.off : FlashMode.torch;
    await _cameraController!.setFlashMode(newMode);
    setState(() => _flashOn = !_flashOn);
  }

  Future<void> _captureSnapshot() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      await _cameraController!.stopImageStream();
      final file = await _cameraController!.takePicture();
      await _cameraController!.startImageStream(_processCameraFrame);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Snapshot saved: ${file.name}'),
          backgroundColor: AppColors.darkCard,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logSession();
    _cameraController?.dispose();
    _detector.dispose();
    super.dispose();
  }

  void _logSession() {
    final duration = DateTime.now().difference(_sessionStart);
    _firestoreService.logDetectionSession(
      facesDetected: _maxFacesDetected,
      sessionDuration: duration,
      averageFps: _fps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitializing)
            _buildLoadingView()
          else if (_cameraController == null ||
              !_cameraController!.value.isInitialized)
            _buildErrorView()
          else
            CameraPreview(_cameraController!),

          // Face overlay
          if (!_isInitializing &&
              _cameraController != null &&
              _cameraController!.value.isInitialized &&
              _detectedFaces.isNotEmpty)
            Positioned.fill(
              child: FaceOverlay(
                faces: _detectedFaces,
                imageSize: _imageSize,
                screenSize: MediaQuery.of(context).size,
                isFrontCamera:
                    _cameras.isNotEmpty && _cameraIndex < _cameras.length
                        ? _cameras[_cameraIndex].lensDirection ==
                            CameraLensDirection.front
                        : false,
              ),
            ),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: AppColors.textSecondary, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Could not access camera',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back / profile button
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 22),
                ),
              ),

              const SizedBox(width: 12),

              // Title
              const Expanded(
                child: Text(
                  AppStrings.cameraScreen,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Stats chips
              _buildStatChip(
                '${_detectedFaces.length} ${AppStrings.facesDetected}',
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '${_fps.toStringAsFixed(1)} ${AppStrings.fps}',
                AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.75), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flash toggle
              _buildControlButton(
                icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                onTap: _toggleFlash,
                color: _flashOn ? AppColors.warning : Colors.white70,
              ),

              // Capture button
              GestureDetector(
                onTap: _captureSnapshot,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white12,
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Flip camera
              _buildControlButton(
                icon: Icons.flip_camera_ios_outlined,
                onTap: _toggleCamera,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
