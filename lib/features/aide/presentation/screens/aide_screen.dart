import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_card.dart';

class AideScreen extends StatelessWidget {
  const AideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aide'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Contact card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centre d\'aide',
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Notre equipe est disponible pour vous aider',
                  style: AppTypography.bodySmall
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Nous contacter', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),

          _ContactCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp',
            subtitle: 'Reponse en moins de 2h',
            detail: '+226 XX XX XX XX',
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactCard(
            icon: Icons.phone_outlined,
            title: 'Telephone',
            subtitle: 'Lun-Ven 8h-18h',
            detail: '+226 XX XX XX XX',
            color: AppColors.blue,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'Reponse sous 24h',
            detail: 'support@numbaa.com',
            color: AppColors.primary,
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Questions frequentes', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),

          ..._faqItems.map((faq) => _FaqTile(
                question: faq['q']!,
                answer: faq['a']!,
              )),
        ],
      ),
    );
  }
}

final _faqItems = [
  {
    'q': 'Comment creer mon mini site ?',
    'a':
        'Allez dans l\'onglet Mini site, choisissez un template et personnalisez votre contenu.',
  },
  {
    'q': 'Comment envoyer une campagne SMS ?',
    'a':
        'Achetez d\'abord un forfait, puis rendez-vous dans l\'onglet Commercialisation.',
  },
  {
    'q': 'Comment recharger mes SMS ?',
    'a':
        'Allez dans l\'onglet Forfaits et choisissez le pack qui vous convient.',
  },
  {
    'q': 'Puis-je changer de numero de telephone ?',
    'a':
        'Contactez notre support pour toute modification de votre numero principal.',
  },
];

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NumbiaCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            detail,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 0),
        backgroundColor: AppColors.surface,
        collapsedBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: const BorderSide(color: AppColors.border),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(question, style: AppTypography.body),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Text(answer,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.neutralMid)),
          ),
        ],
      ),
    );
  }
}
