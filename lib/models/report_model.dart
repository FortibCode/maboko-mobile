class ReportModel {
  final String targetId; // ID du post ou de l'utilisateur
  final String targetType; // 'post' ou 'user'
  final String reason;
  final String reporterId;

  ReportModel({
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.reporterId,
  });
}
