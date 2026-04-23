# NUMBAA

Plateforme de communication digitale pour les petites entreprises d'Afrique de l'Ouest.
Permet aux commerçants de créer et publier un mini-site professionnel depuis leur téléphone, sans connaissances techniques.

---

## Structure du projet

```
numbaa/
├── lib/                        # Application Flutter (frontend)
│   ├── core/
│   │   ├── di/                 # Injection de dépendances (GetIt)
│   │   ├── network/            # ApiClient HTTP + JWT
│   │   └── routing/            # GoRouter
│   ├── domain/
│   │   ├── entities/           # UserEntity, BusinessEntity, SiteEntity, ProductEntity, TemplateEntity
│   │   ├── repositories/       # Contrats (interfaces)
│   │   └── usecases/           # 16 use cases (Clean Architecture)
│   ├── data/
│   │   └── repositories/       # Implémentations HTTP (+ mocks pour dev offline)
│   └── features/
│       ├── auth/               # OTP WhatsApp → JWT
│       ├── onboarding/         # Nom, catégorie, contacts
│       ├── dashboard/          # Vue principale
│       ├── templates/          # Choix du template
│       ├── site_editor/        # Édition des sections + produits
│       └── generation/         # Publication Vercel
└── backend/                    # API Node.js/TypeScript
    ├── src/
    │   ├── config/             # env, PostgreSQL, Redis
    │   ├── whatsapp/           # Baileys (OTP WhatsApp)
    │   ├── middlewares/        # JWT auth, multer upload
    │   ├── modules/            # auth, business, site, product, template, plan
    │   ├── publisher/          # html.builder.ts + vercel.deployer.ts
    │   └── db/                 # migrations SQL + seeds templates
    └── package.json
```

---

## Stack

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter 3.x + BLoC/Cubit + GoRouter + GetIt |
| API | Node.js + TypeScript + Express |
| Base de données | PostgreSQL |
| Cache / OTP | Redis (ioredis) |
| WhatsApp OTP | @whiskeysockets/baileys |
| Auth | JWT + session Redis |
| Upload | multer |
| Publication | Vercel Deployments API |

---

## Lancement rapide

### Backend

```bash
cd backend
cp .env.example .env      # Remplir DATABASE_URL, REDIS_URL, JWT_SECRET, VERCEL_TOKEN
npm install
npx ts-node src/db/migrate.ts
npx ts-node src/db/seeds/templates.seed.ts
npm run dev               # Scan le QR Baileys au premier démarrage
```

### Flutter

```bash
flutter pub get
flutter run               # Pointe sur http://10.0.2.2:3000/v1 (émulateur Android)
```

---

## Fonctionnalités

- Authentification sans mot de passe via OTP WhatsApp
- Création de profil business (nom, catégorie, logo, contacts, réseaux sociaux)
- Choix parmi 6 templates (vitrine ou e-commerce)
- Éditeur de sections (hero, à propos, services, galerie, produits, contact, témoignages, footer)
- Catalogue produits avec photos
- Publication automatique sur Vercel → URL personnalisée
- Gestion de forfait (SMS, data)
