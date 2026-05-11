import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/numbia_card.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          endDrawer: _buildDrawer(context),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.dashboardHeader,
              child: Text(
                'NUMBAA',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Parametres'),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                context.go('/aide');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state.status == DashboardStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == DashboardStatus.error) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Erreur de chargement',
        subtitle: state.error,
        actionLabel: 'Reessayer',
        onAction: () => context.read<DashboardCubit>().load(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<DashboardCubit>().load(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeaderCard(context, state),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.sm),

                _buildSectionTitle('Actions rapides'),
                const SizedBox(height: AppSpacing.md),
                _buildQuickActions(context, state),

                const SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Apercu de l\'activite'),
                const SizedBox(height: AppSpacing.md),
                _buildActivitySection(context, state),

                const SizedBox(height: AppSpacing.xl),

                if (state.alerts.isNotEmpty) ...[
                  _buildSectionTitle('Alertes'),
                  const SizedBox(height: AppSpacing.md),
                  _buildAlerts(state),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, DashboardState state) {
    final businessName = state.business?.name ?? 'votre entreprise';
    final plan = state.plan;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dashboardHeader,
            AppColors.dashboardHeaderDark,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: app name + icons
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'NUMBAA',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 24),
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.dashboardHeader, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Notifications — bientot disponible')),
                      );
                    },
                  ),
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu,
                          color: Colors.white, size: 24),
                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                    ),
                  ),
                ],
              ),
            ),

            // Greeting
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, $businessName 👋',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bienvenu sur votre tableau de bord',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),

            // Two plan cards
            if (plan != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: _PlanInfoCard(
                        icon: Icons.wifi_outlined,
                        topLabel: 'Forfait actif',
                        value: plan.dataRemainingLabel,
                        bottomLabel:
                            'Expire dans ${plan.daysUntilExpiry} jours',
                        isUrgent: plan.daysUntilExpiry <= 3,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PlanInfoCard(
                        icon: Icons.sms_outlined,
                        topLabel: 'SMS restants',
                        value: '${plan.smsRemaining}',
                        bottomLabel: 'Forfait mensuel',
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.h3);
  }

  Widget _buildQuickActions(BuildContext context, DashboardState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: [
        _QuickActionCard(
          icon: Icons.card_membership_outlined,
          label: 'Acheter un forfait',
          color: AppColors.blue,
          onTap: () => context.go('/forfait'),
        ),
        _QuickActionCard(
          icon: Icons.campaign_outlined,
          label: 'Lancer une campagne',
          color: AppColors.success,
          onTap: () => context.go('/commercialisation'),
        ),
        _QuickActionCard(
          icon: state.site != null
              ? Icons.edit_outlined
              : Icons.add_circle_outline,
          label: state.site != null ? 'Modifier le site' : 'Creer mon site',
          color: AppColors.primary,
          onTap: () {
            if (state.site != null) {
              context.push('/editor/${state.site!.id}');
            } else {
              context.push('/website-type');
            }
          },
        ),
        _QuickActionCard(
          icon: Icons.headset_mic_outlined,
          label: 'Assistance',
          color: AppColors.purple,
          onTap: () => context.go('/aide'),
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, DashboardState state) {
    return NumbiaCard(
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.visibility_outlined,
              value: '${state.weeklyVisitors}',
              label: 'Visiteurs\ncette semaine',
              iconColor: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.divider),
          Expanded(
            child: _StatItem(
              icon: Icons.sms_outlined,
              value: state.plan != null ? '${state.plan!.smsRemaining}' : '—',
              label: 'SMS\nrestants',
              iconColor: AppColors.blue,
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.divider),
          Expanded(
            child: _StatItem(
              icon: Icons.web_outlined,
              value: state.site != null ? '1' : '0',
              label: 'Mini site\nactif',
              iconColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(DashboardState state) {
    return Column(
      children: state.alerts
          .map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(alert, style: AppTypography.bodySmall),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _PlanInfoCard extends StatelessWidget {
  final IconData icon;
  final String topLabel;
  final String value;
  final String bottomLabel;
  final bool isUrgent;

  const _PlanInfoCard({
    required this.icon,
    required this.topLabel,
    required this.value,
    required this.bottomLabel,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  topLabel,
                  style:
                      AppTypography.caption.copyWith(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (isUrgent)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 11, color: AppColors.amber),
                ),
              Expanded(
                child: Text(
                  bottomLabel,
                  style: AppTypography.caption.copyWith(
                    color: isUrgent
                        ? AppColors.amber
                        : Colors.white.withValues(alpha: 0.75),
                    fontWeight:
                        isUrgent ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.caption
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h3.copyWith(color: iconColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style:
              AppTypography.caption.copyWith(color: AppColors.neutralMid),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
