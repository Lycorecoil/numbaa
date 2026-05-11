import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final canVerify = _otp.length == 4 && !state.isLoading;

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
                        ? 'Code verification'
                        : 'Code de verification',
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.neutralMid),
                      children: [
                        TextSpan(
                          text: state.language.name == 'moore'
                              ? 'Code WhatsApp yii ne '
                              : 'Code envoye par WhatsApp au ',
                        ),
                        TextSpan(
                          text: state.fullPhone,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutralDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Debug banner (bypass mode only — removed in production)
                  if (state.debugCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bug_report, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Dev — Code : ${state.debugCode}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: SizedBox(
                          width: 60,
                          height: 64,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: AppTypography.h2,
                            decoration: InputDecoration(
                              counterText: '',
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
                            ),
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        state.error!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  const Spacer(),

                  NumbiaButton(
                    label: state.language.name == 'moore'
                        ? 'Siga'
                        : 'Verifier',
                    isLoading: state.isLoading,
                    onPressed: canVerify
                        ? () async {
                            final user = await cubit.verifyOtp(_otp);
                            if (user != null && context.mounted) {
                              context.read<AuthCubit>().setUser(user);
                              if (user.hasCompletedOnboarding) {
                                context.go('/dashboard');
                              } else {
                                context.go('/setup');
                              }
                            }
                          }
                        : null,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: TextButton(
                      onPressed: () => cubit.sendOtp(),
                      child: Text(
                        state.language.name == 'moore'
                            ? 'Code yii tome'
                            : 'Renvoyer le code',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
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
}
