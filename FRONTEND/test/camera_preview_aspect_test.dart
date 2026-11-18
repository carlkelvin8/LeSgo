import 'dart:async';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/widgets/common/camera_capture_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Minimal fake camera: a front camera whose sensor is landscape 1280x720.
class _FakeCamera extends CameraPlatform with MockPlatformInterfaceMixin {
  static const int id = 1;
  final _initialized = StreamController<CameraInitializedEvent>.broadcast();
  final _orientation = StreamController<DeviceOrientationChangedEvent>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async => [
    const CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    ),
  ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async => id;

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    scheduleMicrotask(
      () => _initialized.add(
        CameraInitializedEvent(
          cameraId, 1280, 720, ExposureMode.auto, true, FocusMode.auto, true,
        ),
      ),
    );
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) => _initialized.stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() => _orientation.stream;

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) => const Stream.empty();

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => const Stream.empty();

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}

  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.grey, key: ValueKey('texture'));

  @override
  Future<void> dispose(int cameraId) async {}
}

void main() {
  late CameraPlatform original;

  setUp(() {
    original = CameraPlatform.instance;
    CameraPlatform.instance = _FakeCamera();
  });

  tearDown(() => CameraPlatform.instance = original);

  testWidgets('the selfie preview keeps the camera\'s real proportions (no stretching)',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CameraCaptureScreen(
          lensDirection: CameraLensDirection.front,
          title: 'Live selfie',
          helpText: 'Center your face',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byKey(const ValueKey('texture')));

    // A 1280x720 landscape sensor shown on a portrait phone is 9:16, i.e. taller
    // than wide. The old double AspectRatio forced it into a wide 16:9 box.
    expect(size.height, greaterThan(size.width), reason: 'portrait phone => portrait preview');
    expect(size.width / size.height, closeTo(720 / 1280, 0.01));
  });
}
