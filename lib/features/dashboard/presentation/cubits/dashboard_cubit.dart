import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/business/get_business_use_case.dart';
import '../../../../domain/usecases/plan/get_user_plan_use_case.dart';
import '../../../../domain/usecases/site/delete_site_use_case.dart';
import '../../../../domain/usecases/site/get_site_use_case.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetBusinessUseCase _getBusiness;
  final GetSiteUseCase _getSite;
  final GetUserPlanUseCase _getPlan;
  final DeleteSiteUseCase _deleteSite;
  final String userId;

  DashboardCubit({
    required GetBusinessUseCase getBusiness,
    required GetSiteUseCase getSite,
    required GetUserPlanUseCase getUserPlan,
    required DeleteSiteUseCase deleteSite,
    required this.userId,
  })  : _getBusiness = getBusiness,
        _getSite = getSite,
        _getPlan = getUserPlan,
        _deleteSite = deleteSite,
        super(const DashboardState());

  Future<void> load() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final business = await _getBusiness(userId);
      final site = business != null ? await _getSite(business.id) : null;
      final plan = await _getPlan();

      final alerts = <String>[];
      if (plan != null && plan.daysUntilExpiry <= 3) {
        alerts.add('Votre forfait expire dans ${plan.daysUntilExpiry} jours — renouvelez maintenant');
      }
      if (site == null) alerts.add('Mini site non publie');

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        business: business,
        site: site,
        plan: plan,
        alerts: alerts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteSite(String siteId) async {
    await _deleteSite(siteId);
    emit(state.copyWith(site: null, alerts: []));
  }
}
