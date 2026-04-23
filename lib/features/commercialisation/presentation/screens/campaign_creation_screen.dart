import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_text_field.dart';

enum CampaignType { sms, whatsapp }

class CampaignCreationScreen extends StatefulWidget {
  final CampaignType type;

  const CampaignCreationScreen({super.key, required this.type});

  @override
  State<CampaignCreationScreen> createState() => _CampaignCreationScreenState();
}

class _CampaignCreationScreenState extends State<CampaignCreationScreen> {
  int _step = 1;
  final _messageController = TextEditingController();
  final List<String> _selectedAudiences = [];

  static const _audiences = [
    'Tous mes contacts',
    'Clients reguliers',
    'Nouveaux clients',
    'Inactifs (30+ jours)',
    'VIP',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Color get _typeColor => widget.type == CampaignType.sms
      ? AppColors.blue
      : AppColors.success;

  String get _typeName =>
      widget.type == CampaignType.sms ? 'SMS' : 'WhatsApp';

  IconData get _typeIcon => widget.type == CampaignType.sms
      ? Icons.sms_outlined
      : Icons.chat_outlined;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Campagne $_typeName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Message', 'Public', 'Apercu'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            // Each step: circle + label stacked
            _StepItem(
              number: i + 1,
              label: labels[i],
              isActive: (i + 1) == _step,
              isDone: (i + 1) < _step,
              color: _typeColor,
            ),
            // Connector line between steps
            if (i < 2)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: (i + 1) < _step ? _typeColor : AppColors.divider,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Message ───────────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            step: '1/3',
            title: 'Redigez votre message',
            subtitle: 'Ecrivez le contenu de votre campagne $_typeName.',
            color: _typeColor,
            icon: _typeIcon,
          ),
          const SizedBox(height: AppSpacing.xl),

          NumbiaTextField(
            label: 'Nom de la campagne',
            hint: 'Ex: Promo de Noel',
            prefixIcon: Icons.drive_file_rename_outline_outlined,
            onChanged: (_) {},
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Message', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  maxLength: widget.type == CampaignType.sms ? 160 : 1000,
                  decoration: InputDecoration(
                    hintText: widget.type == CampaignType.sms
                        ? 'Bonjour [Prenom], decouvrez notre offre speciale...'
                        : 'Bonjour [Prenom],\n\nNous avons une offre speciale pour vous...',
                    hintStyle: AppTypography.body
                        .copyWith(color: AppColors.neutralMid),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    counterStyle: AppTypography.caption
                        .copyWith(color: AppColors.neutralMid),
                  ),
                  style: AppTypography.body,
                  onChanged: (_) => setState(() {}),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSpacing.radiusMd),
                      bottomRight: Radius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.neutralMid),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Utilisez [Prenom] pour personnaliser le message.',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.neutralMid),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (widget.type == CampaignType.whatsapp) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Joindre une image (optionnel) — bientot disponible',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          NumbiaButton(
            label: 'Suivant — Choisir le public',
            onPressed: _messageController.text.trim().isNotEmpty
                ? () => setState(() => _step = 2)
                : null,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Audience ──────────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            step: '2/3',
            title: 'Selectionnez votre public',
            subtitle:
                'Choisissez les groupes qui recevront cette campagne.',
            color: _typeColor,
            icon: Icons.people_outline,
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Groupes de contacts', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),

          ..._audiences.map((audience) {
            final selected = _selectedAudiences.contains(audience);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedAudiences.remove(audience);
                  } else {
                    _selectedAudiences.add(audience);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? _typeColor.withValues(alpha: 0.06)
                        : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: selected ? _typeColor : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: selected ? _typeColor : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? _typeColor
                                : AppColors.neutralMid,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          audience,
                          style: AppTypography.body.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '~${_mockCount(audience)} contacts',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.neutralMid),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (_selectedAudiences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.group_outlined, size: 16, color: _typeColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_totalContacts()} destinataires selectionnes',
                    style: AppTypography.caption.copyWith(
                      color: _typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          NumbiaButton(
            label: 'Suivant — Apercu',
            onPressed: _selectedAudiences.isNotEmpty
                ? () => setState(() => _step = 3)
                : null,
          ),
        ],
      ),
    );
  }

  int _mockCount(String audience) {
    const counts = {
      'Tous mes contacts': 348,
      'Clients reguliers': 120,
      'Nouveaux clients': 65,
      'Inactifs (30+ jours)': 89,
      'VIP': 24,
    };
    return counts[audience] ?? 50;
  }

  int _totalContacts() {
    return _selectedAudiences.fold(0, (sum, a) => sum + _mockCount(a));
  }

  // ── Step 3: Preview ───────────────────────────────────────────────────────

  Widget _buildStep3() {
    final message = _messageController.text.trim();
    final total = _totalContacts();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            step: '3/3',
            title: 'Apercu de la campagne',
            subtitle: 'Verifiez avant d\'envoyer.',
            color: _typeColor,
            icon: Icons.preview_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Message preview
          Text('Message', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: widget.type == CampaignType.whatsapp
                  ? const Color(0xFFDCF8C6)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.zero,
                topRight: const Radius.circular(AppSpacing.radiusMd),
                bottomLeft: const Radius.circular(AppSpacing.radiusMd),
                bottomRight: const Radius.circular(AppSpacing.radiusMd),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_typeIcon, size: 14, color: _typeColor),
                    const SizedBox(width: 4),
                    Text(
                      _typeName,
                      style: AppTypography.caption.copyWith(
                          color: _typeColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message.replaceAll('[Prenom]', 'Aminata'),
                  style: AppTypography.body,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Summary card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Type',
                  value: 'Campagne $_typeName',
                  icon: _typeIcon,
                  color: _typeColor,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  label: 'Destinataires',
                  value: '$total contacts',
                  icon: Icons.people_outline,
                  color: AppColors.neutralMid,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  label: 'Groupes',
                  value: _selectedAudiences.join(', '),
                  icon: Icons.group_outlined,
                  color: AppColors.neutralMid,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  label: 'Longueur',
                  value:
                      '${message.length} caracteres',
                  icon: Icons.text_fields_outlined,
                  color: AppColors.neutralMid,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Cette action utilisera $total credits $_typeName de votre forfait actif.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          NumbiaButton(
            label: 'Envoyer la campagne',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Campagne $_typeName envoyee a $total contacts !'),
                  backgroundColor: _typeColor,
                ),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          NumbiaButton(
            label: 'Modifier',
            variant: NumbiaButtonVariant.secondary,
            onPressed: () => setState(() => _step = 1),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Etape $step',
                style: AppTypography.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              Text(title, style: AppTypography.h3),
              Text(subtitle,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.neutralMid)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;
  final Color color;

  const _StepItem({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: (isActive || isDone) ? color : AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: (isActive || isDone) ? color : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$number',
                    style: AppTypography.caption.copyWith(
                      color: isActive ? Colors.white : AppColors.neutralMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isActive ? color : AppColors.neutralMid,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.neutralMid)),
              Text(value,
                  style: AppTypography.body
                      .copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
