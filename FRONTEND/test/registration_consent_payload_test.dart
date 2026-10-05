import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lesgo/core/network/dio_client.dart';
import 'package:lesgo/data/data_source/auth_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/auth/register_request_dto.dart';

class _TestDioClient implements DioClient {
  @override
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
}

void main() {
  for (final terms in [true, false]) {
    for (final privacy in [true, false]) {
      for (final withPhotos in [true, false]) {
        test('registration preserves consent terms=$terms privacy=$privacy '
            'withPhotos=$withPhotos', () async {
          final client = _TestDioClient();
          addTearDown(() => client.dio.close(force: true));
          late RequestOptions sent;
          client.dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                sent = options;
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'success': true, 'message': 'Registered'},
                  ),
                );
              },
            ),
          );
          final photo = XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'capture.jpg',
          );
          await AuthRemoteDataSource(client).register(
            RegisterRequestDto(
              name: 'Maria Santos',
              email: 'maria@example.test',
              phone: '+639181234567',
              password: 'Password123!',
              passwordConfirmation: 'Password123!',
              termsAccepted: terms,
              privacyAccepted: privacy,
              isDefault: terms,
              idType: 'passport',
              idNumber: 'P1234567A',
              role: 'customer',
            ),
            selfie: withPhotos ? photo : null,
            validIdFront: withPhotos ? photo : null,
            validIdBack: withPhotos ? photo : null,
          );

          expect(sent.path, '/v1/auth/register');
          if (withPhotos) {
            final form = sent.data as FormData;
            final fields = Map.fromEntries(form.fields);
            expect(fields['terms_accepted'], terms ? '1' : '0');
            expect(fields['privacy_accepted'], privacy ? '1' : '0');
            expect(fields['is_default'], terms ? '1' : '0');
            expect(fields['id_type'], 'passport');
            expect(fields['id_number'], 'P1234567A');
            expect(
              form.files.map((file) => file.key),
              unorderedEquals(['selfie', 'valid_id_front', 'valid_id_back']),
            );
            expect(form.files.every((file) => file.value.length == 3), isTrue);
          } else {
            final fields = sent.data as Map<String, dynamic>;
            expect(fields['terms_accepted'], terms);
            expect(fields['privacy_accepted'], privacy);
            expect(fields['is_default'], terms);
          }
        });
      }
    }
  }
}
