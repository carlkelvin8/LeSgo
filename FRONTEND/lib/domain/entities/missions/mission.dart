class Mission {
  final String id;
  final String title;
  final double progress;
  final double total;

  Mission({
    required this.id,
    required this.title,
    required this.progress,
    required this.total,
  });

  double get progressPercentage => progress / total;
  bool get isCompleted => progress >= total;
}
