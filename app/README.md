# app

App Flutter de finanzia (Android e iOS): feature-first + Clean Architecture con Riverpod 3 (spec 003 §3, spec 008). Por ahora tiene el scaffold (F0.6), el login con Google (F1.9), el paso de onboarding de Gmail (F3.6), la base local con sync offline (F4.1), el Inicio con el resumen del mes (F4.6), la pantalla de movimientos (F4.2), la de revisión (F4.7), la captura de notificaciones en Android (F4.3), Registrar manual (F4.5a) y las categorías propias (F4.8a); Ajustes tiene Gmail, notificaciones, Mis categorías y cierre de sesión.

## Requisitos

- Flutter 3.35.7 (Dart 3.9). Codemagic fija la misma versión.
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
| `just app-ci` | Lint + tests + cobertura: correrlo antes de subir (GitHub no corre CI de la app) |
| `just app-android-test` | Tests JUnit del listener nativo (`CaptureFilter`); necesita JDK 17–21 y el `gradlew` que genera `flutter build apk` |

El código generado (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/gen/`) se versiona: regenerarlo con `just app-gen` antes de subir.

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

- **iOS**: cliente de tipo iOS con el bundle `co.finanzia.finanzia`. Su client ID y el invertido (`com.googleusercontent.apps.…`) van en `ios/Flutter/GoogleSignIn.xcconfig`; `Info.plist` los toma de ahí para `GIDClientID` y el esquema de URL de vuelta. Sin ellos el build de Codemagic se detiene.

### Gmail (F3.6)

Tras el login, mientras el usuario no haya terminado el onboarding (F4.4, marca local `onboarding_done:<userId>` en `sync_state`, que se pierde al cerrar sesión), el gate de sesión (`redirectFor` + `onboardingGateProvider`, spec 008 §2) lleva al primer paso sin resolver: `/onboarding/gmail` (`lib/features/gmail/presentation/gmail_onboarding_page.dart`), `/onboarding/notificaciones` (solo Android) y `/onboarding/cuentas` (`lib/features/onboarding/presentation/`). La pantalla de Gmail explica con el lenguaje "Veta esmeralda" qué lee (solo alertas de bancos) y qué nunca lee (correo personal, contactos, adjuntos); "Conectar Gmail" pide el scope `gmail.readonly` con autorización incremental (`google_sign_in`, `authorizeServer`) y envía el `serverAuthCode` a `POST /gmail/connect`; "Ahora no" sigue al próximo paso. "Listo" o "Ahora no" en Cuentas terminan el onboarding. Contra el backend local en modo de prueba de Google, hace falta el túnel de desarrollo (`backend/README.md` §16) para que el consentimiento complete el canje.

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
    ├── capture/           # Captura de notificaciones Android (F4.3): cola nativa → /ingest
    ├── categories/        # Categorías propias (F4.8a): hoja crear/editar, Mis categorías
    ├── accounts/          # Cuentas vinculadas (F4.4): hoja crear/editar, Mis cuentas
    ├── onboarding/        # Gate y pasos del onboarding (F4.4): notificaciones, cuentas
    ├── shell/             # HomeShell (bottom nav) + marcadores de Registrar/Ajustes
    └── dashboard/         # Inicio (F4.6): resumen del mes calculado en local
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

Shell autenticado (`lib/features/shell/`, `HomeShell` sobre `StatefulShellRoute.indexedStack` sobre sus 5 rutas: `/` (Inicio), `/movimientos`, `/registrar`, `/revision` y `/ajustes` — spec 008 §2; el detalle `/movimientos/:id` se abre a pantalla completa, sin la barra): la barra inferior de 5 pestañas ya está completa, pero Registrar y Ajustes siguen siendo marcadores ("Llega pronto"). Ajustes ya adelantó el cierre de sesión.

`lib/features/transactions/` trae las dos pantallas nuevas (spec 008 §3.3, diseño en el canvas F4.2 enlazado en spec 008 §7.1):

- **Lista** (`transactions_page.dart`, diseño B "Tarjetas por día"): tarjetas por día con paginación creciente sobre `TransactionsRepository.watch`, buscador con debounce y hoja de filtros. Periodo, tipo, banco y categoría filtran en SQL; fuente (canal) y texto se aplican en el cliente. Cubre los 5 estados sin filas (vacío total, vacío del mes, sin resultados, error de lectura local y primera sincronización) más el aviso de sin conexión y el de operaciones rechazadas (reintentar o dejar como estaba).
- **Detalle** (`transaction_detail_page.dart`, diseño A "Monto protagonista"): monto con decimales, campos editables, fuentes del servidor (`GET /transactions/{id}`, con reintento automático al recuperar la red), par de transferencia navegable, marcar/desmarcar transfer y notas con guardado automático.

### Inicio (F4.6)

`lib/features/dashboard/` muestra el resumen del mes (spec 008 §3.2, diseño A "Balance protagonista").

- **Cálculo local.** Todo se calcula en el teléfono: `DriftInsightsRepository` hace un SQL agregado sobre `local_transactions` y `local_categories`, sin transfers, en el rango del mes en hora de Colombia (`lib/core/time/colombia_month.dart`). Funciona sin red y reacciona al instante a un cambio de categoría. `GET /insights/monthly` no existe; queda diferido.
- **Franja superior.** Saludo, línea de sync, selector de mes (sin meses futuros), balance, y Gastos/Ingresos con su delta frente al mes anterior.
- **"En qué se fue".** El top 5 de categorías, con barras hechas con widgets propios y sin `fl_chart`, más "Otras". Tocar una categoría abre Movimientos filtrado por esa categoría y ese mes.

### Revisión (F4.7)

`lib/features/review/` muestra lo que el backend no pudo leer solo (spec 008 §3.5, AC-8.1). Lee la tabla `local_review` y la mantiene al día con el pull del `SyncCoordinator`.

- **Lista** (`review_page.dart`): cada tarjeta muestra el canal, el banco, la fecha de recepción, el motivo en lenguaje claro y un extracto del mensaje con los montos resaltados. Los teléfonos no se resaltan. Tiene estado vacío ("Nada por revisar") y aviso de sin conexión.
- **Detalle** (`/revision/:rawMessageId`, a pantalla completa, `review_detail_page.dart`):
  - Muestra el texto seleccionable con los montos resaltados, recortado a 320 dp con "Ver mensaje completo" cuando es más largo. Los teléfonos se ignoran. Tocar un monto resaltado lo copia al formulario.
  - El formulario llega prellenado desde `partial_extract`. Si el mensaje no trae fecha, propone la de recepción.
  - "Crear movimiento" encola `convertReview` y "Descartar" encola `discardReview`, este último tras confirmar. Ambas pasan por el outbox, así que funcionan sin conexión.
- **Montos:** `lib/features/review/domain/amount_highlight.dart` usa la misma regla de separadores que `parse_amount` del backend, y el mismo patrón de teléfonos que `parsing/domain/excerpt.py`.
- **Mensajes ya fallidos:** si una plantilla nueva ya los entiende, `just reparse` (backend/README) los reprocesa y cierra su revisión.

### Captura de notificaciones (F4.3, solo Android)

El listener es nativo (`android/app/src/main/kotlin/co/finanzia/finanzia/capture/`, spec 006 §3.2 y spec 008 §4.1):

- **`FinanziaNotificationListener`** recibe cada notificación, aunque la app esté cerrada. **`CaptureFilter`** decide con la config de `GET /v1/config/capture`: app bancaria o SMS de remitente bancario, y con monto. Lo que pasa va a **`CaptureStore`**, una cola SQLite propia (`finanzia_capture.db`). Lo demás no se guarda ni se loguea.
- **`CaptureChannel`** (`MethodChannel("co.finanzia/capture")`) expone la cola y el permiso a Dart. En Dart, `lib/features/capture/` la ve como el puerto `NotificationSource` (en iOS es la cola de Apple Pay, abajo).
- **`CaptureFlusher`** vacía la cola en lotes de 50 a `POST /v1/ingest/notifications` al entrar, al volver a primer plano, cada 15 min y al recuperar la red. Lo capturado con la app cerrada se envía al abrirla (sin envío en segundo plano todavía). Al cerrar sesión se borran la cola y la config.
- **Ajustes → "Notificaciones del banco"** muestra si hay acceso. "Activar" muestra la divulgación y abre el ajuste del sistema.

Para probarla en un teléfono, con `just up`, `just dev`, `just worker` y `just app-run`: activar el acceso desde Ajustes y hacer un movimiento real con Bancolombia o Nequi. La cola se puede mirar con `adb shell run-as co.finanzia.finanzia ls databases` (`finanzia_capture.db`). Para un SMS, el título de la notificación de Mensajes tiene que coincidir con un patrón de `sms_sender_patterns` (`backend/.../parsing/config/capture.yaml`): si el SMS llega desde un número corto y no desde un nombre, el filtro lo ignora.

### Pagos con Apple Pay en iPhone (F4.3b)

iOS no deja leer notificaciones. La captura automática es una automatización personal "Transacción" de Atajos (iOS 17+) que, al pagar con Wallet, corre la acción **"Registrar pago en finanzia"** (spec 006 §3.3):

- **`RegistrarPagoWallet`** (`ios/Runner/RegistrarPagoWallet.swift`) es la App Intent: recibe tarjeta, comercio y monto y los encola sin abrir la app.
- **`WalletQueue`** (`ios/Runner/WalletCapture.swift`) es la cola (JSON en Application Support) y **`WalletCaptureChannel`** la expone por el mismo `MethodChannel("co.finanzia/capture")`.
- En Dart, **`IosWalletNotificationSource`** arma el texto que parsea la plantilla `apple_wallet` del backend y el mismo `CaptureFlusher` lo envía al abrir la app.
- El onboarding y Ajustes → "Pagos con Apple Pay" guían la creación del Atajo. Para que el pago se una con el correo del banco, la tarjeta tiene que llevar el banco y sus últimos 4 dígitos.

**Compilar e instalar.** Este equipo es Windows, así que el `.ipa` sale de Codemagic (`codemagic.yaml` en la raíz, workflow `ios-unsigned`, corrida manual):

1. En codemagic.io, crear la app desde el repo y un grupo de variables `finanzia` con `API_BASE_URL=https://luka.a360soft.tech` (el backend de producción, backend/deploy/README.md).
2. Correr `ios-unsigned` y descargar `finanzia.ipa` de los artefactos.
3. Instalarlo con SideStore, que lo firma con el Apple ID; con un Apple ID gratuito hay que refrescarlo cada 7 días.

Riesgos conocidos: el Swift solo se compila en Codemagic, así que los errores se corrigen con sus logs. Con un Apple ID gratuito el entitlement de lectura NFC puede no estar disponible; si SideStore lo quita, la lectura de tags en iOS no funciona, pero el resto sí.

### Registrar y categorías propias (F4.5a, F4.8a)

- **Registrar** (`lib/features/transactions/presentation/registrar_page.dart`): el formulario de Revisión (`TransactionFormCard`) más la nota. Encola `createTransaction` por el outbox, así que funciona sin red. "Ver" abre el detalle con `resolveId`, que devuelve el id del servidor si el sync ya canjeó el local en este proceso.
- **Categorías** (`lib/features/categories/`): crear, editar y borrar van directo a `/v1/categories`, sin outbox, y sin red avisan. Tras un éxito, `DriftCategoriesStore` actualiza la copia local; el pull de cada sync sigue siendo la verdad. El ícono se guarda por clave (`category_catalog.dart`) y el color como `#RRGGBB` de la paleta.

## Tests

- **Unitarios y de widgets:** dominio, `SessionManager` (incluye el single-flight de punta a punta), repositorio, interceptor, controllers, redirects del router y estados del login.
- **Goldens (`tag golden`):** `test/features/auth/presentation/goldens/` y `test/features/review/presentation/goldens/`. Dependen del rasterizador de cada plataforma, así que `just app-test` no los corre. Se regeneran y revisan a mano.
