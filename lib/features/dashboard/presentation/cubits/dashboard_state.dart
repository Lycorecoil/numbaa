import 'package:equatable/equatable.dart';
import '../../../../domain/entities/business_entity.dart';
import '../../../../domain/entities/plan_entity.dart';
import '../../../../domain/entities/site_entity.dart';

enum DashboardStatus { loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final BusinessEntity? business;
  final SiteEntity? site;
  final PlanEntity? plan;
  final int weeklyVisitors;
  final List<String> alerts;
  final String? error;

  const DashboardState({
    this.status = DashboardStatus.loading,
    this.business,
    this.site,
    this.plan,
    this.weeklyVisitors = 0,
    this.alerts = const [],
    this.error,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    BusinessEntity? business,
    SiteEntity? site,
    PlanEntity? plan,
    int? weeklyVisitors,
    List<String>? alerts,
    String? error,
  }) {
    return DashboardState(
      status: status ?? this.status,
      business: business ?? this.business,
      site: site ?? this.site,
      plan: plan ?? this.plan,
      weeklyVisitors: weeklyVisitors ?? this.weeklyVisitors,
      alerts: alerts ?? this.alerts,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, business, site, plan, weeklyVisitors, alerts, error];
}
