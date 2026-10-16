import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/partner_dto.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_edit_profile_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_profile_provider.dart';

class Auth extends RiderAuthNotifier {
  Auth() {
    state = RiderAuthState(isLoggedIn: true, user: RiderUser(
      id: 115, name: 'Merchant', email: 'store@example.test',
      role: 'partner', partnerId: 37));
  }
}

class Profiles extends MerchantRemoteDataSource {
  UpdatePartnerRequest? saved;
  PartnerDto get profile => PartnerDto(id: 37, name: 'Store',
    supportPhone: '09990000000', supportEmail: 'store@example.test',
    logoUrl: saved == null ? null : 'https://media.example.test/new-logo.jpg');
  @override
  Future<PartnerDto> getPartnerProfile(int id) async => profile;
  @override
  Future<PartnerDto> updatePartnerProfile(int id, UpdatePartnerRequest request) async {
    saved = request;
    return profile;
  }
}

void main() {
  test('background refresh preserves selected photo and submits the same draft', () async {
    final profiles = Profiles();
    final container = ProviderContainer(overrides: [
      riderAuthProvider.overrideWith((ref) => Auth()),
      merchantDataSourceProvider.overrideWithValue(profiles),
      merchantReferralCodeProvider.overrideWith((ref) async => 'CODE'),
    ]);
    addTearDown(container.dispose);
    await container.read(merchantProfileProvider.future);
    await container.read(merchantReferralCodeProvider.future);
    final subscription = container.listen(merchantEditProfileProvider, (_, next) {});
    addTearDown(subscription.close);
    final form = container.read(merchantEditProfileProvider.notifier);
    form.updateLogoPath('/data/user/0/app/cache/selected.jpg');
    form.updateRestaurantName('Edited store');

    container.invalidate(merchantProfileProvider);
    container.invalidate(merchantReferralCodeProvider);
    await container.read(merchantProfileProvider.future);
    await container.read(merchantReferralCodeProvider.future);

    expect(container.read(merchantEditProfileProvider.notifier), same(form));
    expect(container.read(merchantEditProfileProvider).logoPath,
      '/data/user/0/app/cache/selected.jpg');
    expect(container.read(merchantEditProfileProvider).restaurantName, 'Edited store');
    expect(await form.attemptSave(), isTrue);
    expect(profiles.saved!.logoPath, '/data/user/0/app/cache/selected.jpg');
    expect(container.read(merchantEditProfileProvider).logoPath, isNull);
    expect(container.read(merchantEditProfileProvider).logoUrl,
      'https://media.example.test/new-logo.jpg');
  });
}
