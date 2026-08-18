enum LesrideVehicleOption {
  tricycle(code: 'tricycle', label: 'Tricycle', isAvailable: true),
  sedan(code: 'sedan', label: 'Sedan', isAvailable: false),
  sevenSeater(code: 'seven_seater', label: '7 Seater', isAvailable: false);

  const LesrideVehicleOption({
    required this.code,
    required this.label,
    required this.isAvailable,
  });

  final String code;
  final String label;
  final bool isAvailable;
}
