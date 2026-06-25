/// Staff role capabilities for merchant partner staff accounts.
class MerchantStaffPermissions {
  MerchantStaffPermissions._();

  static const admin = 'admin';
  static const cook = 'cook';
  static const cashier = 'cashier';

  static const manageMenu = 'manage_menu';
  static const manageOrders = 'manage_orders';
  static const manageStaff = 'manage_staff';
  static const manageSettings = 'manage_settings';
  static const manageWallet = 'manage_wallet';
  static const viewAnalytics = 'view_analytics';
  static const managePrinter = 'manage_printer';

  static const Map<String, List<String>> rolePermissions = {
    admin: [
      manageMenu,
      manageOrders,
      manageStaff,
      manageSettings,
      manageWallet,
      viewAnalytics,
      managePrinter,
    ],
    cook: [
      manageOrders,
      manageMenu,
    ],
    cashier: [
      manageOrders,
      manageWallet,
    ],
  };

  static const Map<String, String> roleDescriptions = {
    admin:
        'Full access — menu, orders, staff, LeSpay, analytics, printer, and settings.',
    cook:
        'Kitchen — view and update orders, manage menu items and availability.',
    cashier:
        'Front desk — manage orders and LeSpay payments to riders.',
  };

  static List<String> permissionsForRole(String role) {
    return List<String>.from(rolePermissions[role] ?? const []);
  }

  static String descriptionForRole(String role) {
    return roleDescriptions[role] ?? 'Limited staff access.';
  }

  static bool roleCan(String role, String permission) {
    return permissionsForRole(role).contains(permission);
  }

  static bool userCan({
    required bool isMerchantOwner,
    String? staffRole,
    List<String>? explicitPermissions,
    required String permission,
  }) {
    if (isMerchantOwner) return true;
    if (explicitPermissions != null && explicitPermissions.contains(permission)) {
      return true;
    }
    if (staffRole != null) {
      return roleCan(staffRole, permission);
    }
    return false;
  }
}
