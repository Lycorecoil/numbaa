# NUMBAA — Remédiation Dependency Security P0 V1.2

Date : 4 novembre 2026 (Africa/Lagos). Dépôt : D:\Projects\NUMBAA.
Branche : fix/backend-dependency-security-p0. Base préservée : fix/builder-security-p0 à eb967401754029b1be2375fb9b5a61dc70d45f6b.
Draft PR : https://github.com/Lycorecoil/numbaa/pull/2 ; base fix/builder-security-p0. PR #1 ouverte et non fusionnée lors du contrôle initial.

## Mesures avant / après

| Mesure | Avant | Après |
| --- | --- | --- |
| Paquets signalés | 18 | 4 |
| Critiques / élevés / modérés | 1 / 10 / 7 | 0 / 0 / 4 |
| GHSA uniques dans npm audit | 36 | 1 |
| Paquets signalés uniquement par propagation parent | 6 | 3 |
| Paquets signalés en production (--omit=dev) | 13 | 0 |
| GHSA uniques en production | 32 | 0 |

Les paquets parents signalés uniquement par propagation sont un sous-ensemble des paquets signalés, pas des vulnérabilités supplémentaires. Les CVE sont rattachées aux identifiants GHSA et ne sont pas recomptées. Périmètre : avis présents dans npm audit ; cela ne prouve pas l'absence de toute vulnérabilité possible.

## Versions, nature et chaînes

| Paquet | Versions avant → après | Nature | Environnement | Chaîne parent | Résultat |
| --- | --- | --- | --- | --- | --- |
| @vercel/blob | 2.8.0 → 2.8.2 | directe | production | root → Blob | résolu dans cet audit |
| @vercel/cli-config | 0.2.6 → 0.3.6 | transitive | production | Blob → OIDC → cli-config | résolu dans cet audit |
| @vercel/oidc | 3.8.7 → 3.8.10 | transitive | production | Blob → OIDC | résolu dans cet audit |
| axios | 1.19.0 → 1.21.0 | transitive | production | Baileys → Axios | résolu dans cet audit |
| body-parser | 1.20.6 → 1.20.9 | transitive | production | Express → body-parser | résolu dans cet audit |
| brace-expansion | 1.1.18 → 1.1.21 | transitive | dev | minimatch → brace-expansion | résolu dans cet audit |
| follow-redirects | 1.16.0 → 1.16.2 | transitive | production | Baileys → Axios → follow-redirects | résolu dans cet audit |
| glob | 7.2.3 → 7.2.3 | transitive | dev | ts-node-dev → rimraf → glob | reste : modérée |
| minimatch | 3.1.5 → 3.1.5 | transitive | dev | ts-node-dev → rimraf → glob → minimatch | reste : modérée |
| morgan | 1.11.0 → 1.12.1 | directe | production | root → Morgan | résolu dans cet audit |
| music-metadata | 11.15.0 → 11.16.1 | transitive | production | Baileys → music-metadata | résolu dans cet audit |
| proxy-addr | 2.0.7 → 2.0.8 | transitive | production | Express → proxy-addr | résolu dans cet audit |
| qs | 6.15.3 → 6.16.2 | transitive | production | Express → qs / body-parser → qs | résolu dans cet audit |
| rimraf | 2.7.1 → 2.7.1 | transitive | dev | ts-node-dev → rimraf | reste : modérée |
| sharp | 0.35.3 → 0.35.5 | transitive | production | Baileys → sharp (peer) | résolu dans cet audit |
| ts-node-dev | 2.0.0 → 2.0.0 | directe | dev | root → ts-node-dev | reste : modérée |
| undici | 6.28.1 → 6.29.1 | transitive | production | Blob → Undici | résolu dans cet audit |
| zod | 4.1.11 → 4.6.7 | transitive | production | Blob → OIDC → cli-config → Zod | résolu dans cet audit |

Express 4.22.2 et Baileys 6.7.24 restent inchangés. Aucune migration majeure de SDK, aucune rétrogradation Blob. Les binaires optionnels sharp passent de 0.35.3 à 0.35.5 et leurs libvips de 1.3.2 à 1.3.4 selon la plateforme.

## Lots et compatibilité

1. HTTP/proxy/logs : corrections compatibles du lockfile body-parser 1.20.9, proxy-addr 2.0.8, Morgan 1.12.1, brace-expansion 1.1.21 et qs. Premier commit 199a9da ; audit intermédiaire : 15 paquets, zéro critique. CI du lot : https://github.com/Lycorecoil/numbaa/actions/runs/41804664472 (deux jobs réussis).
2. Réseau/médias/Vercel : Axios 1.21.0, follow-redirects 1.16.2, Undici 6.29.1, sharp 0.35.5, music-metadata 11.16.1, Blob 2.8.2, OIDC 3.8.10. Commit 1d4c388. Tests SDK et OTP ajoutés.
3. Deux overrides ciblés dans package.json : Express → qs 6.16.2 (la contrainte ~6.15.1 conserve sinon une version signalée) ; OIDC → cli-config 0.3.6 (le SDK épingle sinon 0.3.1, qui dépend/embarque Zod vulnérable). cli-config 0.3.6 inclut une chaîne Zod corrigée (4.6.7 installée). Un simple override de Zod ne suffirait pas à prouver la correction d'un bundle embarqué. Tests des schémas auth/global et résolution OIDC ajoutés. Le passage de cli-config 0.2.6 à 0.3.6 est une évolution 0.x interne : compatibilité exercée sur les interfaces utilisées par OIDC, sans prétendre couvrir toutes les fonctions CLI.

La simulation npm audit fix --dry-run a été examinée. Aucun audit fix --force exécuté. Les résolutions ont été appliquées par npm update ciblé et overrides ; aucune modification des correctifs SEC-01/SEC-02/DATA-01, routes, schéma, Flutter ou framework.

## Exposition réelle et validation

- body-parser : parseurs réels de l'application testés avec JSON/formulaires gzip valides, flux malformés, octets supplémentaires après gzip et requête health après erreur. Les erreurs de décompression attendues produisent 400 sans arrêt du processus.
- proxy-addr : la configuration observée est trust proxy = 1, pas un sous-réseau IPv6 vulnérable. L'alerte critique est néanmoins corrigée. Test de l'application réelle : un préfixe X-Forwarded-For manipulé ne contourne pas la limite OTP lorsque le dernier hop client reste identique. Ce test ne certifie pas la topologie du reverse proxy de production.
- JWT/session : vrais middleware/JWT ; Redis simulé ; tokens manquants/invalides et session absente refusés.
- Axios/follow-redirects : serveurs loopback uniquement ; suivi de redirection et suppression des credentials entre origines testés. Les scénarios de pollution de prototype ou HTTP/2 des avis ne sont pas tous reproduits.
- Blob/Undici : vrai SDK appelé via le helper de l'application ; MockAgent interdit le réseau réel et valide le bearer factice et la réponse upload.
- OIDC/cli-config/Zod : token de requête synthétique non expiré, schémas valides et invalides exercés ; aucun compte Vercel, rafraîchissement réel ou signature d'identité réelle testé.
- Baileys/médias : import du SDK conservé, génération/lecture PNG par sharp et parsing WAV par music-metadata. Aucun socket WhatsApp ouvert.
- OTP : service réel, Redis/sender WhatsApp mockés ; code à quatre chiffres, stockage et expiration de 300 s vérifiés. Aucun OTP réel envoyé.
- Publication : helper réel avec HTTPS entièrement mocké ; encodage HTML et alias de réponse vérifiés. Aucun déploiement effectué.
- Morgan : middleware réel exercé par les tests HTTP ; aucun audit complet des consommateurs de logs n'est revendiqué.

## Commandes et preuves

- git status, branch -vv, log, fetch et ls-remote : référence eb96740, main f0ce86f, aucun changement local initial ; nouvelle branche dédiée.
- npm ci : exécuté initialement et après chacun des deux lots, réussi.
- npm audit --json et --omit=dev --json : exécutés avant/après ; résultat final production : found 0 vulnerabilities.
- npm ls --all et npm explain sur les 18 paquets : résultats sauvegardés hors dépôt. Une première lecture npm ls a eu lieu trop tôt pendant npm ci et a renvoyé ELSPROBLEMS sur l'installation incomplète ; elle n'est pas utilisée comme preuve, les lectures après installation sont la référence.
- npm test : build TypeScript et tests locaux finaux réussis : 38 réussis, zéro échec, une suite PostgreSQL ignorée localement faute de TEST_DATABASE_URL.
- PostgreSQL et SDK : CI du commit de code 1d4c388 réussie, [run 41805205954](https://github.com/Lycorecoil/numbaa/actions/runs/41805205954) : **46 tests réussis, zéro échec, zéro ignoré**, dont les sept scénarios PostgreSQL. Le commit de documentation qui contient ce rapport doit également être vérifié sur la PR avant le compte rendu final ; son lien CI et son SHA seront relevés dans ce compte rendu, sans substituer la CI historique à celle du dernier SHA.
- git diff --check : réussi avant chaque commit.
- Avis GitHub Advisory API publics relus le 4 novembre 2026 pour les 36 GHSA ; rattachements ci-dessous.
- Le connecteur GitHub a refusé la création de PR (403 integration) et le runtime UI n'a pas démarré. La draft PR #2 a été créée avec l'authentification Git existante via l'API standard, sans afficher ni enregistrer ses identifiants.

## Registre GHSA / CVE

| GHSA unique | CVE primaire associée | Paquet source | Sévérité audit initial | État |
| --- | --- | --- | --- | --- |
| [GHSA-vh66-26gq-q6x8](https://github.com/advisories/GHSA-vh66-26gq-q6x8) | CVE-2026-101908 | axios | moderate | absent après correction |
| [GHSA-9fr6-4gfg-395g](https://github.com/advisories/GHSA-9fr6-4gfg-395g) | CVE-2026-101902 | axios | moderate | absent après correction |
| [GHSA-c29m-xwm3-cm6r](https://github.com/advisories/GHSA-c29m-xwm3-cm6r) | CVE-2026-101903 | axios | high | absent après correction |
| [GHSA-mghh-pgcx-3jjj](https://github.com/advisories/GHSA-mghh-pgcx-3jjj) | CVE-2026-101906 | axios | high | absent après correction |
| [GHSA-x97p-jq2g-jp4f](https://github.com/advisories/GHSA-x97p-jq2g-jp4f) | CVE-2026-101909 | axios | high | absent après correction |
| [GHSA-3pq3-5fj3-cg6v](https://github.com/advisories/GHSA-3pq3-5fj3-cg6v) | CVE-2026-101898 | axios | high | absent après correction |
| [GHSA-542g-h47m-68v8](https://github.com/advisories/GHSA-542g-h47m-68v8) | CVE-2026-101901 | axios | high | absent après correction |
| [GHSA-j8rh-479h-cp32](https://github.com/advisories/GHSA-j8rh-479h-cp32) | CVE-2026-101904 | axios | moderate | absent après correction |
| [GHSA-4hqw-qxg8-jxx2](https://github.com/advisories/GHSA-4hqw-qxg8-jxx2) | CVE-2026-101900 | axios | moderate | absent après correction |
| [GHSA-m8m8-qj5v-23w3](https://github.com/advisories/GHSA-m8m8-qj5v-23w3) | CVE-2026-101905 | axios | high | absent après correction |
| [GHSA-44g4-m2mj-wpvx](https://github.com/advisories/GHSA-44g4-m2mj-wpvx) | CVE-2026-101899 | axios | moderate | absent après correction |
| [GHSA-r4gj-5m52-g5wh](https://github.com/advisories/GHSA-r4gj-5m52-g5wh) | CVE-2026-101907 | axios | high | absent après correction |
| [GHSA-27r3-jxmh-p828](https://github.com/advisories/GHSA-27r3-jxmh-p828) | CVE-2026-111181 | body-parser | high | absent après correction |
| [GHSA-q2hr-2g5m-vwhr](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr) | CVE-2026-102277 | brace-expansion | moderate | absent après correction |
| [GHSA-qhr7-859c-m2p7](https://github.com/advisories/GHSA-qhr7-859c-m2p7) | CVE-2026-102278 | brace-expansion | high | absent après correction |
| [GHSA-6j4f-fj2g-mc7p](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p) | CVE-2026-102276 | brace-expansion | high | absent après correction |
| [GHSA-q3jh-wrc6-jgq8](https://github.com/advisories/GHSA-q3jh-wrc6-jgq8) | CVE-2026-111756 | follow-redirects | high | absent après correction |
| [GHSA-8r9p-f939-6h3c](https://github.com/advisories/GHSA-8r9p-f939-6h3c) | CVE-2026-111755 | follow-redirects | high | absent après correction |
| [GHSA-mrwp-f3q8-3g9p](https://github.com/advisories/GHSA-mrwp-f3q8-3g9p) | CVE-2026-116689 | follow-redirects | high | absent après correction |
| [GHSA-g3hv-75wg-m249](https://github.com/advisories/GHSA-g3hv-75wg-m249) | CVE-2026-118764 | minimatch | moderate | reste (dev) |
| [GHSA-jxfw-x594-9x9m](https://github.com/advisories/GHSA-jxfw-x594-9x9m) | CVE-2026-15603 | morgan | moderate | absent après correction |
| [GHSA-9f6g-j8ch-79g4](https://github.com/advisories/GHSA-9f6g-j8ch-79g4) | CVE-2026-87859 | morgan | moderate | absent après correction |
| [GHSA-f94x-6692-553q](https://github.com/advisories/GHSA-f94x-6692-553q) | CVE-2026-107391 | music-metadata | moderate | absent après correction |
| [GHSA-5gfj-9q3v-qfp3](https://github.com/advisories/GHSA-5gfj-9q3v-qfp3) | CVE-2026-107389 | music-metadata | moderate | absent après correction |
| [GHSA-jqcg-44mw-7w3h](https://github.com/advisories/GHSA-jqcg-44mw-7w3h) | CVE-2026-90711 | proxy-addr | critical | absent après correction |
| [GHSA-x5fp-wj9c-mxmx](https://github.com/advisories/GHSA-x5fp-wj9c-mxmx) | CVE-2026-82562 | qs | moderate | absent après correction |
| [GHSA-4mjr-xmp4-gh2g](https://github.com/advisories/GHSA-4mjr-xmp4-gh2g) | CVE-2026-82417 | qs | moderate | absent après correction |
| [GHSA-6pq8-jhm2-2vcw](https://github.com/advisories/GHSA-6pq8-jhm2-2vcw) | CVE-2026-110816 | qs | moderate | absent après correction |
| [GHSA-rgj7-g3m4-5g8c](https://github.com/advisories/GHSA-rgj7-g3m4-5g8c) | aucune CVE primaire publiée dans le champ cve_id | sharp | high | absent après correction |
| [GHSA-wq5f-xc86-pv6w](https://github.com/advisories/GHSA-wq5f-xc86-pv6w) | aucune CVE primaire publiée dans le champ cve_id | sharp | high | absent après correction |
| [GHSA-4qv8-2p9j-2685](https://github.com/advisories/GHSA-4qv8-2p9j-2685) | CVE-2026-109924 | undici | moderate | absent après correction |
| [GHSA-xjj6-f33q-929c](https://github.com/advisories/GHSA-xjj6-f33q-929c) | CVE-2026-109869 | undici | high | absent après correction |
| [GHSA-2m5v-pch6-74hx](https://github.com/advisories/GHSA-2m5v-pch6-74hx) | CVE-2026-109383 | undici | high | absent après correction |
| [GHSA-qrxm-fqhp-jwvm](https://github.com/advisories/GHSA-qrxm-fqhp-jwvm) | CVE-2026-87018 | undici | high | absent après correction |
| [GHSA-9fm3-97px-rjf6](https://github.com/advisories/GHSA-9fm3-97px-rjf6) | CVE-2026-109932 | undici | moderate | absent après correction |
| [GHSA-mrhx-c7xc-m3w5](https://github.com/advisories/GHSA-mrhx-c7xc-m3w5) | CVE-2023-54404 | zod | high | absent après correction |

Pour les avis sharp sans cve_id primaire, suivre leurs références amont ; l'absence de ce champ n'est pas une preuve d'absence de CVE dans les bibliothèques natives. Le décompte de 36 correspond uniquement aux identifiants racines présents dans npm audit, sans y ajouter artificiellement les références secondaires.

## Risque résiduel et décisions

Reste un seul avis GHSA-g3hv-75wg-m249 (CVE-2026-118764), propagé sur quatre paquets : ts-node-dev → rimraf → glob → minimatch. Sévérité modérée, développement uniquement dans l'arbre npm observé. Cause : minimatch <11.0.1 ; pas de résolution automatique compatible proposée pour cette chaîne ancienne. Une mise à niveau forcée de minimatch 3 vers 11 risque de casser glob 7 ; elle n'est pas appliquée.

Exposition : motifs du runner de développement, pas les requêtes HTTP de l'application. Mesures recommandées : ne pas exposer npm run dev à des entrées non fiables ; installer les dépendances runtime avec npm ci --omit=dev dans un environnement de production maîtrisé. Aucune configuration de déploiement modifiée ici.

Responsable proposé : mainteneur backend NUMBAA / responsable sécurité-produit. Horizon proposé : lot distinct de remplacement de ts-node-dev avant le 18 novembre 2026 ; ces affectations et cette échéance sont à confirmer par le responsable, pas présentées comme acceptées. Aucune exception pour une vulnérabilité critique/élevée exploitable en production n'est demandée sur l'audit final : aucune n'est signalée dans l'arbre production. Revue humaine requise pour les overrides et l'exposition des outils dev.

Limites : Redis et WhatsApp réels non testés, pas d'identifiants de production utilisés, aucun déploiement ni fusion. Les avertissements npm concernant Multer 1.x et les scripts d'installation Baileys/protobufjs sont consignés : ce sont des avertissements distincts des résultats audit actuels ; aucun script n'a été approuvé ni migration Multer majeure ajoutée implicitement.
