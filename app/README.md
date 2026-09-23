# app

App Flutter de finanzia (Android e iOS): feature-first + Clean Architecture con Riverpod 3 (spec 003 §3, spec 008). Por ahora tiene el scaffold (F0.6) y el login con Google (F1.9).

## Requisitos

- Flutter 3.35.7 (Dart 3.9). CI fija la misma versión.
- Para correrla contra el backend local: `just up` y `just dev` desde la raíz, con `backend/.env` creado a partir de `backend/.env.example`.
- Un teléfono Android por USB (o un emulador) con depuración USB activa.

## Comandos

Desde la raíz del repo:

| Receta | Qué hace |
|---|---|
| `just app-run` | `adb reverse tcp:8000 tcp:8000` + `flutter run` |
| `just app-gen` | Regenera freezed/json_serializable/drift (`build_runner`) y los textos l10n |
| `just app-lint` | `dart format` + `flutter analyze --fatal-infos` |
| `just app-test` | Tests (sin goldens) + gate de cobertura de `domain`+`application` ≥ 90 % |
| `just app-goldens` | Regenera los goldens visuales del login (claro y oscuro) |
| `just app-ci` | Lo mismo que corre `App CI` en GitHub Actions |

El código generado (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/gen/`) se versiona. CI lo regenera y falla si cambia.

## Configuración

No hay que pasar nada para desarrollo: `flutter run` (o Run en el IDE) usa los valores por defecto. Solo existen dos `--dart-define`, pensados para builds de otros entornos:

| Variable | Default | Uso |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8000` | Base de la API; con `adb reverse tcp:8000 tcp:8000` llega al backend local desde teléfono o emulador |
| `GOOGLE_SERVER_CLIENT_ID` | client ID web de `finanzia-509500` | Audiencia del `id_token` que verifica el backend |

Los `dart-define` se aplican al compilar: después de cambiarlos hay que relanzar la app, porque el hot reload no los recoge.

### Google Sign-In real

El proyecto de Google Cloud es `finanzia-509500` (Google Auth Platform, público externo en modo de prueba). Tiene dos clientes OAuth:

- **Web** (`30065910946-hatnf…apps.googleusercontent.com`): es la audiencia del `id_token`. La app lo usa como `serverClientId` y el backend lo exige como `FINANZIA_GOOGLE_CLIENT_ID`.
- **Android**: paquete `co.finanzia.finanzia` con el SHA-1 del keystore de debug de la máquina de desarrollo. Si otra máquina u otro keystore firma el APK, hay que agregar su SHA-1 (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`).

Mientras la app esté en modo de prueba, solo los usuarios de prueba de la consola pueden iniciar sesión. Con el backend corriendo, `just app-run` abre el túnel adb y lanza la app. No hay modo de login simulado: la app y el backend solo aceptan Google real.

Pendiente para iOS: crear el cliente OAuth de iOS y añadir `GIDClientID` y el URL scheme en `ios/Runner/Info.plist`.

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
