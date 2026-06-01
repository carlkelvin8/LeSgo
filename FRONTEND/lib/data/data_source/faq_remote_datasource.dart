import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/faq/faq_articles_response_dto.dart';

@lazySingleton
class FaqRemoteDataSource {
  final DioClient _dioClient;

  FaqRemoteDataSource(this._dioClient);

  Future<FaqArticlesResponseDto> getArticles() async {
    final response = await _dioClient.dio.get(ApiConstants.faqArticles);
    return FaqArticlesResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
