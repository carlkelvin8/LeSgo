class BookingService {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final ServiceType type;

  BookingService({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.type,
  });

  BookingService copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    ServiceType? type,
  }) {
    return BookingService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      type: type ?? this.type,
    );
  }
}

enum ServiceType {
  leseat,
  lesbuy,
  lesgo,
  lesport,
  lesride,
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.leseat:
        return 'LeSeat';
      case ServiceType.lesbuy:
        return 'LesBuy';
      case ServiceType.lesgo:
        return 'LesGo';
      case ServiceType.lesport:
        return 'LesTransport';
      case ServiceType.lesride:
        return 'LesRide';
    }
  }

  String get iconPath {
    switch (this) {
      case ServiceType.leseat:
        return 'assets/images/book/Leseat.svg';
      case ServiceType.lesbuy:
        return 'assets/images/book/Lesbuy.svg';
      case ServiceType.lesgo:
        return 'assets/images/book/Lesgo.svg';
      case ServiceType.lesport:
        return 'assets/images/book/Lesport.svg';
      case ServiceType.lesride:
        return 'assets/images/book/Lesride.svg';
    }
  }
}
