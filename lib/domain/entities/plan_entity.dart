import 'package:equatable/equatable.dart';

/// Represents the active subscription plan of the user.
class PlanEntity extends Equatable {
  final String name;
  final DateTime expiresAt;
  final int smsRemaining;
  final int totalSms;
  final int dataRemainingMb;
  final int dataTotalMb;

  const PlanEntity({
    required this.name,
    required this.expiresAt,
    required this.smsRemaining,
    required this.totalSms,
    required this.dataRemainingMb,
    required this.dataTotalMb,
  });

  String get dataRemainingLabel {
    if (dataRemainingMb >= 1024) {
      return '${(dataRemainingMb / 1024).toStringAsFixed(1)} Go';
    }
    return '$dataRemainingMb Mo';
  }

  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props =>
      [name, expiresAt, smsRemaining, totalSms, dataRemainingMb, dataTotalMb];
}
