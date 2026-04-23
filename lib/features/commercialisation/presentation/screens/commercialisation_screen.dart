import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_card.dart';
import 'campaign_creation_screen.dart';

class CommercialisationScreen extends StatelessWidget {
  const CommercialisationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campagnes'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), AppColors.success],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lancez vos campagnes',
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Touchez vos clients par SMS et WhatsApp',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Nouvelle campagne', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),

          _CampaignTypeCard(
            icon: Icons.sms_outlined,
            title: 'Campagne SMS',
            description:
                'Envoyez des promotions, rappels et actualites par SMS a votre base client.',
            color: AppColors.blue,
            stats: '120 SMS restants',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CampaignCreationScreen(
                    type: CampaignType.sms),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _CampaignTypeCard(
            icon: Icons.chat_outlined,
            title: 'Campagne WhatsApp',
            description:
                'Communiquez avec vos clients via WhatsApp avec images et liens.',
            color: AppColors.success,
            stats: 'Inclus dans votre forfait',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CampaignCreationScreen(
                    type: CampaignType.whatsapp),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Historique des campagnes', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),

          NumbiaCard(
            child: Column(
              children: [
                const Icon(Icons.campaign_outlined,
                    size: 48, color: AppColors.neutralMid),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucune campagne encore',
                  style: AppTypography.body
                      .copyWith(color: AppColors.neutralMid),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Vos campagnes envoyees apparaitront ici.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.neutralMid),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String stats;
  final VoidCallback onTap;

  const _CampaignTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.stats,
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
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stats,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.neutralMid),
            ],
          ),
        ),
      ),
    );
  }
}
