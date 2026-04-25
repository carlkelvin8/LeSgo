// Mock WebSocket service for compilation
class WebSocketService {
  void connect() {}
  void disconnect() {}
  void send(String message) {}
  
  Future<void> initialize() async {}
  
  Future<void> subscribeToOrder(int orderId, String token) async {}
  
  void unsubscribeFromOrder(int orderId) {}
  
  Stream<Map<String, dynamic>> getOrderEventStream(int orderId) {
    return Stream.empty();
  }
}