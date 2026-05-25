import '../../core/network/api_client.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/repositories/plan_repository.dart';

class HttpPlanRepository implements PlanRepository {
  final ApiClient _api;
  HttpPlanRepository(this._api);

  @override
  Future<PlanEntity?> getUserPlan() async {
    try {
      final res = await _api.get('/plans/me');
      final m = res['plan'] as Map<String, dynamic>;
      return PlanEntity(
        name: m['name'] as String,
        expiresAt: DateTime.parse(m['expiresAt'] as String),
        smsRemaining: m['smsRemaining'] as int,
        totalSms: m['totalSms'] as int,
        dataRemainingMb: m['dataRemainingMb'] as int,
        dataTotalMb: m['dataTotalMb'] as int,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
