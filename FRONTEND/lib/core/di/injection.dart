import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../services/order_polling_service.dart';
import '../../data/data_source/chat_remote_datasource.dart';
import '../../data/data_source/voucher_remote_datasource.dart';
import '../../data/data_source/faq_remote_datasource.dart';
import '../../data/data_source/loyalty_remote_datasource.dart';
import '../../data/data_source/referral_remote_datasource.dart';
import '../../data/data_source/survey_remote_datasource.dart';
import '../../data/data_source/device_remote_datasource.dart';
import '../../data/data_source/notification_remote_datasource.dart';
import '../../data/data_source/realtime_remote_datasource.dart';
import '../../data/data_source/order_remote_datasource.dart';
import '../../data/data_source/wallet_remote_datasource.dart';
import '../services/app_preferences_service.dart';
import '../../data/data_source/xendit_remote_datasource.dart';
import '../network/dio_client.dart';
import '../services/ssl_pinning_service.dart';
import '../services/map_recent_search_service.dart';
import '../services/customer_satisfaction_service.dart';
import '../services/chat_realtime_service.dart';
import '../services/chat_websocket_service.dart';
import '../di/local_storage_service.dart';
import '../../data/data_source/support_remote_datasource.dart';
import '../../data/data_source/document_remote_datasource.dart';
import '../services/analytics_service.dart';
import '../services/file_upload_service.dart';
import '../services/gemini_customer_service.dart';

// Repository interfaces
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/order_repository.dart';
import '../../domain/repository/partner_repository.dart';
import '../../domain/repository/tracking_repository.dart';

// Repository implementations
import '../../data/repositoryImpl/auth_repository_impl.dart';
import '../../data/repositoryImpl/order_repository_impl.dart';
import '../../data/repositoryImpl/partner_repository_impl.dart';
import '../../data/repositoryImpl/tracking_repository_impl.dart';

// Datasources needed by repositories
import '../../data/data_source/auth_remote_datasource.dart';
import '../../data/data_source/partner_remote_datasource.dart';
import '../../data/data_source/tracking_remote_datasource.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async {
  await getIt.init();

  getIt<SslPinningService>().configureSslPinning(getIt<DioClient>().dio);

  // Register WebSocketService manually
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  if (!getIt.isRegistered<OrderPollingService>()) {
    getIt.registerLazySingleton<OrderPollingService>(
      () => OrderPollingService(getIt<OrderRemoteDataSource>()),
    );
  }

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

  if (!getIt.isRegistered<FaqRemoteDataSource>()) {
    getIt.registerLazySingleton<FaqRemoteDataSource>(
      () => FaqRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<LoyaltyRemoteDataSource>()) {
    getIt.registerLazySingleton<LoyaltyRemoteDataSource>(
      () => LoyaltyRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<ReferralRemoteDataSource>()) {
    getIt.registerLazySingleton<ReferralRemoteDataSource>(
      () => ReferralRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<SurveyRemoteDataSource>()) {
    getIt.registerLazySingleton<SurveyRemoteDataSource>(
      () => SurveyRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<DeviceRemoteDataSource>()) {
    getIt.registerLazySingleton<DeviceRemoteDataSource>(
      () => DeviceRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<RealtimeRemoteDataSource>()) {
    getIt.registerLazySingleton<RealtimeRemoteDataSource>(
      () => RealtimeRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<NotificationRemoteDataSource>()) {
    getIt.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<AppPreferencesService>()) {
    getIt.registerLazySingleton<AppPreferencesService>(
      () => AppPreferencesService(getIt<SharedPreferences>()),
    );
  }

  if (!getIt.isRegistered<SupportRemoteDataSource>()) {
    getIt.registerLazySingleton<SupportRemoteDataSource>(
      () => SupportRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<DocumentRemoteDataSource>()) {
    getIt.registerLazySingleton<DocumentRemoteDataSource>(
      () => DocumentRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<ChatRealtimeService>()) {
    getIt.registerLazySingleton<ChatRealtimeService>(
      () => ChatRealtimeService(
        getIt<RealtimeRemoteDataSource>(),
        getIt<ChatWebSocketService>(),
        getIt<LocalStorageService>(),
        getIt<DioClient>(),
      ),
    );
  }

  if (!getIt.isRegistered<ChatWebSocketService>()) {
    getIt.registerLazySingleton<ChatWebSocketService>(
      () => ChatWebSocketService(
        getIt<RealtimeRemoteDataSource>(),
        getIt<LocalStorageService>(),
      ),
    );
  }

  if (!getIt.isRegistered<AnalyticsService>()) {
    getIt.registerLazySingleton<AnalyticsService>(
      () => AnalyticsService(getIt<DioClient>(), getIt<LocalStorageService>()),
    );
  }

  if (!getIt.isRegistered<FileUploadService>()) {
    getIt.registerLazySingleton<FileUploadService>(
      () => FileUploadService(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<GeminiCustomerService>()) {
    getIt.registerLazySingleton<GeminiCustomerService>(
      () => GeminiCustomerService(),
    );
  }

  if (!getIt.isRegistered<MapRecentSearchService>()) {
    getIt.registerLazySingleton<MapRecentSearchService>(
      () => MapRecentSearchService(getIt<SharedPreferences>()),
    );
  }

  // =========================================================================
  // REPOSITORY LAYER
  // Repositories provide a clean interface between providers and datasources.
  // New providers should inject these instead of datasources directly.
  // =========================================================================
  _registerRepositories();
}

void _registerRepositories() {
  // Import these at runtime — they're thin wrappers around existing datasources
  // AuthRepository
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
    );
  }

  // OrderRepository
  if (!getIt.isRegistered<OrderRepository>()) {
    getIt.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(getIt<OrderRemoteDataSource>()),
    );
  }

  // PartnerRepository
  if (!getIt.isRegistered<PartnerRepository>()) {
    getIt.registerLazySingleton<PartnerRepository>(
      () => PartnerRepositoryImpl(getIt<PartnerRemoteDataSource>()),
    );
  }

  // TrackingRepository
  if (!getIt.isRegistered<TrackingRepository>()) {
    getIt.registerLazySingleton<TrackingRepository>(
      () => TrackingRepositoryImpl(getIt<TrackingRemoteDataSource>()),
    );
  }
}

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
