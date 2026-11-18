/// AI replies must be handled by a trusted backend so provider credentials are
/// never embedded in a rider or merchant app. Until that endpoint exists, the
/// chat sends messages directly to the support-ticket flow.
class GeminiCustomerService {
  bool get isConfigured => false;

  void startConversation() {}

  Future<String> sendMessage(String _) async =>
      throw GeminiNotConfiguredException();
}

class GeminiNotConfiguredException implements Exception {
  @override
  String toString() =>
      'Our assistant is unavailable right now. Please contact LeSgo support.';
}

class GeminiServiceException implements Exception {
  final String message;

  const GeminiServiceException(this.message);

  @override
  String toString() => message;
}
