# luka

App Flutter (Android/iOS) + backend FastAPI que captura gastos automáticamente (notificaciones, Gmail, Apple Pay, manual) y arma el reporte de renta colombiano (formulario 210 de la DIAN). Usuarios y moneda: Colombia, COP, español.

- Principios P1–P8: [`docs/constitution.md`](docs/constitution.md). Seguridad primero, dedupe sagrado, dominio puro, offline-first, exactitud fiscal, habeas data, escalar sin reescribir y spec-driven.
- Specs: [`docs/specs/`](docs/specs/). 003 arquitectura, 005 API, 008 app, 009 seguridad, 011 gastos fijos y push.
- Roadmap y estado de tareas: [`docs/roadmap/tasks.md`](docs/roadmap/tasks.md).
- Guías: [`backend/README.md`](backend/README.md) y [`app/README.md`](app/README.md).

## Flujo de trabajo

- **Spec primero (P8).** Un cambio de comportamiento actualiza su spec en el mismo commit. Si un spec contradice el código, se corrige ahí mismo.
- **Commits:** Conventional Commits con scope, en español y sin tildes. Por ejemplo, `feat(ledger): ...` o `fix(app): ...`. El cuerpo cita el ID de roadmap (`F4.1`) y termina con el trailer `Co-Authored-By`.
- **Solo se sube `main`**, por avance rápido. Nada de ramas remotas ni PRs. Antes de subir, correr lint y tests: GitHub ya no los corre.
- **Dependencias:** se actualizan a mano en `main`, respetando los pines de Flutter 3.35. Dependabot está desactivado (sin `dependabot.yml` ni alertas). La única auditoría automática es pip-audit (más gitleaks) en el gate del despliegue del backend.
- **TDD** en `domain/` y `application/`. Nada se da por hecho sin haber corrido el comando que lo prueba.

## Comandos (`justfile` en la raíz)

| Backend | App |
|---|---|
| `just up` / `just down`: Postgres 16 + Redis 7 | `just app-run`: `adb reverse tcp:8000 tcp:8000` + `flutter run` |
| `just dev`: API con recarga en `:8000` | `just app-gen`: build_runner + gen-l10n |
| `just worker`: worker arq | `just app-lint`: format + `flutter analyze --fatal-infos` |
| `just lint`: ruff, pyright, import-linter | `just app-test`: tests + cobertura domain/application ≥ 90 % |
| `just test`, `just coverage-domain` (≥ 90 %) | `just app-goldens`: regenerar goldens del login |
| `just migrate`, `just revision <nombre>` | `just app-icons`: PNG de los íconos desde `app/tool/brand/*.svg` |
| | `just app-ci` = lint + test |

GitHub Actions solo despliega: `.github/workflows/deploy-backend.yml` corre, en cada push a `main` que toca `backend/`, el gate (pip-audit + gitleaks), publica la imagen en GHCR y la levanta en el VPS con Docker Compose (`backend/deploy/README.md`). No hay CI de lint ni tests: `just lint`, `just test` y `just app-ci` se corren en local.

## Backend (`backend/`, Python 3.12, uv)

- **Arquitectura:** monolito modular hexagonal, `src/luka/{shared,modules/<m>/{domain,application,infrastructure}}`. Import-linter tiene 6 contratos: `shared` no importa módulos, y los cruces entre módulos pasan solo por `public.py`/`events.py`.
- **Dominio:** dataclasses frozen de stdlib; Pydantic solo en los bordes (API y settings).
- **Errores:** cada módulo define errores puros y un `EXCEPTION_MAP` en infra. El sobre de error de la API es `{"error":{"code","message","field?"}}`.
- **Tiempo y logs:** el tiempo siempre entra por `ClockPort`; nada de `datetime.now()` directo. Los logs son structlog.
- **Tests:** pytest con markers `unit`, `integration` y `ci`. Los dobles viven solo en `tests/`. El verificador de Google se inyecta con `create_test_app` (`tests/support/google_stub.py`, tokens `stub:<sub>:<email>`); la API no tiene modo simulado.

## App (`app/`, Flutter 3.35.7 / Dart 3.9)

- **Estructura:** feature-first + Clean Architecture: `lib/app` (router con session gate y `composition.dart`), `lib/core` y `lib/features/<f>/{domain,data,application,presentation}`.
- **Reglas de capas** (las verifica `test/architecture_test.dart`):
  - `domain` es Dart puro.
  - `application` no importa `data` ni `presentation`.
  - `presentation` no importa `data`.
  - `core` no importa features.
- **Estado:** Riverpod 3 **sin codegen** (`Notifier`/`AsyncNotifier` a mano). `riverpod_generator` no resuelve con Flutter 3.35. Los puertos de `application` son providers que se sobrescriben en `lib/app/composition.dart`.
- **Red:** **dio**, no `http`. El `AuthInterceptor` pone el Bearer y, ante `401 token_expired`, hace un refresh single-flight vía `SessionManager` y reintenta.
- **Modelos:** **json_serializable / freezed**, no `fromJson` a mano. La guía oficial de Flutter recomienda generación de código para proyectos medianos o grandes. El código generado se versiona y hay que regenerarlo (`just app-gen`) antes de subir.
- **Tests:** **mocktail**, no mockito. El doble de dio es `test/helpers/stub_backend.dart`. Los goldens (`tag golden`) no corren en `just app-test`.
- **Montos:** siempre en `Cop` (centavos `int`, `lib/core/format/money.dart`); nunca `double`. `formatCop` da `$1.234.567`, y el gasto usa U+2212.
- **UI:**
  - Textos solo en `lib/core/l10n/arb/app_es.arb`.
  - Colores, tipografía y espaciado desde `lib/core/theme` (sistema "Rojo tomate", spec 008 §7.1).
  - Contraste AA y áreas táctiles de 48 dp o más.
- **Versiones fijadas** por el analyzer 7 de Flutter 3.35: freezed <3.2, json_serializable <6.11, drift 2.28, build_runner <2.8. No subirlas sin actualizar Flutter.

## Configuración mínima

- **Nada simulado:** no hay modos ni entornos "fake". En desarrollo se usa la integración real; los dobles solo en tests.
- **Variables de entorno:** no añadir las que repitan un default.
  - `backend/.env.example` trae solo las obligatorias: DB, Redis, `JWT_SECRET`, los secretos de Google/Gmail y la configuración del proyecto GCP.
  - Lo que depende del proyecto GCP (client IDs web e iOS, topic y push de Pub/Sub) nunca tiene default en el backend: se declara en el `.env` de cada entorno.
  - La app solo acepta `API_BASE_URL` y `GOOGLE_SERVER_CLIENT_ID`, y ambas tienen default de desarrollo. `flutter run` funciona sin flags.
- **Google Sign-In:** proyecto GCP `luka-510204`. El client ID web es la audiencia del `id_token` en Android y el cliente del `serverAuthCode`; en iOS la audiencia es el cliente iOS, y el backend acepta ambos. En iOS los client IDs salen de `ios/Flutter/GoogleSignIn.xcconfig` (un test verifica que el web coincida con el default de Dart). Si cambia la máquina o el keystore, hay que agregar su SHA-1 al cliente Android.

## Seguridad (P1, spec 009)

- **Tokens:** solo en `flutter_secure_storage`, nunca en SharedPreferences.
- **Logs:** nunca montos, comercios, emails, tokens ni cuerpos de mensajes; en la ruta se loguea la plantilla, no el path crudo. Aplica al backend (hay test, `tests/ci/test_log_hygiene.py`) y al `LogInterceptor` de dio.
- **Secretos:** `.env` y `.env.*` están ignorados en todo el repo, salvo `.env.example`.

## Skills y MCP de Dart/Flutter

- **Plugin oficial:** `dart-flutter@dart-flutter`, instalado a nivel usuario. Trae las skills `flutter-*` y `dart-*` y el MCP `dart mcp-server`, que da diagnósticos del analyzer, tests e inspección de la app en ejecución.
- **Excepciones en este repo:**
  - `flutter-use-http-package`: usamos dio.
  - `flutter-implement-json-serialization`: usamos json_serializable.
  - `dart-generate-test-mocks`: usamos mocktail.
- **Hot reload** (regla oficial), con la app corriendo por `flutter run`:
  - Cambios de UI en `lib/`: hot reload.
  - Cambios en estado inicial, providers globales o `main()`: hot restart.
  - Cambios en `--dart-define` o en código nativo: relanzar.
  - Cambios en `test/` o en docs: no hace falta nada.
