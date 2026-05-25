import '../../entities/plan_entity.dart';
import '../../repositories/plan_repository.dart';

class GetUserPlanUseCase {
  final PlanRepository _repo;
  GetUserPlanUseCase(this._repo);

  Future<PlanEntity?> call() => _repo.getUserPlan();
}
