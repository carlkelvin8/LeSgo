/// Shared rules for when a customer may cancel an active order.
bool canCustomerCancelOrderStatus(String? status) {
  if (status == null || status.isEmpty) return true;
  return !{'completed', 'cancelled', 'failed'}.contains(status.toLowerCase());
}
