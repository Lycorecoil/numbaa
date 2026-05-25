import '../entities/plan_entity.dart';

abstract class PlanRepository {
  Future<PlanEntity?> getUserPlan();
}
