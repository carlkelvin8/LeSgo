import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/auth_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/auth/register_request_dto.dart';
import 'package:lesgo/data/data_source/dto/auth/register_response_dto.dart';
import 'package:lesgo/domain/entities/auth/register/address_request.dart';
import 'package:lesgo/domain/entities/auth/register/register_request.dart';
import 'package:lesgo/presentation/provider/register/notifier/address_notifier.dart';
import 'package:lesgo/presentation/provider/register/notifier/register_state.dart';
import 'package:lesgo/presentation/provider/register/notifier/submit_notifier.dart';

class _Geocoder extends GeocodingPlatform {
  bool fail = false;
  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double lat,
    double lng,
  ) async {
    if (fail) throw Exception('Geocoder unavailable');
    return [];
  }
}

class _Registration extends StateNotifier<RegisterState>
    with AddressNotifier, SubmitNotifier {
  _Registration(super.state);
}

class _CaptureRegistration implements AuthRemoteDataSource {
  late RegisterRequestDto request;
  @override
  Future<RegisterResponseDto> register(
    RegisterRequestDto request, {
    XFile? selfie,
    XFile? validIdFront,
    XFile? validIdBack,
  }) async {
    this.request = request;
    // Stop at the API boundary, without creating an account or saving tokens.
    return const RegisterResponseDto(success: false, message: 'Captured');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'registration sends barangay, landmark, default choice and referral',
    () async {
      final api = _CaptureRegistration();
      getIt.registerSingleton<AuthRemoteDataSource>(api);
      addTearDown(() => getIt.unregister<AuthRemoteDataSource>());
      final notifier = _Registration(
        RegisterState(
          data: RegisterRequest(
            firstName: 'Maria',
            lastName: 'Santos',
            birthday: '01/01/2000',
            email: 'maria@example.test',
            password: 'Password123!',
            confirmPassword: 'Password123!',
            phoneNumber: '+639171234570',
            phoneVerificationToken: 'verified-phone-proof',
            termsAccepted: true,
            selfiePath: 'selfie.jpg',
            idType: 'passport',
            idNumber: 'P123',
            validIdFrontPath: 'front.jpg',
            validIdBackPath: 'back.jpg',
            referralCode: ' FRIEND12 ',
          ),
        ),
      );
      addTearDown(notifier.dispose);
      notifier.updateAddressFromForm(
        houseNumberStreet: '73 Purok Surngot',
        subdivBarangay: 'Buenavista',
        cityProvince: 'Claveria, Cagayan',
        zipCode: '3519',
        landmark: 'Near school',
      );
      notifier.updateAddress(isDefault: true);
      await notifier.submitRegistration();
      final json = api.request.toJson();
      expect(json['address_line_1'], '73 Purok Surngot');
      expect(json['address_line_2'], 'Buenavista, Landmark: Near school');
      expect(json['city'], 'Claveria');
      expect(json['province'], 'Cagayan');
      expect(json['is_default'], true);
      expect(json['referral_code'], 'FRIEND12');
      expect(json['phone_verification_token'], 'verified-phone-proof');
    },
  );

  test(
    'empty or failed geocoding releases loading and retains pin and address',
    () async {
      final previous = GeocodingPlatform.instance;
      final geocoder = _Geocoder();
      GeocodingPlatform.instance = geocoder;
      addTearDown(() {
        if (previous != null) GeocodingPlatform.instance = previous;
      });
      final notifier = _Registration(
        RegisterState(
          data: RegisterRequest(
            address: Address(
              streetName: 'Purok Surngot',
              barangay: 'Buenavista',
              city: 'Claveria',
              landmark: 'Near school',
            ),
          ),
        ),
      );
      addTearDown(notifier.dispose);
      for (final fail in [false, true, false]) {
        geocoder.fail = fail;
        await notifier.updateSelectedLocation(const LatLng(18.607, 121.083));
        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, fail ? isNotNull : isNull);
        expect(notifier.state.data.address!.latitude, 18.607);
        expect(notifier.state.data.address!.longitude, 121.083);
        expect(notifier.state.data.address!.barangay, 'Buenavista');
        expect(notifier.state.data.address!.landmark, 'Near school');
        expect(await notifier.saveAddress(), true);
      }
    },
  );

  test('manual address without pin cannot proceed to registration', () async {
    final notifier = _Registration(
      RegisterState(
        data: RegisterRequest(
          address: Address(
            streetName: 'Purok Surngot',
            barangay: 'Buenavista',
            city: 'Claveria',
          ),
        ),
      ),
    );
    addTearDown(notifier.dispose);
    expect(await notifier.saveAddress(), false);
    expect(notifier.state.isLoading, false);
    expect(notifier.state.error, contains('select your address on the map'));
  });
}
