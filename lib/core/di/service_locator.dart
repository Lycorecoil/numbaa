import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../data/repositories/http_auth_repository.dart';
import '../../data/repositories/http_business_repository.dart';
import '../../data/repositories/http_template_repository.dart';
import '../../data/repositories/http_site_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/repositories/template_repository.dart';
import '../../domain/repositories/site_repository.dart';
// Auth use cases
import '../../domain/usecases/auth/check_auth_status_use_case.dart';
import '../../domain/usecases/auth/login_with_password_use_case.dart';
import '../../domain/usecases/auth/request_otp_use_case.dart';
import '../../domain/usecases/auth/set_password_use_case.dart';
import '../../domain/usecases/auth/verify_otp_use_case.dart';
import '../../domain/usecases/auth/logout_use_case.dart';
import '../../domain/usecases/auth/mark_onboarding_complete_use_case.dart';
// Business use cases
import '../../domain/usecases/business/get_business_use_case.dart';
import '../../domain/usecases/business/save_business_use_case.dart';
// Site use cases
import '../../domain/usecases/site/get_site_use_case.dart';
import '../../domain/usecases/site/create_site_use_case.dart';
import '../../domain/usecases/site/update_site_use_case.dart';
import '../../domain/usecases/site/publish_site_use_case.dart';
import '../../domain/usecases/site/get_products_use_case.dart';
import '../../domain/usecases/site/add_product_use_case.dart';
import '../../domain/usecases/site/update_product_use_case.dart';
import '../../domain/usecases/site/delete_product_use_case.dart';
// Template use cases
import '../../domain/usecases/template/get_templates_by_type_use_case.dart';

final getIt = GetIt.instance;

const String apiBaseUrl = 'https://numbaa.vercel.app/v1';

/// Register all dependencies. Call once at app startup.
void setupServiceLocator() {
  // HTTP client
  getIt.registerLazySingleton(() => ApiClient(baseUrl: apiBaseUrl));

  // Repositories (HTTP implementations)
  getIt.registerLazySingleton<AuthRepository>(() => HttpAuthRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<BusinessRepository>(() => HttpBusinessRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<TemplateRepository>(() => HttpTemplateRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<SiteRepository>(() => HttpSiteRepository(getIt<ApiClient>()));

  // Auth use cases
  getIt.registerLazySingleton(() => CheckAuthStatusUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LoginWithPasswordUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RequestOtpUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SetPasswordUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => VerifyOtpUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => MarkOnboardingCompleteUseCase(getIt<AuthRepository>()));

  // Business use cases
  getIt.registerLazySingleton(() => GetBusinessUseCase(getIt<BusinessRepository>()));
  getIt.registerLazySingleton(() => SaveBusinessUseCase(getIt<BusinessRepository>()));

  // Site use cases
  getIt.registerLazySingleton(() => GetSiteUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => CreateSiteUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => UpdateSiteUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => PublishSiteUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => GetProductsUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => AddProductUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => UpdateProductUseCase(getIt<SiteRepository>()));
  getIt.registerLazySingleton(() => DeleteProductUseCase(getIt<SiteRepository>()));

  // Template use cases
  getIt.registerLazySingleton(() => GetTemplatesByTypeUseCase(getIt<TemplateRepository>()));
}
