# app

App Flutter de finanzia (Android e iOS): feature-first + Clean Architecture con Riverpod 3 (spec 003 §3, spec 008). Por ahora tiene el scaffold (F0.6), el login con Google (F1.9), el paso de onboarding de Gmail (F3.6), la base local con sync offline (F4.1) y la pantalla de movimientos (F4.2); el resto del shell son marcadores.

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

### Gmail (F3.6)

Tras el login, si Gmail no está activo (nunca conectado, revocado o con error) y el usuario no eligió "Ahora no" antes, el gate de sesión (`redirectFor`, spec 008 §2) lleva a `/onboarding/gmail` (`lib/features/gmail/presentation/gmail_onboarding_page.dart`) en vez de a Inicio. La pantalla explica con el lenguaje "Veta esmeralda" qué lee (solo alertas de bancos) y qué nunca lee (correo personal, contactos, adjuntos); "Conectar Gmail" pide el scope `gmail.readonly` con autorización incremental (`google_sign_in`, `authorizeServer`) y envía el `serverAuthCode` a `POST /gmail/connect`; "Ahora no" solo pospone la invitación (se guarda en `sync_state` hasta el próximo login) y ambos botones llevan a Inicio. Contra el backend local en modo de prueba de Google, hace falta el túnel de desarrollo (`backend/README.md` §16) para que el consentimiento complete el canje.

En Ajustes, la fila "Gmail" (`lib/features/gmail/presentation/widgets/gmail_settings_tile.dart`) muestra el estado real (`GET /gmail/status`): conectado ("Conectado · `<email>`" + botón "Desconectar" con diálogo de confirmación), revocado o con error ("Reconectar"), sin conectar ("Conectar") o sin poder consultarlo ("Reintentar"). Como el consent screen sigue en modo de prueba, un grant vencido a los 7 días también aparece como revocado — se resuelve reconectando desde aquí, no es un error de la app.

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
    ├── sync/              # SyncCoordinator (F4.1): outbox + pull incremental
    ├── transactions/      # Movimientos (F4.2): lista, filtros, detalle, categoría/transfer
    ├── shell/             # HomeShell (bottom nav) + marcadores de Registrar/Revisión/Ajustes
    └── dashboard/         # placeholder post-login hasta F4.6
```

`test/architecture_test.dart` verifica las reglas de capas: `domain` puro, `application` sin `data` ni `presentation`, `core` sin features.

### Sesión

- **Almacenamiento:** los tokens van en `flutter_secure_storage` (Keystore en Android, Keychain `first_unlock` en iOS), como un único blob JSON con el último perfil conocido. Nunca van en SharedPreferences (spec 009 §2).
- **Al abrir la app:** si el access token sigue vigente, se entra sin red. Si vence en menos de 60 s, se hace refresh. Si el backend rechaza el refresh, se vuelve al login. Si no hay red, se entra con el perfil en caché (P4).
- **Durante el uso:** `AuthInterceptor` añade el Bearer. Ante `401 token_expired` pide un refresh a `SessionManager`, que es single-flight: N peticiones concurrentes comparten uno solo. Luego reintenta la petición una vez. Si el refresh es rechazado o llega `401 unauthorized`, la sesión termina y el login muestra "Tu sesión se cerró para proteger tu cuenta".
- **Logout:** si el access está vencido, primero se refresca para poder revocar. Después se revoca el refresh token en el backend (best effort) y se borra la sesión local.

### Sistema de diseño

Paleta "Esmeralda andina", tipografía y tokens en `lib/core/theme/`. El detalle está en spec 008 §7.1 y en el canvas de diseño. Las fuentes van empaquetadas en `assets/fonts` con sus licencias OFL.

### Base de datos local y sincronización (F4.1)

La app trae una base SQLite local con Drift (`AppDatabase`, base `finanzia`, `schemaVersion` 3 — `lib/core/db/tables.dart`) para funcionar sin conexión (spec 004 §5): `local_transactions` (con la bandera `pending_push` y, desde F4.2, la columna `channels`), `local_categories`, `local_accounts`, `local_review` y `outbox` (operaciones offline en orden FIFO, con `target_id`/`related_id` para canjear ids locales), más `sync_state` (cursor de transacciones, última sincronización y usuario dueño). El `SyncCoordinator` (`lib/features/sync/`, contrato en spec 005 §9, disparadores en spec 008 §5) drena primero el outbox y luego hace el pull.

La migración a `schemaVersion` 3 (F4.2, `lib/core/db/app_database.dart`) agrega `channels` y, en el mismo paso, borra el cursor de `sync_state`: eso fuerza un pull completo en el próximo sync para rellenar los canales de las transacciones que ya estaban en la base antes de la migración.

Se borra por completo, incluido lo que no alcanzó a enviarse, solo cuando el usuario cierra sesión voluntariamente en caliente (transición `Authenticated → Unauthenticated(sessionExpired: false)`); una sesión que expira, o un arranque en frío sin sesión, la conserva. También se borra si inicia sesión un usuario distinto al que la dejó (`claimFor`). Antes de borrar o de reclamar la base para otro usuario, el coordinador espera a que termine cualquier sync en curso, para que no se crucen escrituras tardías entre usuarios (P6).

Para inspeccionarla en un Android físico o emulador (`applicationId` `co.finanzia.finanzia`, `android/app/build.gradle.kts`):

```sh
adb shell run-as co.finanzia.finanzia ls databases
adb shell run-as co.finanzia.finanzia ls app_flutter
```

El archivo (`finanzia.sqlite`) suele vivir en `app_flutter` (carpeta de documentos de la app), no en `databases`; con la ruta se puede copiar (`adb shell run-as ... cat ...` o `run-as ... cp`) y abrir con `sqlite3`, o inspeccionarla directo con el Database Inspector de Android Studio.

### Movimientos (F4.2)

Shell autenticado (`lib/features/shell/`, `HomeShell` sobre `StatefulShellRoute.indexedStack` sobre sus 5 rutas: `/` (Inicio), `/movimientos`, `/registrar`, `/revision` y `/ajustes` — spec 008 §2; el detalle `/movimientos/:id` se abre a pantalla completa, sin la barra): la barra inferior de 5 pestañas ya está completa, pero solo Transacciones tiene pantalla real; Dashboard, Registrar, Revisión y Ajustes son marcadores ("Llega pronto"). Ajustes ya adelantó el cierre de sesión.

`lib/features/transactions/` trae las dos pantallas nuevas (spec 008 §3.3, diseño en el canvas F4.2 enlazado en spec 008 §7.1):

- **Lista** (`transactions_page.dart`, diseño B "Tarjetas por día"): tarjetas por día con paginación creciente sobre `TransactionsRepository.watch`, buscador con debounce y hoja de filtros. Periodo, tipo, banco y categoría filtran en SQL; fuente (canal) y texto se aplican en el cliente. Cubre los 5 estados sin filas (vacío total, vacío del mes, sin resultados, error de lectura local y primera sincronización) más el aviso de sin conexión y el de operaciones rechazadas (reintentar o dejar como estaba).
- **Detalle** (`transaction_detail_page.dart`, diseño A "Monto protagonista"): monto con decimales, campos editables, fuentes del servidor (`GET /transactions/{id}`, con reintento automático al recuperar la red), par de transferencia navegable, marcar/desmarcar transfer y notas con guardado automático.

## Tests

- **Unitarios y de widgets:** dominio, `SessionManager` (incluye el single-flight de punta a punta), repositorio, interceptor, controllers, redirects del router y estados del login.
- **Goldens (`tag golden`):** `test/features/auth/presentation/goldens/`. Dependen del rasterizador de cada plataforma, así que CI no los corre. Se regeneran y revisan a mano.
