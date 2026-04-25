// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:lesgo/core/di/injection.dart' as _i1012;
import 'package:lesgo/core/di/local_storage_service.dart' as _i584;
import 'package:lesgo/core/network/dio_client.dart' as _i214;
import 'package:lesgo/core/services/connectivity_service.dart' as _i987;
import 'package:lesgo/core/services/error_logging_service.dart' as _i42;
import 'package:lesgo/core/services/favorites_service.dart' as _i808;
import 'package:lesgo/core/services/fcm_service.dart' as _i407;
import 'package:lesgo/core/services/notification_service.dart' as _i1010;
import 'package:lesgo/core/services/permission_service.dart' as _i680;
import 'package:lesgo/core/services/rate_limiter_service.dart' as _i758;
import 'package:lesgo/core/services/secure_storage_service.dart' as _i155;
import 'package:lesgo/core/services/session_timeout_service.dart' as _i946;
import 'package:lesgo/core/services/ssl_pinning_service.dart' as _i373;
import 'package:lesgo/data/data_source/address_remote_datasource.dart' as _i940;
import 'package:lesgo/data/data_source/auth_remote_datasource.dart' as _i677;
import 'package:lesgo/data/data_source/distance_remote_datasource.dart' as _i20;
import 'package:lesgo/data/data_source/geofence_remote_datasource.dart' as _i74;
import 'package:lesgo/data/data_source/order_remote_datasource.dart' as _i189;
import 'package:lesgo/data/data_source/partner_remote_datasource.dart'
    as _i1024;
import 'package:lesgo/data/data_source/payment_gateway_remote_datasource.dart'
    as _i802;
import 'package:lesgo/data/data_source/payment_remote_datasource.dart' as _i208;
import 'package:lesgo/data/data_source/review_remote_datasource.dart' as _i472;
import 'package:lesgo/data/data_source/security_remote_datasource.dart'
    as _i542;
import 'package:lesgo/data/data_source/service_remote_datasource.dart' as _i738;
import 'package:lesgo/data/data_source/social_remote_datasource.dart' as _i162;
import 'package:lesgo/data/data_source/tracking_remote_datasource.dart'
    as _i657;
import 'package:lesgo/data/data_source/user_remote_datasource.dart' as _i761;
import 'package:lesgo/data/repositoryImpl/user_repository_impl.dart' as _i937;
import 'package:lesgo/domain/repository/user_repository.dart' as _i962;
import 'package:lesgo/domain/use_cases/login_usecase.dart' as _i720;
import 'package:lesgo/domain/use_cases/logout_usecase.dart' as _i496;
import 'package:lesgo/presentation/provider/auth/auth_provider.dart' as _i270;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i987.ConnectivityService>(
      () => _i987.ConnectivityService(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i42.ErrorLoggingService>(
      () => _i42.ErrorLoggingService(),
    );
    gh.lazySingleton<_i407.FcmService>(() => _i407.FcmService());
    gh.lazySingleton<_i680.PermissionService>(() => _i680.PermissionService());
    gh.lazySingleton<_i758.RateLimiterService>(
      () => _i758.RateLimiterService(),
    );
    gh.lazySingleton<_i373.SslPinningService>(() => _i373.SslPinningService());
    gh.lazySingleton<_i584.LocalStorageService>(
      () => _i584.LocalStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i808.FavoritesService>(
      () => _i808.FavoritesService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i155.SecureStorageService>(
      () => _i155.SecureStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i214.DioClient>(
      () => _i214.DioClient(gh<_i584.LocalStorageService>()),
    );
    gh.lazySingleton<_i946.SessionTimeoutService>(
      () => _i946.SessionTimeoutService(gh<_i155.SecureStorageService>()),
    );
    gh.lazySingleton<_i1010.NotificationService>(
      () => _i1010.NotificationService(gh<_i407.FcmService>()),
    );
    gh.lazySingleton<_i940.AddressRemoteDataSource>(
      () => _i940.AddressRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i20.DistanceRemoteDataSource>(
      () => _i20.DistanceRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i74.GeofenceRemoteDataSource>(
      () => _i74.GeofenceRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i189.OrderRemoteDataSource>(
      () => _i189.OrderRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i1024.PartnerRemoteDataSource>(
      () => _i1024.PartnerRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i802.PaymentGatewayRemoteDataSource>(
      () => _i802.PaymentGatewayRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i208.PaymentRemoteDataSource>(
      () => _i208.PaymentRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i472.ReviewRemoteDataSource>(
      () => _i472.ReviewRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i542.SecurityRemoteDataSource>(
      () => _i542.SecurityRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i738.ServiceRemoteDataSource>(
      () => _i738.ServiceRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i162.SocialRemoteDataSource>(
      () => _i162.SocialRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i657.TrackingRemoteDataSource>(
      () => _i657.TrackingRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i761.UserRemoteDataSource>(
      () => _i761.UserRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.factory<_i677.AuthRemoteDataSource>(
      () => _i677.AuthRemoteDataSource(gh<_i214.DioClient>()),
    );
    gh.lazySingleton<_i962.UserRepository>(
      () => _i937.UserRepositoryImpl(
        gh<_i761.UserRemoteDataSource>(),
        gh<_i584.LocalStorageService>(),
      ),
    );
    gh.lazySingleton<_i720.LoginUseCase>(
      () => _i720.LoginUseCase(gh<_i962.UserRepository>()),
    );
    gh.lazySingleton<_i496.LogoutUseCase>(
      () => _i496.LogoutUseCase(gh<_i962.UserRepository>()),
    );
    gh.factory<_i270.AuthNotifier>(
      () => _i270.AuthNotifier(
        gh<_i720.LoginUseCase>(),
        gh<_i496.LogoutUseCase>(),
        gh<_i584.LocalStorageService>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i1012.RegisterModule {}
