import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';
import '../cubits/template_cubit.dart';
import '../cubits/template_state.dart';

/// Screen where users choose between showcase and e-commerce website.
class WebsiteTypeScreen extends StatelessWidget {
  final String? siteId;
  const WebsiteTypeScreen({super.key, this.siteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateCubit, TemplateState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Type de site'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quel type de site souhaitez-vous ?',
                      style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choisissez le format adapte a votre activite.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Showcase option
                  NumbiaCard(
                    selected:
                        state.selectedWebsiteType == WebsiteType.showcase,
                    onTap: () => context
                        .read<TemplateCubit>()
                        .selectWebsiteType(WebsiteType.showcase),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.language,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Site Vitrine',
                                  style: AppTypography.h3),
                              const SizedBox(height: 4),
                              Text(
                                'Presentez votre activite, vos services et vos coordonnees.',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // E-commerce option
                  NumbiaCard(
                    selected:
                        state.selectedWebsiteType == WebsiteType.ecommerce,
                    onTap: () => context
                        .read<TemplateCubit>()
                        .selectWebsiteType(WebsiteType.ecommerce),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Site E-commerce',
                                  style: AppTypography.h3),
                              const SizedBox(height: 4),
                              Text(
                                'Catalogue de produits avec commande par WhatsApp, telephone ou email.',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // E-commerce clarification
                  if (state.selectedWebsiteType == WebsiteType.ecommerce) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Le site e-commerce propose un catalogue de produits. Vos clients vous contactent par WhatsApp, telephone ou email pour commander. Pas de paiement en ligne.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.neutralDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  NumbiaButton(
                    label: 'Choisir un template',
                    onPressed: state.selectedWebsiteType != null
                        ? () => context.push(
                            '/templates?type=${state.selectedWebsiteType!.name}${siteId != null ? '&siteId=$siteId' : ''}')
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
