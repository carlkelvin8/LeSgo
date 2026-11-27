import 'dart:async';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/widgets/register/registration_camera_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Minimal fake camera: a front camera whose sensor is landscape 1280x720.
class _FakeCamera extends CameraPlatform with MockPlatformInterfaceMixin {
  static const int id = 1;
  final _initialized = StreamController<CameraInitializedEvent>.broadcast();
  final _orientation =
      StreamController<DeviceOrientationChangedEvent>.broadcast();
  Completer<XFile>? photo;
  final errors = StreamController<CameraErrorEvent>.broadcast();
  int openings = 0;

  @override
  Future<XFile> takePicture(int cameraId) {
    final pending = Completer<XFile>();
    photo = pending;
    return pending.future;
  }

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
  ) async {
    openings++;
    return id;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    scheduleMicrotask(
      () => _initialized.add(
        CameraInitializedEvent(
          cameraId,
          1280,
          720,
          ExposureMode.auto,
          true,
          FocusMode.auto,
          true,
        ),
      ),
    );
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      _initialized.stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      _orientation.stream;

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) =>
      const Stream.empty();

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => errors.stream;

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}

  @override
  Widget buildPreview(int cameraId) =>
      const ColoredBox(color: Colors.grey, key: ValueKey('texture'));

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

  testWidgets('a photo returns to the same registration route', (tester) async {
    XFile? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await capturePhotoWithCamera(
                    context,
                    lensDirection: CameraLensDirection.front,
                    title: 'Live selfie',
                    helpText: 'Center your face',
                  );
                },
                child: const Text('Registration'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Registration'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();
    (CameraPlatform.instance as _FakeCamera).photo!.complete(
      XFile('selfie.jpg'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(result?.path, 'selfie.jpg');
    expect(find.text('Registration'), findsOneWidget);
  });

  testWidgets('returning to the app reopens the registration camera', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect((CameraPlatform.instance as _FakeCamera).openings, 2);
    expect(find.byKey(const ValueKey('texture')), findsOneWidget);
  });

  testWidgets('a late photo cannot close the registration page', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Home')),
      ),
    );
    navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Registration')),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push<XFile>(
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(
          lensDirection: CameraLensDirection.front,
          title: 'Live selfie',
          helpText: 'Center your face',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();

    navigator.currentState!.pop();
    (CameraPlatform.instance as _FakeCamera).photo!.complete(
      XFile('selfie.jpg'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registration'), findsOneWidget);
  });

  testWidgets(
    'the selfie preview keeps the camera\'s real proportions (no stretching)',
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
      expect(
        size.height,
        greaterThan(size.width),
        reason: 'portrait phone => portrait preview',
      );
      expect(size.width / size.height, closeTo(720 / 1280, 0.01));
    },
  );
}
