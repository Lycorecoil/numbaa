import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/plan_entity.dart';
import '../../../../domain/usecases/business/get_business_use_case.dart';
import '../../../../domain/usecases/site/get_site_use_case.dart';
import 'dashboard_state.dart';

/// Loads business, site and plan data for the dashboard.
class DashboardCubit extends Cubit<DashboardState> {
  final GetBusinessUseCase _getBusiness;
  final GetSiteUseCase _getSite;
  final String userId;

  DashboardCubit({
    required GetBusinessUseCase getBusiness,
    required GetSiteUseCase getSite,
    required this.userId,
  })  : _getBusiness = getBusiness,
        _getSite = getSite,
        super(const DashboardState());

  Future<void> load() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final business = await _getBusiness(userId);
      final site = business != null ? await _getSite(business.id) : null;

      // Mock plan & activity data
      final plan = PlanEntity(
        name: 'Starter',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        smsRemaining: 120,
        totalSms: 500,
        dataRemainingMb: 1536,
        dataTotalMb: 2048,
      );

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        business: business,
        site: site,
        plan: plan,
        weeklyVisitors: 127,
        alerts: [
          'Votre forfait expire dans 3 jours — renouvelez maintenant',
          'Mini site non publie',
        ],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        error: e.toString(),
      ));
    }
  }
}
