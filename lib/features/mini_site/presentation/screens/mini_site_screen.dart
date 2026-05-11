import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';
import '../../../dashboard/presentation/cubits/dashboard_cubit.dart';
import '../../../dashboard/presentation/cubits/dashboard_state.dart';

class MiniSiteScreen extends StatefulWidget {
  const MiniSiteScreen({super.key});

  @override
  State<MiniSiteScreen> createState() => _MiniSiteScreenState();
}

class _MiniSiteScreenState extends State<MiniSiteScreen> {
  bool _isPublished = false;

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
          appBar: AppBar(
            title: const Text('Mon mini site'),
            automaticallyImplyLeading: false,
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state.status == DashboardStatus.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Gradient header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre presence en ligne',
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Creez et gerez votre site web professionnel',
                style:
                    AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: state.site != null
              ? _buildExistingSite(context, state)
              : _buildNoSite(context),
        ),
      ],
    );
  }

  Widget _buildExistingSite(BuildContext context, DashboardState state) {
    final siteName = state.business?.name ?? 'Mon site';
    final publishedUrl = state.site?.publishedUrl;
    final displayUrl = publishedUrl ?? 'Non publie';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Site preview card
        NumbiaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock browser chrome
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Browser bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.radiusSm),
                          topRight: Radius.circular(AppSpacing.radiusSm),
                        ),
                        border: Border(
                            bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Row(children: [
                            _DotIndicator(color: const Color(0xFFFF5F57)),
                            const SizedBox(width: 4),
                            _DotIndicator(color: const Color(0xFFFFBD2E)),
                            const SizedBox(width: 4),
                            _DotIndicator(color: const Color(0xFF28C840)),
                          ]),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline,
                                      size: 10,
                                      color: AppColors.success),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      displayUrl,
                                      style: AppTypography.caption
                                          .copyWith(fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Page preview body
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              siteName,
                              style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                            Text(
                              'Votre site professionnel',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.neutralMid,
                                  fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Site name + url + toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siteName,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: publishedUrl != null
                              ? () {
                                  Clipboard.setData(
                                      ClipboardData(text: publishedUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Lien copie !'),
                                        duration: Duration(seconds: 2)),
                                  );
                                }
                              : null,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayUrl,
                                  style: AppTypography.caption.copyWith(
                                      color: publishedUrl != null
                                          ? AppColors.primary
                                          : AppColors.neutralMid),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (publishedUrl != null) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_outlined,
                                    size: 12, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: _isPublished,
                        onChanged: (v) {
                          setState(() => _isPublished = v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? 'Site publie avec succes !'
                                  : 'Site mis hors ligne'),
                              backgroundColor: v
                                  ? AppColors.success
                                  : AppColors.neutralMid,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        activeThumbColor: AppColors.success,
                      ),
                      Text(
                        _isPublished ? 'En ligne' : 'Hors ligne',
                        style: AppTypography.caption.copyWith(
                          color: _isPublished
                              ? AppColors.success
                              : AppColors.neutralMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: NumbiaButton(
                      label: 'Modifier',
                      variant: NumbiaButtonVariant.secondary,
                      icon: Icons.edit_outlined,
                      onPressed: () =>
                          context.push('/editor/${state.site!.id}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: NumbiaButton(
                      label: 'Apercu',
                      icon: Icons.visibility_outlined,
                      onPressed: () =>
                          context.push('/preview/${state.site!.id}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              NumbiaButton(
                label: 'Changer de template',
                variant: NumbiaButtonVariant.secondary,
                icon: Icons.style_outlined,
                onPressed: () =>
                    context.push('/website-type?siteId=${state.site!.id}'),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Share card
        NumbiaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.share_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Partager votre site', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Partagez votre lien sur vos reseaux pour attirer plus de clients.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.neutralMid),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _ShareButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: AppColors.success,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Partage WhatsApp — bientot')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ShareButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Partage Facebook — bientot')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ShareButton(
                    icon: Icons.link,
                    label: 'Copier',
                    color: AppColors.primary,
                    onTap: () {
                      if (publishedUrl != null) {
                        Clipboard.setData(ClipboardData(text: publishedUrl));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(publishedUrl != null
                                ? 'Lien copie dans le presse-papiers'
                                : 'Publiez votre site pour obtenir un lien'),
                            duration: const Duration(seconds: 2)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text('Fonctionnalites', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        _featuresList(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildNoSite(BuildContext context) {
    return Column(
      children: [
        NumbiaCard(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_circle_outline,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Creez votre mini site', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choisissez un template et personnalisez votre site professionnel en quelques minutes.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              NumbiaButton(
                label: 'Commencer maintenant',
                icon: Icons.rocket_launch_outlined,
                onPressed: () => context.push('/website-type'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Ce que vous obtenez', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        _featuresList(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _featuresList() {
    const features = [
      _FeatureData(
        Icons.palette_outlined,
        'Templates professionnels',
        'Choisissez parmi des modeles adaptes a votre secteur.',
        AppColors.primary,
      ),
      _FeatureData(
        Icons.shopping_bag_outlined,
        'Catalogue produits',
        'Affichez vos produits ou services avec photos et prix.',
        AppColors.success,
      ),
      _FeatureData(
        Icons.analytics_outlined,
        'Statistiques en temps reel',
        'Suivez les visites, clics et partages de votre site.',
        AppColors.purple,
      ),
      _FeatureData(
        Icons.search_outlined,
        'Optimise pour Google',
        'Votre site est indexe et visible sur les moteurs de recherche.',
        AppColors.warning,
      ),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: f.color.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(f.icon, color: f.color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.description,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.neutralMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _FeatureData(this.icon, this.title, this.description, this.color);
}

class _DotIndicator extends StatelessWidget {
  final Color color;
  const _DotIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
