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
  Future<void> _cameraOperation = Future<void>.value();
  String? _error;
  bool _isCapturing = false;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  void _initializeCamera() {
    _cameraOperation = _cameraOperation.then((_) async {
      if (!mounted ||
          !_inForeground ||
          (_controller?.value.isInitialized == true && _error == null)) {
        return;
      }
      await _releaseCamera();
      if (mounted && _inForeground) await _openCamera();
    });
  }

  Future<void> _openCamera() async {
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

      if (!mounted || !_inForeground) return;
      final controller = CameraController(
        matches.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || !_inForeground) return;
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
    if (state == AppLifecycleState.resumed) {
      _inForeground = true;
      _initializeCamera();
    } else if (_inForeground) {
      _inForeground = false;
      _cameraOperation = _cameraOperation.then((_) => _releaseCamera());
    }
  }

  Future<void> _releaseCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (mounted) setState(() {});
    try {
      await controller.dispose();
    } catch (error) {
      debugPrint('Could not release the document camera: $error');
    }
  }

  void _takePicture() {
    final controller = _controller;
    final route = ModalRoute.of(context);
    if (controller == null ||
        !_inForeground ||
        route?.isCurrent != true ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    // Finish capture before disposing the controller. A late result belongs
    // only to the camera route that started the capture.
    _cameraOperation = _cameraOperation.then((_) async {
      try {
        if (!mounted ||
            !_inForeground ||
            route?.isCurrent != true ||
            !identical(controller, _controller)) {
          return;
        }
        final photo = await controller.takePicture();
        if (mounted && _inForeground && route?.isCurrent == true) {
          Navigator.of(context).pop(photo);
        }
      } catch (error) {
        if (mounted && _inForeground && route?.isCurrent == true) {
          setState(
            () => _error = error is CameraException
                ? error.description ?? 'Hindi makuha ang larawan.'
                : 'Hindi makuha ang larawan.',
          );
        }
      } finally {
        if (mounted) setState(() => _isCapturing = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inForeground = false;
    _cameraOperation = _cameraOperation.then((_) => _releaseCamera());
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
                  // CameraPreview already sizes itself with the correct (portrait
                  // aware) aspect ratio. Wrapping it in another AspectRatio with
                  // the sensor's landscape ratio squashed the image sideways, so
                  // faces looked stretched / fisheye.
                  : Center(child: CameraPreview(controller)),
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
                            : Icon(
                                Icons.camera_alt,
                                color: AppColors.foreground(
                                  context,
                                  Colors.black,
                                ),
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
