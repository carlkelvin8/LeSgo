/// Service type constants shared across apps.
class ServiceTypes {
  ServiceTypes._();

  static const String lesRide = 'lesride';
  static const String lesEat = 'leseat';
  static const String lesBuy = 'lesbuy';
  static const String lesGo = 'lesgo';

  static const List<String> all = [lesRide, lesEat, lesBuy, lesGo];

  static String label(String type) {
    switch (type) {
      case lesRide:
        return 'LesRide';
      case lesEat:
        return 'LesEat';
      case lesBuy:
        return 'LesBuy';
      case lesGo:
        return 'LesGo';
      default:
        return type;
    }
  }
}
