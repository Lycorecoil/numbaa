import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';

class ForfaitScreen extends StatefulWidget {
  const ForfaitScreen({super.key});

  @override
  State<ForfaitScreen> createState() => _ForfaitScreenState();
}

class _ForfaitScreenState extends State<ForfaitScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedSubNav = 0;

  static const _tabs = ['Tous', 'Journalier', 'Hebdo.', 'Mensuel'];
  static const _subNavItems = ['Donnees', 'Appel', 'SMS', 'Combo'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forfaits'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.neutralMid,
          indicatorColor: AppColors.primary,
          labelStyle: AppTypography.caption
              .copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.caption,
        ),
      ),
      body: Column(
        children: [
          // Blue banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dashboardHeader,
                  AppColors.dashboardHeaderDark
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisissez votre forfait',
                  style: AppTypography.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Envoyez des SMS et WhatsApp a vos clients',
                  style:
                      AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Sub-navigation chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: List.generate(_subNavItems.length, (i) {
                final selected = _selectedSubNav == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSubNav = i),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: i < _subNavItems.length - 1 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _subNavItems[i],
                        style: AppTypography.caption.copyWith(
                          color: selected ? Colors.white : AppColors.neutralMid,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(height: 1, color: AppColors.divider),

          // Plan list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _buildPlanList(tab, _subNavItems[_selectedSubNav]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(String period, String type) {
    final plans = _getPlans(period, type);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ...plans.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PlanCard(
                name: p['name'] as String,
                price: p['price'] as String,
                detail: p['detail'] as String,
                duration: p['duration'] as String,
                color: p['color'] as Color,
                isPopular: p['popular'] as bool? ?? false,
                features: List<String>.from(p['features'] as List),
              ),
            )),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Paiement disponible bientot (Mobile Money, Visa)',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getPlans(String period, String type) {
    if (period == 'Journalier') {
      return [
        {
          'name': 'Mini Jour',
          'price': '100 FCFA',
          'detail': _detailForType(type, 'journalier'),
          'duration': '1 jour',
          'color': AppColors.blue,
          'features': _featuresForType(type, 'mini'),
        },
        {
          'name': 'Flash Jour',
          'price': '250 FCFA',
          'detail': _detailForType(type, 'journalier_plus'),
          'duration': '1 jour',
          'color': AppColors.primary,
          'popular': true,
          'features': _featuresForType(type, 'flash'),
        },
      ];
    }
    if (period == 'Hebdo.') {
      return [
        {
          'name': 'Starter Hebdo',
          'price': '500 FCFA',
          'detail': _detailForType(type, 'hebdo'),
          'duration': '7 jours',
          'color': AppColors.blue,
          'features': _featuresForType(type, 'starter_hebdo'),
        },
        {
          'name': 'Pro Hebdo',
          'price': '1 500 FCFA',
          'detail': _detailForType(type, 'hebdo_plus'),
          'duration': '7 jours',
          'color': AppColors.primary,
          'popular': true,
          'features': _featuresForType(type, 'pro_hebdo'),
        },
      ];
    }
    if (period == 'Mensuel') {
      return [
        {
          'name': 'Starter',
          'price': '2 500 FCFA',
          'detail': _detailForType(type, 'mensuel'),
          'duration': '30 jours',
          'color': AppColors.blue,
          'features': _featuresForType(type, 'starter'),
        },
        {
          'name': 'Pro',
          'price': '7 500 FCFA',
          'detail': _detailForType(type, 'mensuel_plus'),
          'duration': '30 jours',
          'color': AppColors.primary,
          'popular': true,
          'features': _featuresForType(type, 'pro'),
        },
        {
          'name': 'Premium',
          'price': '15 000 FCFA',
          'detail': _detailForType(type, 'mensuel_max'),
          'duration': '30 jours',
          'color': AppColors.purple,
          'features': _featuresForType(type, 'premium'),
        },
      ];
    }
    // Tous — show best sellers across periods
    return [
      {
        'name': 'Flash Jour',
        'price': '250 FCFA',
        'detail': _detailForType(type, 'journalier_plus'),
        'duration': '1 jour',
        'color': AppColors.blue,
        'features': _featuresForType(type, 'flash'),
      },
      {
        'name': 'Pro Hebdo',
        'price': '1 500 FCFA',
        'detail': _detailForType(type, 'hebdo_plus'),
        'duration': '7 jours',
        'color': AppColors.primary,
        'popular': true,
        'features': _featuresForType(type, 'pro_hebdo'),
      },
      {
        'name': 'Pro Mensuel',
        'price': '7 500 FCFA',
        'detail': _detailForType(type, 'mensuel_plus'),
        'duration': '30 jours',
        'color': AppColors.success,
        'features': _featuresForType(type, 'pro'),
      },
      {
        'name': 'Premium',
        'price': '15 000 FCFA',
        'detail': _detailForType(type, 'mensuel_max'),
        'duration': '30 jours',
        'color': AppColors.purple,
        'features': _featuresForType(type, 'premium'),
      },
    ];
  }

  String _detailForType(String type, String tier) {
    switch (type) {
      case 'Appel':
        return tier.contains('max') || tier.contains('premium')
            ? '300 min'
            : tier.contains('plus') || tier.contains('pro')
                ? '100 min'
                : '30 min';
      case 'SMS':
        return tier.contains('max') || tier.contains('premium')
            ? '1 500 SMS'
            : tier.contains('plus') || tier.contains('pro')
                ? '500 SMS'
                : '100 SMS';
      case 'Combo':
        return 'Donnees + Appel + SMS';
      default: // Donnees
        return tier.contains('max') || tier.contains('premium')
            ? '5 Go'
            : tier.contains('plus') || tier.contains('pro')
                ? '1.5 Go'
                : '500 Mo';
    }
  }

  List<String> _featuresForType(String type, String tier) {
    switch (type) {
      case 'Appel':
        return [
          _detailForType(type, tier),
          'Appels locaux inclus',
          if (tier.contains('pro') || tier.contains('premium'))
            'Appels internationaux',
          'Valide sur tout le reseau',
        ];
      case 'SMS':
        return [
          _detailForType(type, tier),
          'SMS nationaux',
          if (tier.contains('pro') || tier.contains('premium'))
            'SMS internationaux',
          'Envoi groupé inclus',
        ];
      case 'Combo':
        return [
          'Donnees: ${_detailForType('Donnees', tier)}',
          'Appels: ${_detailForType('Appel', tier)}',
          'SMS: ${_detailForType('SMS', tier)}',
          'Tout en un',
        ];
      default: // Donnees
        return [
          _detailForType(type, tier),
          'Internet 4G/LTE',
          if (tier.contains('pro') || tier.contains('premium'))
            'Partage de connexion',
          'Utilisation nationale',
        ];
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String detail;
  final String duration;
  final Color color;
  final bool isPopular;
  final List<String> features;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.detail,
    required this.duration,
    required this.color,
    this.isPopular = false,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return NumbiaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isPopular) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Populaire',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                detail,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: AppTypography.h2.copyWith(color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ $duration',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.neutralMid),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(f, style: AppTypography.bodySmall),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.md),
          NumbiaButton(
            label: 'Choisir $name',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Paiement bientot disponible')),
              );
            },
          ),
        ],
      ),
    );
  }
}
