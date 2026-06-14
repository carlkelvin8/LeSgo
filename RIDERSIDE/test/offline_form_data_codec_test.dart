import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/network/offline_form_data_codec.dart';
import 'package:lezgo_rider/core/network/offline_form_file_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  test('encode and decode round-trips FormData fields and files', () async {
    final source = FormData.fromMap({
      'latitude': '14.5995',
      'photo': MultipartFile.fromBytes(
        [1, 2, 3, 4],
        filename: 'proof.jpg',
      ),
    });

    final encoded = await OfflineFormDataCodec.encode(source);
    expect(encoded[OfflineFormDataCodec.markerKey], isTrue);

    final restored = await OfflineFormDataCodec.decode(encoded);
    expect(restored.fields.map((e) => e.key), contains('latitude'));
    expect(restored.files, hasLength(1));
    expect(restored.files.first.key, 'photo');

    final keys = OfflineFormDataCodec.storageKeysFromEncoded(encoded);
    await OfflineFormFileStorage.deleteMany(keys);
  });
}
