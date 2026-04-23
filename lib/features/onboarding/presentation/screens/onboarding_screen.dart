import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_text_field.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';

/// Business setup screen — last step of onboarding.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.neutralDark),
              onPressed: () => context.go('/otp'),
            ),
            title: Text(
              state.language.name == 'moore'
                  ? 'Yiibu rikibu'
                  : 'Votre entreprise',
              style: AppTypography.h3,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.language.name == 'moore'
                        ? 'Yiibu rikibu yaa zema'
                        : 'Configurez votre profil',
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.language.name == 'moore'
                        ? 'Beoogo rikibu sor n teem'
                        : 'Ces informations apparaitront sur votre mini site.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.neutralMid),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Logo picker
                  _LogoPicker(state: state, cubit: cubit),
                  const SizedBox(height: AppSpacing.xl),

                  // Business name
                  NumbiaTextField(
                    label: state.language.name == 'moore'
                        ? 'Rikibu yure'
                        : 'Nom de l\'entreprise',
                    hint: 'Ex: Boulangerie du Soleil',
                    controller: TextEditingController(
                        text: state.businessName)
                      ..selection = TextSelection.collapsed(
                          offset: state.businessName.length),
                    onChanged: cubit.setBusinessName,
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Category dropdown
                  Text(
                    state.language.name == 'moore'
                        ? 'Rikibu zugu'
                        : 'Categorie d\'activite',
                    style: AppTypography.label,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: state.businessCategory != null
                            ? AppColors.primary
                            : AppColors.border,
                        width: state.businessCategory != null ? 1.5 : 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BusinessCategory>(
                        value: state.businessCategory,
                        isExpanded: true,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text(
                            state.language.name == 'moore'
                                ? 'Rikibu zugu sor'
                                : 'Selectionnez une categorie',
                            style: AppTypography.body
                                .copyWith(color: AppColors.neutralMid),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        items: BusinessCategory.values.map((cat) {
                          return DropdownMenuItem<BusinessCategory>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  _iconForCategory(cat),
                                  size: 18,
                                  color: AppColors.neutralMid,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(cat.label, style: AppTypography.body),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (cat) {
                          if (cat != null) cubit.setBusinessCategory(cat);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // WhatsApp (optional)
                  NumbiaTextField(
                    label: state.language.name == 'moore'
                        ? 'WhatsApp (otionel)'
                        : 'Numero WhatsApp (optionnel)',
                    hint: '+226 70 00 00 00',
                    controller: TextEditingController(text: state.whatsapp)
                      ..selection = TextSelection.collapsed(
                          offset: state.whatsapp.length),
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.chat_outlined,
                    onChanged: cubit.setWhatsapp,
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  NumbiaButton(
                    label: state.language.name == 'moore'
                        ? 'Tuma'
                        : 'Terminer',
                    isLoading: state.isLoading,
                    onPressed: cubit.canCompleteSetup()
                        ? () async {
                            final ok = await cubit.completeSetup();
                            if (ok && context.mounted) {
                              context.read<AuthCubit>().markOnboardingComplete();
                              context.go('/dashboard');
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForCategory(BusinessCategory cat) {
    switch (cat) {
      case BusinessCategory.commerce:
        return Icons.storefront_outlined;
      case BusinessCategory.restaurant:
        return Icons.restaurant_outlined;
      case BusinessCategory.service:
        return Icons.miscellaneous_services_outlined;
      case BusinessCategory.technologie:
        return Icons.computer_outlined;
      case BusinessCategory.education:
        return Icons.school_outlined;
      case BusinessCategory.autre:
        return Icons.category_outlined;
    }
  }
}

class _LogoPicker extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;

  const _LogoPicker({required this.state, required this.cubit});

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null) {
      cubit.setLogoPath(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = state.logoPath != null;
    final isMoore = state.language.name == 'moore';

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: hasLogo ? Colors.transparent : AppColors.neutralLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasLogo ? AppColors.primary : AppColors.border,
                      width: hasLogo ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: hasLogo
                        ? Image.file(
                            File(state.logoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: AppColors.neutralMid,
                            ),
                          )
                        : const Icon(
                            Icons.storefront_outlined,
                            size: 40,
                            color: AppColors.neutralMid,
                          ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: hasLogo ? AppColors.primary : AppColors.neutralMid,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    hasLogo ? Icons.edit : Icons.add_a_photo,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasLogo
                  ? (isMoore ? 'Logo yii sore' : 'Changer le logo')
                  : (isMoore ? 'Logo sor' : 'Ajouter un logo'),
              style: AppTypography.caption.copyWith(
                color: hasLogo ? AppColors.primary : AppColors.neutralMid,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!hasLogo)
              Text(
                isMoore ? 'Galerie wii' : 'Depuis votre galerie',
                style:
                    AppTypography.caption.copyWith(color: AppColors.neutralMid),
              ),
          ],
        ),
      ),
    );
  }
}
