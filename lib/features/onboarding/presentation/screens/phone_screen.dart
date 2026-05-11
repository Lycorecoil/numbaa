import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';

/// Country code options.
const _countryCodes = [
  _Country('+226', 'Burkina Faso', '🇧🇫'),
  _Country('+225', "Cote d'Ivoire", '🇨🇮'),
  _Country('+223', 'Mali', '🇲🇱'),
  _Country('+221', 'Senegal', '🇸🇳'),
  _Country('+229', 'Benin', '🇧🇯'),
  _Country('+228', 'Togo', '🇹🇬'),
  _Country('+233', 'Ghana', '🇬🇭'),
  _Country('+237', 'Cameroun', '🇨🇲'),
  _Country('+33', 'France', '🇫🇷'),
];

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final canProceed =
            state.phone.trim().length >= 8 && !state.isLoading;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.neutralDark),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.language.name == 'moore'
                        ? 'Koom fone numri'
                        : 'Votre numero de telephone',
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.language.name == 'moore'
                        ? 'Tond na koom code la yii ne OTP'
                        : 'Nous vous enverrons un code de verification par SMS.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.neutralMid),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Phone input with country code
                  Text('Numero de telephone', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      // Country code picker
                      GestureDetector(
                        onTap: () =>
                            _showCountryPicker(context, cubit, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _flagForCode(state.countryCode),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.countryCode,
                                style: AppTypography.body
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  size: 18, color: AppColors.neutralMid),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Phone number field
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTypography.body,
                          decoration: InputDecoration(
                            hintText: '70 00 00 00',
                            hintStyle: AppTypography.bodySmall
                                .copyWith(color: AppColors.neutralMid),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                          ),
                          onChanged: cubit.setPhone,
                        ),
                      ),
                    ],
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.error!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ],

                  const Spacer(),

                  NumbiaButton(
                    label: state.language.name == 'moore'
                        ? 'Siga'
                        : 'Envoyer le code',
                    isLoading: state.isLoading,
                    onPressed: canProceed
                        ? () async {
                            final ok = await cubit.sendOtp();
                            if (ok && context.mounted) {
                              context.push('/otp');
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _flagForCode(String code) {
    return _countryCodes
        .firstWhere(
          (c) => c.code == code,
          orElse: () => const _Country('+226', '', '🌍'),
        )
        .flag;
  }

  void _showCountryPicker(
      BuildContext context, OnboardingCubit cubit, OnboardingState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Text('Choisir le pays', style: AppTypography.h3),
          ),
          const Divider(),
          ..._countryCodes.map((country) => ListTile(
                leading: Text(country.flag,
                    style: const TextStyle(fontSize: 24)),
                title: Text(country.name, style: AppTypography.body),
                trailing: Text(
                  country.code,
                  style: AppTypography.body.copyWith(
                    color: AppColors.neutralMid,
                  ),
                ),
                selected: state.countryCode == country.code,
                selectedTileColor: AppColors.primaryLight,
                onTap: () {
                  cubit.setCountryCode(country.code);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

class _Country {
  final String code;
  final String name;
  final String flag;
  const _Country(this.code, this.name, this.flag);
}
