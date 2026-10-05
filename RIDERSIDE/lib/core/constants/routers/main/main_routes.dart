class MainRoutes {
  static const String riderMain = '/rider/main';
  /// Shared registration-fee payment/approval gate for rider & merchant accounts.
  static const String registrationFeeStatus = '/registration-fee/status';
  static const String riderBookingDetail = '/rider/booking-detail';
  static const String riderHistoryDetail = '/rider/history-detail';
  static const String riderChangePassword = '/rider/change-password';
  static const String riderDeactivateAccount = '/rider/deactivate-account';
  static const String riderDeleteAccount = '/rider/delete-account';
  /// Legacy path — opens admin support chat (same as [riderCustomerServiceChat]).
  static const String riderSupportTickets = '/rider/support-tickets';
  static const String riderFaqs = '/rider/faqs';
  static const String riderOffers = '/rider/offers';
  static const String riderLoyalty = '/rider/loyalty';
  static const String riderReferral = '/rider/referral';
  static const String riderSecurity = '/rider/security';
  static const String riderNotifications = '/rider/notifications';
  static const String riderNotificationSettings = '/rider/notification-settings';
  static const String riderCustomerServiceChat = '/rider/customer-service-chat';
  static const String riderDocuments = '/rider/documents';
  static const String riderEarnings = '/rider/earnings';
  static const String riderSafety = '/rider/safety';
  static const String riderSchedule = '/rider/schedule';
  static const String riderScheduledPayout = '/rider/scheduled-payout';
  static const String riderEarningsInsights = '/rider/earnings-insights';
  static const String riderRating = '/rider/rating';
  static const String riderVehicleManagement = '/rider/vehicles';
  static const String riderQuickStats = '/rider/quick-stats';
  static const String riderPayout = '/rider/payout';
  static const String riderTripAnalytics = '/rider/trip-analytics';
  static const String riderPerformance = '/rider/performance';
  static const String riderChatList = '/rider/chat-list';
  static const String riderChat = '/rider/chat';
  static const String merchantMain = '/merchant/main';
  static const String merchantOrderDetail = '/merchant/order-detail';
  static const String merchantFaqs = '/merchant/faqs';
  static const String merchantOffers = '/merchant/offers';
  static const String merchantLoyalty = '/merchant/loyalty';
  static const String merchantReferral = '/merchant/referral';
  static const String merchantSecurity = '/merchant/security';
  /// Legacy path — opens admin support chat (same as [riderCustomerServiceChat]).
  static const String merchantSupportTickets = '/merchant/support-tickets';
  static const String merchantMissions = '/merchant/missions';
  static const String merchantDeactivateAccount = '/merchant/deactivate-account';
  static const String merchantDeleteAccount = '/merchant/delete-account';
  static const String merchantDocuments = '/merchant/documents';
  static const String merchantEarnings = '/merchant/earnings';
  static const String merchantWallet = '/merchant/wallet';
  static const String merchantPayoutHistory = '/merchant/payout-history';
  static const String merchantReviews = '/merchant/reviews';
  static const String merchantAnalytics = '/merchant/analytics';
  static const String merchantSalesReport = '/merchant/sales-report';
  static const String merchantStaff = '/merchant/staff';
  static const String merchantPrinterSettings = '/merchant/printer-settings';

  MainRoutes._();
}
