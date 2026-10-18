import 'package:lesgo/core/theme/app_colors.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Opens an in-app camera with an explicit lens selection.
///
/// Using [CameraController] instead of the platform camera intent is important:
/// some Android camera apps ignore the requested front/rear lens and silently
/// open the last-used camera.
Future<XFile?> capturePhotoWithCamera(
  BuildContext context, {
  required CameraLensDirection lensDirection,
  required String title,
  required String helpText,
}) {
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CameraCaptureScreen(
        lensDirection: lensDirection,
        title: title,
        helpText: helpText,
      ),
    ),
  );
}

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    required this.lensDirection,
    required this.title,
    required this.helpText,
    super.key,
  });

  final CameraLensDirection lensDirection;
  final String title;
  final String helpText;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  String? _error;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() => _error = null);

    try {
      final cameras = await availableCameras();
      final matches = cameras.where(
        (camera) => camera.lensDirection == widget.lensDirection,
      );

      if (matches.isEmpty) {
        throw CameraException(
          'CameraNotFound',
          widget.lensDirection == CameraLensDirection.front
              ? 'Walang available na front camera sa device na ito.'
              : 'Walang available na rear camera sa device na ito.',
        );
      }

      _camera = matches.first;
      final controller = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } on CameraException {
        // Some front cameras do not expose flash controls. Capture still works.
      }

      if (mounted) setState(() {});
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' =>
            'Camera permission is required. Allow it in the app settings, then try again.',
          _ => error.description ?? 'Hindi ma-open ang camera.',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Hindi ma-open ang camera. Subukan ulit.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _camera != null) {
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(photo);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _error = error.description ?? 'Hindi makuha ang larawan.';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.black),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, Colors.black),
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _error != null
                  ? _CameraError(message: _error!, onRetry: _initializeCamera)
                  : controller == null || !controller.value.isInitialized
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Text(
                    widget.helpText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    button: true,
                    label: 'Take photo',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap:
                          controller?.value.isInitialized == true &&
                              !_isCapturing
                          ? _takePicture
                          : null,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface(context, Colors.white),
                          border: Border.all(color: Colors.white70, width: 5),
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            :  Icon(
                                Icons.camera_alt,
                                color: AppColors.foreground(context, Colors.black),
                                size: 34,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white, size: 52),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
