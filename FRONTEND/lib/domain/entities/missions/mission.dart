class Mission {
  final int id;
  final int userId;
  final String missionType;
  final String title;
  final String? description;
  final int currentProgress;
  final int goalTarget;
  final bool isCompleted;
  final String? completedAt;
  final String rewardType;
  final double rewardValue;
  final bool rewardClaimed;
  final String? claimedAt;
  final String missionDate;

  Mission({
    required this.id,
    required this.userId,
    required this.missionType,
    required this.title,
    this.description,
    required this.currentProgress,
    required this.goalTarget,
    required this.isCompleted,
    this.completedAt,
    required this.rewardType,
    required this.rewardValue,
    required this.rewardClaimed,
    this.claimedAt,
    required this.missionDate,
  });

  double get progressPercentage => goalTarget > 0 ? (currentProgress / goalTarget).clamp(0.0, 1.0) : 0.0;
  
  // Legacy compatibility for old hardcoded missions
  double get progress => currentProgress.toDouble();
  double get total => goalTarget.toDouble();
}
