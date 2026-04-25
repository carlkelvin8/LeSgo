import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../../data/data_source/chat_remote_datasource.dart';
import '../network/dio_client.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async {
  await getIt.init();
  
  // Register WebSocketService manually
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // Register ChatRemoteDataSource manually (not picked up by code generation)
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(getIt<DioClient>()),
  );
}

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
