import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

@lazySingleton
class SurveyRemoteDataSource {
  final DioClient _dioClient;

  SurveyRemoteDataSource(this._dioClient);

  Future<void> submitCustomerSatisfaction({
    required int rating,
    required String? feedback,
    required int completedOrdersCount,
  }) async {
    await _dioClient.dio.post(
      ApiConstants.customerSurvey,
      data: {
        'rating': rating,
        'feedback': feedback,
        'completed_orders_count': completedOrdersCount,
        'source': 'customer_app',
      },
    );
  }
}
