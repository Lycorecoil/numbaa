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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await getIt<LoginWithPasswordUseCase>().call(
        _fullPhone,
        _passwordCtrl.text,
      );
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
          ..._countryCodes.map(
            (country) => ListTile(
              leading:
                  Text(country.flag, style: const TextStyle(fontSize: 24)),
              title: Text(country.name, style: AppTypography.body),
              trailing: Text(country.code,
                  style: AppTypography.body
                      .copyWith(color: AppColors.neutralMid)),
              selected: _countryCode == country.code,
              selectedTileColor: AppColors.primaryLight,
              onTap: () {
                setState(() => _countryCode = country.code);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final canSubmit = _phoneCtrl.text.trim().length >= 8 &&
        _passwordCtrl.text.isNotEmpty &&
        !_loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connexion', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Entrez votre numero et votre mot de passe.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.neutralMid),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text('Numero de telephone', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_flagForCode(_countryCode),
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text(_countryCode,
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          const Icon(Icons.arrow_drop_down,
                              size: 18, color: AppColors.neutralMid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: '70 00 00 00',
                        hintStyle: AppTypography.bodySmall
                            .copyWith(color: AppColors.neutralMid),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              Text('Mot de passe', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Votre mot de passe',
                  hintStyle: AppTypography.bodySmall
                      .copyWith(color: AppColors.neutralMid),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: canSubmit ? (_) => _submit() : null,
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.error)),
              ],

              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/phone'),
                  child: Text(
                    'Mot de passe oublie ?',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),

              const Spacer(),

              NumbiaButton(
                label: 'Se connecter',
                isLoading: _loading,
                onPressed: canSubmit ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/language'),
                  child: Text(
                    'Creer un compte',
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
  }
}

class _Country {
  final String code;
  final String name;
  final String flag;
  const _Country(this.code, this.name, this.flag);
}
