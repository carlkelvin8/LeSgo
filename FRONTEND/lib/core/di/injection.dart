import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../../data/data_source/chat_remote_datasource.dart';
import '../../data/data_source/voucher_remote_datasource.dart';
import '../../data/data_source/wallet_remote_datasource.dart';
import '../../data/data_source/xendit_remote_datasource.dart';
import '../network/dio_client.dart';
import '../services/ssl_pinning_service.dart';
import '../services/customer_satisfaction_service.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async {
  await getIt.init();

  getIt<SslPinningService>().configureSslPinning(getIt<DioClient>().dio);

  // Register WebSocketService manually
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // Register ChatRemoteDataSource manually (not picked up by code generation)
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(getIt<DioClient>()),
  );

  if (!getIt.isRegistered<VoucherRemoteDataSource>()) {
    getIt.registerLazySingleton<VoucherRemoteDataSource>(
      () => VoucherRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<WalletRemoteDataSource>()) {
    getIt.registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<XenditRemoteDataSource>()) {
    getIt.registerLazySingleton<XenditRemoteDataSource>(
      () => XenditRemoteDataSource(),
    );
  }

  if (!getIt.isRegistered<CustomerSatisfactionService>()) {
    getIt.registerLazySingleton<CustomerSatisfactionService>(
      () => CustomerSatisfactionService(getIt<SharedPreferences>()),
    );
  }

}

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
