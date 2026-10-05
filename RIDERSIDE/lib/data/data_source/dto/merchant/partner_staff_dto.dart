class PartnerStaffDto {
  final int id;
  final int partnerId;
  final int userId;
  final String role;
  final List<String>? permissions;
  final bool isActive;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final String? createdAt;
  final String? updatedAt;

  PartnerStaffDto({
    required this.id,
    required this.partnerId,
    required this.userId,
    required this.role,
    this.permissions,
    required this.isActive,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCook => role == 'cook';
  bool get isCashier => role == 'cashier';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'cook':
        return 'Cook';
      case 'cashier':
        return 'Cashier';
      default:
        return role;
    }
  }

  factory PartnerStaffDto.fromJson(Map<String, dynamic> json) {
    return PartnerStaffDto(
      id: json['id'] as int? ?? 0,
      partnerId: json['partner_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      role: json['role'] as String? ?? 'cashier',
      permissions: (json['permissions'] as List?)?.cast<String>(),
      isActive: json['is_active'] as bool? ?? true,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
