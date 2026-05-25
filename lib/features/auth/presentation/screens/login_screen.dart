import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/usecases/auth/login_with_password_use_case.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../cubits/auth_cubit.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _countryCode = '+226';
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await getIt<LoginWithPasswordUseCase>().call(_fullPhone, _passwordCtrl.text);
      if (!mounted) return;
      context.read<AuthCubit>().setUser(user);
      if (user.hasCompletedOnboarding) {
        context.go('/dashboard');
      } else {
        context.go('/setup');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showCountryPicker() {
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
            selected: _countryCode == country.code,
            selectedTileColor: AppColors.primaryLight,
            onTap: () { setState(() => _countryCode = country.code); Navigator.pop(context); },
          )),
        ],
      ),
    );
  }

  String _flagForCode(String code) => _countryCodes
      .firstWhere((c) => c.code == code, orElse: () => const _Country('+226', '', '🌍'))
      .flag;

  @override
  Widget build(BuildContext context) {
    final canSubmit = _phoneCtrl.text.trim().length >= 8 && _passwordCtrl.text.isNotEmpty && !_loading;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // Header orange
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.26,
              child: Center(
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
                    const Text('NUMBAA', style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    )),
                    const SizedBox(height: 4),
                    Text('Votre vitrine digitale',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                  ],
                ),
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
                    Text('Connexion', style: AppTypography.h2),
                    const SizedBox(height: 6),
                    Text('Bon retour ! Connectez-vous pour continuer.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid)),
                    const SizedBox(height: 28),

                    Text('Telephone', style: AppTypography.label),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutralLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _showCountryPicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_flagForCode(_countryCode), style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 4),
                                  Text(_countryCode, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                                  const Icon(Icons.expand_more, size: 16, color: AppColors.neutralMid),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 24, color: AppColors.border),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: AppTypography.body,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                hintText: '70 00 00 00',
                                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text('Mot de passe', style: AppTypography.label),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutralLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: AppTypography.body,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                hintText: 'Votre mot de passe',
                                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: canSubmit ? (_) => _submit() : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.neutralMid,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
                    ],

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/phone'),
                        child: Text('Mot de passe oublie ?',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                      ),
                    ),

                    const SizedBox(height: 16),
                    NumbiaButton(
                      label: 'Se connecter',
                      isLoading: _loading,
                      onPressed: canSubmit ? _submit : null,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/phone'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Pas encore de compte ? ',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                            children: [
                              TextSpan(
                                text: 'Creer un compte',
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
  }
}

class _Country {
  final String code;
  final String name;
  final String flag;
  const _Country(this.code, this.name, this.flag);
}
