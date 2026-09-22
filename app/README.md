# app

App Flutter de finanzia (Android e iOS): feature-first + Clean Architecture con Riverpod 3 (spec 003 §3, spec 008). Por ahora tiene el scaffold (F0.6) y el login con Google (F1.9).

## Requisitos

- Flutter 3.35.7 (Dart 3.9). CI fija la misma versión.
- Para correrla contra el backend local: `just up` y `just dev` desde la raíz, con `FINANZIA_GOOGLE_VERIFIER=fake` (ver `backend/.env.example`).

## Comandos

Desde la raíz del repo:

| Receta | Qué hace |
|---|---|
| `just app-run` | Corre la app en el emulador Android con `AUTH_MODE=fake` contra `http://10.0.2.2:8000` |
| `just app-gen` | Regenera freezed/json_serializable/drift (`build_runner`) y los textos l10n |
| `just app-lint` | `dart format` + `flutter analyze --fatal-infos` |
| `just app-test` | Tests (sin goldens ni contrato) + gate de cobertura de `domain`+`application` ≥ 90 % |
| `just app-goldens` | Regenera los goldens visuales del login (claro y oscuro) |
| `just app-contract` | Corre el flujo de auth real contra la API local (`FINANZIA_API_URL`) |
| `just app-ci` | Lo mismo que corre `App CI` en GitHub Actions |

El código generado (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/gen/`) se versiona. CI lo regenera y falla si cambia.

## Configuración (`--dart-define`)

| Variable | Default | Uso |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:8000` | Base de la API. En el simulador de iOS o en Chrome usa `http://localhost:8000` |
| `AUTH_MODE` | `google` | `fake`: login sin Google, con `id_token` `fake:<sub>:<email>` |
| `FAKE_USER_EMAIL` | `dev@finanzia.local` | Usuario del modo fake |
| `GOOGLE_SERVER_CLIENT_ID` | — | Client ID **web** de Google Cloud; obligatorio con `AUTH_MODE=google` |

El login real con Google está pendiente de crear el proyecto GCP. Cuando exista hay que:
- registrar el SHA-1 de la app Android,
- añadir `GIDClientID` y el URL scheme en `ios/Runner/Info.plist`,
- pasar `GOOGLE_SERVER_CLIENT_ID` con el mismo valor que `FINANZIA_GOOGLE_CLIENT_ID` del backend.

## Arquitectura

```
lib/
├── main.dart            # ProviderScope + overrides de composición + licencias de fuentes
├── app/                 # MaterialApp, router (session gate) y composition.dart
├── core/                # config, red (dio + AuthInterceptor), tema, l10n, formato COP,
│                        # secure storage, Drift (vacía hasta F4.1), widgets de marca
└── features/
    ├── auth/
    │   ├── domain/        # User, AuthFailure (sellado), AuthRepository — Dart puro
    │   ├── data/          # AuthApi, SessionManager, TokenStore, IdTokenProvider, repo impl
    │   ├── application/   # AuthController (sesión global), SignInController (acción)
    │   └── presentation/  # SplashPage, LoginPage, ticker de captura, botón de Google
    └── dashboard/         # placeholder post-login hasta F4
```

`test/architecture_test.dart` verifica las reglas de capas: `domain` puro, `application` sin `data` ni `presentation`, `core` sin features.

### Sesión

- **Almacenamiento:** los tokens van en `flutter_secure_storage` (Keystore en Android, Keychain `first_unlock` en iOS), como un único blob JSON con el último perfil conocido. Nunca van en SharedPreferences (spec 009 §2).
- **Al abrir la app:** si el access token sigue vigente, se entra sin red. Si vence en menos de 60 s, se hace refresh. Si el backend rechaza el refresh, se vuelve al login. Si no hay red, se entra con el perfil en caché (P4).
- **Durante el uso:** `AuthInterceptor` añade el Bearer. Ante `401 token_expired` pide un refresh a `SessionManager`, que es single-flight: N peticiones concurrentes comparten uno solo. Luego reintenta la petición una vez. Si el refresh es rechazado o llega `401 unauthorized`, la sesión termina y el login muestra "Tu sesión se cerró para proteger tu cuenta".
- **Logout:** si el access está vencido, primero se refresca para poder revocar. Después se revoca el refresh token en el backend (best effort) y se borra la sesión local.

### Sistema de diseño

Paleta "Esmeralda andina", tipografía y tokens en `lib/core/theme/`. El detalle está en spec 008 §7.1 y en el canvas de diseño. Las fuentes van empaquetadas en `assets/fonts` con sus licencias OFL.

## Tests

- **Unitarios y de widgets:** dominio, `SessionManager` (incluye el single-flight de punta a punta), repositorio, interceptor, controllers, redirects del router y estados del login.
- **Goldens (`tag golden`):** `test/features/auth/presentation/goldens/`. Dependen del rasterizador de cada plataforma, así que CI no los corre. Se regeneran y revisan a mano.
- **Contrato (`tag backend`):** login → `/v1/me` → refresh → restore → logout contra la API real. Se salta si no está definido `FINANZIA_API_URL`.
