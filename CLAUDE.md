# CLAUDE.md — NUMBAA

Contexte pour les futures sessions Claude sur ce projet.

## Projet

NUMBAA est une application Flutter (Clean Architecture) qui permet aux petites entreprises d'Afrique de l'Ouest de créer et publier un mini-site depuis leur smartphone. L'OTP se fait par WhatsApp (Baileys), le backend est Node.js/TypeScript, la base de données PostgreSQL, le cache Redis, et les mini-sites sont déployés sur Vercel.

## Répertoires

- **`lib/`** — Application Flutter (le code actif, Clean Architecture complète)
- **`backend/`** — API Node.js/TypeScript (structure complète, à déployer)

---

## Flutter — état actuel (COMPLET, `flutter analyze` → 0 erreurs)

### Architecture

```
lib/
├── core/
│   ├── di/service_locator.dart       # GetIt — enregistre ApiClient + 4 repos HTTP + 16 use cases
│   ├── network/api_client.dart       # HTTP wrapper avec JWT (flutter_secure_storage)
│   ├── routing/app_router.dart       # GoRouter complet
│   └── constants/enums.dart          # AppLanguage, BusinessCategory, WebsiteType, SiteStatus, SectionType
├── domain/
│   ├── entities/                     # UserEntity, BusinessEntity (+ ContactInfo, SocialLinks), SiteEntity (+ SiteSection), ProductEntity, TemplateEntity
│   ├── repositories/                 # 4 interfaces abstraites
│   └── usecases/                     # 16 use cases (auth×5, business×2, site×8, template×1)
├── data/repositories/
│   ├── http_auth_repository.dart     # Implémentation HTTP de AuthRepository
│   ├── http_business_repository.dart # Implémentation HTTP de BusinessRepository
│   ├── http_site_repository.dart     # Implémentation HTTP de SiteRepository
│   ├── http_template_repository.dart # Implémentation HTTP de TemplateRepository
│   ├── mock_*.dart                   # Mocks SharedPreferences (pour dev offline)
└── features/
    ├── auth/                         # AuthCubit (CheckAuthStatus, Logout, MarkOnboardingComplete)
    ├── onboarding/                   # OnboardingCubit (RequestOtp, VerifyOtp, SaveBusiness, GetBusiness)
    ├── dashboard/                    # DashboardCubit (GetBusiness, GetSite)
    ├── templates/                    # TemplateCubit (GetTemplatesByType)
    ├── site_editor/                  # EditorCubit (GetProducts, Add/Update/DeleteProduct, UpdateSite)
    └── generation/                   # PublishScreen (PublishSiteUseCase)
```

### URL backend

`lib/core/di/service_locator.dart` ligne 33 :
```dart
const String apiBaseUrl = 'http://10.0.2.2:3000/v1'; // émulateur Android → localhost
```
Changer pour le vrai serveur en production.

### Dépendances clés (pubspec.yaml)
- `flutter_bloc`, `go_router`, `get_it`, `http`, `flutter_secure_storage`, `image_picker`, `uuid`, `equatable`, `google_fonts`

---

## Backend — état actuel (COMPLET, à déployer)

### Structure `backend/src/`

```
config/
  env.ts          # Variables d'env (DATABASE_URL, REDIS_URL, JWT_SECRET, VERCEL_TOKEN, etc.)
  database.ts     # pg.Pool + query<T>() helper
  redis.ts        # ioredis singleton + connectRedis()
whatsapp/
  baileys.client.ts   # Connexion WhatsApp (QR au premier démarrage → session persistante dans ./whatsapp-session/)
  otp.service.ts      # generateAndSendOtp() + verifyOtp() — Redis TTL 300s, max 3 tentatives
middlewares/
  auth.middleware.ts  # JWT verify + session Redis, generateToken()
  upload.middleware.ts # multer JPG/PNG/WEBP
modules/
  auth/     # POST /request-otp, POST /verify-otp, POST /logout, GET /me, PATCH /onboarding
  business/ # GET|POST|PUT / + POST /logo
  site/     # GET /:businessId, POST /, PUT /:siteId, POST /:siteId/publish
  product/  # GET|POST / + PUT|DELETE /:productId + POST /:productId/image
  template/ # GET / + GET /:id (pas d'auth requis)
  plan/     # GET /me
publisher/
  html.builder.ts   # SiteEntity → HTML statique auto-contenu (CSS inline, CSS variables --primary)
  vercel.deployer.ts # deployToVercel(businessId, html) → URL Vercel
db/
  migrations/001_init.sql  # 7 tables : users, businesses, templates, sites, site_sections, products, plans
  migrate.ts               # Runner de migration
  seeds/templates.seed.ts  # 6 templates (3 showcase + 3 ecommerce)
routes.ts   # Monte tous les modules sous /v1
app.ts      # Setup Express (helmet, cors, morgan, rate-limiting, Baileys au démarrage)
```

### Schéma BDD (PostgreSQL)

7 tables : `users`, `businesses`, `templates`, `sites`, `site_sections`, `products`, `plans`

Voir `backend/src/db/migrations/001_init.sql` pour le DDL complet.

### Redis keys
- `otp:{phone}` → `{code, attempts}` JSON — TTL 300s
- `session:{userId}` → `"valid"` — TTL 7 jours (révoqué au logout)

### Variables d'environnement (`backend/.env.example`)
```
DATABASE_URL=postgresql://user:pass@localhost:5432/numbaa
REDIS_URL=redis://localhost:6379
JWT_SECRET=<32 chars min>
JWT_EXPIRY=7d
VERCEL_TOKEN=<vercel api token>
UPLOAD_DIR=uploads
MAX_FILE_SIZE=5242880
PORT=3000
```

### Démarrage

```bash
cd backend
npm install
cp .env.example .env        # Remplir les vraies valeurs
npx ts-node src/db/migrate.ts            # Créer les tables
npx ts-node src/db/seeds/templates.seed.ts  # Insérer les 6 templates
npm run dev                 # Démarre Express + Baileys (QR dans le terminal au premier démarrage)
```

Au premier démarrage, Baileys affiche un QR code dans le terminal. Scanne-le avec le numéro WhatsApp dédié à l'envoi des OTP. La session est ensuite persistée dans `backend/whatsapp-session/`.

---

## API Endpoints

| Module | Method | Path | Auth |
|--------|--------|------|------|
| Auth | POST | /v1/auth/request-otp | Non |
| Auth | POST | /v1/auth/verify-otp | Non |
| Auth | POST | /v1/auth/logout | Oui |
| Auth | GET | /v1/auth/me | Oui |
| Auth | PATCH | /v1/auth/onboarding | Oui |
| Business | GET/POST/PUT | /v1/business | Oui |
| Business | POST | /v1/business/logo | Oui (multipart) |
| Sites | GET | /v1/sites/:businessId | Oui |
| Sites | POST | /v1/sites | Oui |
| Sites | PUT | /v1/sites/:siteId | Oui |
| Sites | POST | /v1/sites/:siteId/publish | Oui |
| Products | GET/POST | /v1/sites/:siteId/products | Oui |
| Products | PUT/DELETE | /v1/sites/:siteId/products/:productId | Oui |
| Templates | GET | /v1/templates | Non |
| Templates | GET | /v1/templates/:id | Non |
| Plans | GET | /v1/plans/me | Oui |

---

## Ce qui reste à faire

1. **Déployer le backend** sur un VPS (Railway, Render, DigitalOcean)
   - Configurer les variables d'env en production
   - Remplacer `http://10.0.2.2:3000` par l'URL réelle dans `lib/core/di/service_locator.dart`

2. **Upload de fichiers en production** — actuellement multer stocke en local (`uploads/`)
   - Envisager Cloudinary ou S3 pour les logos et images produits

3. **Tests end-to-end** — scénario complet :
   - `requestOtp(phone)` → message WhatsApp reçu
   - `verifyOtp(phone, code)` → JWT retourné, user en DB
   - `saveBusiness(...)` → business en PostgreSQL
   - `createSite(...)` → site + sections en DB
   - `publishSite(...)` → HTML généré → Vercel → URL retournée

4. **Gestion des forfaits** — la table `plans` existe mais pas encore de logique de décompte SMS/data

---

## Points importants

- `deleteProduct` prend `(siteId, productId)` — l'EditorCubit passe `state.site?.id` comme siteId
- Le JWT est stocké dans `flutter_secure_storage` (clé `numbaa_jwt`)
- La session Redis est vérifiée à chaque requête authentifiée (`session:{userId}`)
- Les templates sont read-only (seeded en DB, jamais créés par l'utilisateur)
- Le `primaryColor` du site pilote les CSS variables `--primary` dans le HTML généré
