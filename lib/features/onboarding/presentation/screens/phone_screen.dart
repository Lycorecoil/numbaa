import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';

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
        final canProceed = state.phone.trim().length >= 8 && !state.isLoading;

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              // Header orange
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.26,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.storefront, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 10),
                            Text('Creer votre compte',
                              style: AppTypography.h3.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Etape 1 sur 3',
                              style: AppTypography.caption.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Formulaire
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Votre numero de telephone', style: AppTypography.h2),
                        const SizedBox(height: 6),
                        Text(
                          'Nous vous enverrons un code de verification par WhatsApp.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                        ),
                        const SizedBox(height: 28),

                        Text('Numero de telephone', style: AppTypography.label),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.neutralLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showCountryPicker(context, cubit, state),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_flagForCode(state.countryCode),
                                        style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 4),
                                      Text(state.countryCode,
                                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                                      const Icon(Icons.expand_more, size: 16, color: AppColors.neutralMid),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 24, color: AppColors.border),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: AppTypography.body,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    hintText: '70 00 00 00',
                                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                                  ),
                                  onChanged: cubit.setPhone,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Text(state.error!,
                            style: AppTypography.caption.copyWith(color: AppColors.error)),
                        ],

                        const SizedBox(height: 32),
                        NumbiaButton(
                          label: 'Envoyer le code',
                          isLoading: state.isLoading,
                          onPressed: canProceed
                              ? () async {
                                  final ok = await cubit.sendOtp();
                                  if (ok && context.mounted) context.push('/otp');
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                text: 'Deja un compte ? ',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                                children: [
                                  TextSpan(
                                    text: 'Se connecter',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _flagForCode(String code) => _countryCodes
      .firstWhere((c) => c.code == code, orElse: () => const _Country('+226', '', '🌍'))
      .flag;

  void _showCountryPicker(BuildContext context, OnboardingCubit cubit, OnboardingState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Text('Choisir le pays', style: AppTypography.h3),
          ),
          const Divider(),
          ..._countryCodes.map((country) => ListTile(
            leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
            title: Text(country.name, style: AppTypography.body),
            trailing: Text(country.code, style: AppTypography.body.copyWith(color: AppColors.neutralMid)),
            selected: state.countryCode == country.code,
            selectedTileColor: AppColors.primaryLight,
            onTap: () { cubit.setCountryCode(country.code); Navigator.pop(context); },
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
