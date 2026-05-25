import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../constants/enums.dart';
import '../di/service_locator.dart';
import '../../domain/usecases/auth/mark_onboarding_complete_use_case.dart';
import '../../domain/usecases/auth/request_otp_use_case.dart';
import '../../domain/usecases/auth/verify_otp_use_case.dart';
import '../../domain/usecases/business/get_business_use_case.dart';
import '../../domain/usecases/business/save_business_use_case.dart';
import '../../domain/usecases/business/upload_logo_use_case.dart';
import '../../domain/usecases/plan/get_user_plan_use_case.dart';
import '../../domain/usecases/site/add_product_use_case.dart';
import '../../domain/usecases/site/delete_product_use_case.dart';
import '../../domain/usecases/site/delete_site_use_case.dart';
import '../../domain/usecases/site/get_products_use_case.dart';
import '../../domain/usecases/site/get_site_use_case.dart';
import '../../domain/usecases/site/update_product_use_case.dart';
import '../../domain/usecases/site/update_site_use_case.dart';
import '../../domain/usecases/template/get_templates_by_type_use_case.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/set_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/cubits/dashboard_cubit.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/generation/presentation/screens/preview_screen.dart';
import '../../features/generation/presentation/screens/publish_screen.dart';
import '../../features/onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../features/onboarding/presentation/screens/language_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/otp_screen.dart';
import '../../features/onboarding/presentation/screens/phone_screen.dart';
import '../../features/aide/presentation/screens/aide_screen.dart';
import '../../features/commercialisation/presentation/screens/commercialisation_screen.dart';
import '../../features/forfait/presentation/screens/forfait_screen.dart';
import '../../features/mini_site/presentation/screens/mini_site_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/site_editor/presentation/cubits/editor_cubit.dart';
import '../../features/site_editor/presentation/screens/editor_screen.dart';
import '../../features/site_editor/presentation/screens/product_manager_screen.dart';
import '../../features/templates/presentation/cubits/template_cubit.dart';
import '../../features/templates/presentation/screens/template_catalog_screen.dart';
import '../../features/templates/presentation/screens/template_preview_screen.dart';
import '../../features/templates/presentation/screens/website_type_screen.dart';
import '../../shared/layouts/main_shell.dart';

/// Shared OnboardingCubit instance for the language→phone→otp→setup flow.
OnboardingCubit _buildOnboardingCubit() => OnboardingCubit(
      requestOtp: getIt<RequestOtpUseCase>(),
      verifyOtp: getIt<VerifyOtpUseCase>(),
      saveBusiness: getIt<SaveBusinessUseCase>(),
      uploadLogo: getIt<UploadLogoUseCase>(),
      markOnboardingComplete: getIt<MarkOnboardingCompleteUseCase>(),
    );

/// Builds the app router. Requires an [AuthCubit] for redirect logic.
GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // --- Splash ---
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // --- Login (returning users) ---
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- Set password (after first OTP verification) ---
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const SetPasswordScreen(),
      ),

      // --- Onboarding flow (language → phone → otp → setup) ---
      // Shared OnboardingCubit wraps all 4 screens
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => _buildOnboardingCubit(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/language',
            builder: (context, state) => const LanguageScreen(),
          ),
          GoRoute(
            path: '/phone',
            builder: (context, state) => const PhoneScreen(),
          ),
          GoRoute(
            path: '/otp',
            builder: (context, state) => const OtpScreen(),
          ),
          GoRoute(
            path: '/setup',
            builder: (context, state) => const OnboardingScreen(),
          ),
        ],
      ),

      // --- Main app shell (bottom nav) ---
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              final user = authCubit.state.user;
              return BlocProvider(
                create: (_) => DashboardCubit(
                  getBusiness: getIt<GetBusinessUseCase>(),
                  getSite: getIt<GetSiteUseCase>(),
                  getUserPlan: getIt<GetUserPlanUseCase>(),
                  deleteSite: getIt<DeleteSiteUseCase>(),
                  userId: user?.id ?? '',
                ),
                child: const DashboardScreen(),
              );
            },
          ),
          GoRoute(
            path: '/forfait',
            builder: (context, state) => const ForfaitScreen(),
          ),
          GoRoute(
            path: '/commercialisation',
            builder: (context, state) => const CommercialisationScreen(),
          ),
          GoRoute(
            path: '/mini-site',
            builder: (context, state) {
              final user = authCubit.state.user;
              return BlocProvider(
                create: (_) => DashboardCubit(
                  getBusiness: getIt<GetBusinessUseCase>(),
                  getSite: getIt<GetSiteUseCase>(),
                  getUserPlan: getIt<GetUserPlanUseCase>(),
                  deleteSite: getIt<DeleteSiteUseCase>(),
                  userId: user?.id ?? '',
                ),
                child: const MiniSiteScreen(),
              );
            },
          ),
          GoRoute(
            path: '/aide',
            builder: (context, state) => const AideScreen(),
          ),
          GoRoute(
            path: '/templates-browse',
            builder: (context, state) {
              return BlocProvider(
                create: (_) => TemplateCubit(getIt<GetTemplatesByTypeUseCase>())
                  ..init(WebsiteType.showcase),
                child: const TemplateCatalogScreen(),
              );
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // --- Website type selection ---
      GoRoute(
        path: '/website-type',
        builder: (context, state) {
          final siteId = state.uri.queryParameters['siteId'];
          return BlocProvider(
            create: (_) => TemplateCubit(getIt<GetTemplatesByTypeUseCase>()),
            child: WebsiteTypeScreen(siteId: siteId),
          );
        },
      ),

      // --- Template selection flow ---
      GoRoute(
        path: '/templates',
        builder: (context, state) {
          final typeName = state.uri.queryParameters['type'] ?? 'showcase';
          final siteId = state.uri.queryParameters['siteId'];
          final websiteType = WebsiteType.values.firstWhere(
            (t) => t.name == typeName,
            orElse: () => WebsiteType.showcase,
          );
          return BlocProvider(
            create: (_) => TemplateCubit(getIt<GetTemplatesByTypeUseCase>())
              ..init(websiteType),
            child: TemplateCatalogScreen(siteId: siteId),
          );
        },
      ),
      GoRoute(
        path: '/template-preview',
        builder: (context, state) {
          final typeName = state.uri.queryParameters['type'] ?? 'showcase';
          final templateId = state.uri.queryParameters['templateId'] ?? '';
          final siteId = state.uri.queryParameters['siteId'];
          final websiteType = WebsiteType.values.firstWhere(
            (t) => t.name == typeName,
            orElse: () => WebsiteType.showcase,
          );
          return BlocProvider(
            create: (_) => TemplateCubit(getIt<GetTemplatesByTypeUseCase>())
              ..initWithTemplate(websiteType, templateId),
            child: TemplatePreviewScreen(siteId: siteId),
          );
        },
      ),

      // --- Site editor ---
      GoRoute(
        path: '/editor/:siteId',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          return BlocProvider(
            create: (_) => EditorCubit(
            getProducts: getIt<GetProductsUseCase>(),
            addProduct: getIt<AddProductUseCase>(),
            updateProduct: getIt<UpdateProductUseCase>(),
            deleteProduct: getIt<DeleteProductUseCase>(),
            updateSite: getIt<UpdateSiteUseCase>(),
          )
              ..loadSite(siteId),
            child: _EditorLoader(siteId: siteId),
          );
        },
      ),

      // --- Product manager ---
      GoRoute(
        path: '/editor/:siteId/products',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          return BlocProvider(
            create: (_) => EditorCubit(
            getProducts: getIt<GetProductsUseCase>(),
            addProduct: getIt<AddProductUseCase>(),
            updateProduct: getIt<UpdateProductUseCase>(),
            deleteProduct: getIt<DeleteProductUseCase>(),
            updateSite: getIt<UpdateSiteUseCase>(),
          )
              ..loadSite(siteId),
            child: _ProductManagerLoader(siteId: siteId),
          );
        },
      ),

      // --- Preview ---
      GoRoute(
        path: '/preview/:siteId',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          return BlocProvider(
            create: (_) => EditorCubit(
            getProducts: getIt<GetProductsUseCase>(),
            addProduct: getIt<AddProductUseCase>(),
            updateProduct: getIt<UpdateProductUseCase>(),
            deleteProduct: getIt<DeleteProductUseCase>(),
            updateSite: getIt<UpdateSiteUseCase>(),
          )
              ..loadSite(siteId),
            child: _PreviewLoader(siteId: siteId),
          );
        },
      ),

      // --- Publish ---
      GoRoute(
        path: '/publish/:siteId',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          return BlocProvider(
            create: (_) => EditorCubit(
            getProducts: getIt<GetProductsUseCase>(),
            addProduct: getIt<AddProductUseCase>(),
            updateProduct: getIt<UpdateProductUseCase>(),
            deleteProduct: getIt<DeleteProductUseCase>(),
            updateSite: getIt<UpdateSiteUseCase>(),
          )
              ..loadSite(siteId),
            child: _PublishLoader(siteId: siteId),
          );
        },
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Site loader helpers
// ---------------------------------------------------------------------------

class _EditorLoader extends StatefulWidget {
  final String siteId;
  const _EditorLoader({required this.siteId});

  @override
  State<_EditorLoader> createState() => _EditorLoaderState();
}

class _EditorLoaderState extends State<_EditorLoader> {
  @override
  void initState() {
    super.initState();
    _loadSite();
  }

  Future<void> _loadSite() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      if (mounted) context.read<EditorCubit>().setError('Utilisateur non connecte');
      return;
    }
    final business = await getIt<GetBusinessUseCase>().call(user.id);
    if (business == null) {
      if (mounted) context.read<EditorCubit>().setError('Business introuvable');
      return;
    }
    final site = await getIt<GetSiteUseCase>().call(business.id);
    if (!mounted) return;
    if (site != null) {
      context.read<EditorCubit>().loadSiteEntity(site);
    } else {
      context.read<EditorCubit>().setError('Site introuvable');
    }
  }

  @override
  Widget build(BuildContext context) => EditorScreen(siteId: widget.siteId);
}

class _ProductManagerLoader extends StatefulWidget {
  final String siteId;
  const _ProductManagerLoader({required this.siteId});

  @override
  State<_ProductManagerLoader> createState() => _ProductManagerLoaderState();
}

class _ProductManagerLoaderState extends State<_ProductManagerLoader> {
  @override
  void initState() {
    super.initState();
    _loadSite();
  }

  Future<void> _loadSite() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final business = await getIt<GetBusinessUseCase>().call(user.id);
    if (business == null) return;
    final site = await getIt<GetSiteUseCase>().call(business.id);
    if (site != null && mounted) {
      context.read<EditorCubit>().loadSiteEntity(site);
    } else if (mounted) {
      context.read<EditorCubit>().setError('Site introuvable');
    }
  }

  @override
  Widget build(BuildContext context) =>
      ProductManagerScreen(siteId: widget.siteId);
}

class _PreviewLoader extends StatefulWidget {
  final String siteId;
  const _PreviewLoader({required this.siteId});

  @override
  State<_PreviewLoader> createState() => _PreviewLoaderState();
}

class _PreviewLoaderState extends State<_PreviewLoader> {
  @override
  void initState() {
    super.initState();
    _loadSite();
  }

  Future<void> _loadSite() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final business = await getIt<GetBusinessUseCase>().call(user.id);
    if (business == null) return;
    final site = await getIt<GetSiteUseCase>().call(business.id);
    if (site != null && mounted) {
      context.read<EditorCubit>().loadSiteEntity(site);
    } else if (mounted) {
      context.read<EditorCubit>().setError('Site introuvable');
    }
  }

  @override
  Widget build(BuildContext context) => PreviewScreen(siteId: widget.siteId);
}

class _PublishLoader extends StatefulWidget {
  final String siteId;
  const _PublishLoader({required this.siteId});

  @override
  State<_PublishLoader> createState() => _PublishLoaderState();
}

class _PublishLoaderState extends State<_PublishLoader> {
  @override
  void initState() {
    super.initState();
    _loadSite();
  }

  Future<void> _loadSite() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final business = await getIt<GetBusinessUseCase>().call(user.id);
    if (business == null) return;
    final site = await getIt<GetSiteUseCase>().call(business.id);
    if (site != null && mounted) {
      context.read<EditorCubit>().loadSiteEntity(site);
    } else if (mounted) {
      context.read<EditorCubit>().setError('Site introuvable');
    }
  }

  @override
  Widget build(BuildContext context) => PublishScreen(siteId: widget.siteId);
}
