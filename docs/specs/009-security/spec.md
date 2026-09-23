# Spec 009 — Seguridad

Aplica P1. Referencia de verificación: OWASP ASVS 4.0 nivel 2 (además exigido por CASA, spec 010).

## 1. Modelo de amenazas (STRIDE resumido)

| Activo | Amenaza principal | Mitigación |
|---|---|---|
| Refresh tokens de Gmail | Robo de DB → acceso al correo de usuarios | Cifrado en reposo AES-GCM con clave fuera de la DB; scope solo lectura; revocación en cascada al detectar incidente |
| Sesiones de usuarios | Robo/replay de JWT | Access token ≤ 15 min; refresh rotativo con detección de reuso por familia; revocación server-side |
| Contenido de correos/notifs | Exfiltración / lectura interna | Retención 90 días, cifrado de disco del VPS, logs sin contenido, acceso a prod restringido |
| Endpoint de ingesta | Inyección de transacciones falsas (spoofing) | JWT del usuario + re-validación server-side de paquetes soportados + rate limit |
| Webhook Pub/Sub | Llamadas falsificadas | Verificación OIDC (issuer Google, audience exacta, service account esperada) |
| API pública | Credential stuffing / brute force / DoS | Solo Google Sign-In (sin contraseñas propias), rate limiting por IP y usuario, Caddy con límites de tamaño |
| LLM (DeepSeek) | Fuga de PII a terceros | Se envía solo el **extracto** del mensaje bancario (`relevant_line_prefix`/fallback, spec 006 §4.1) y la fecha de recepción — nunca el cuerpo completo, email del usuario, remitente ni identificadores internos (`user_id`/`raw_message_id`, spec 006 §4.2); DPA del proveedor documentado en spec 010 |
| App móvil | Extracción de secretos del APK | La app no contiene secretos: solo client_id público de OAuth; el canje de tokens ocurre en el backend |
| Dependencias | Supply chain | pip-audit/osv-scanner + lockfiles (uv.lock, pubspec.lock) (sin Dependabot: las actualizaciones se hacen a mano en `main`; pip-audit corre en el CI del backend, la app aún no tiene auditoría automática) |

## 2. Autenticación y sesiones

### 2.1 Flujo Google Sign-In
1. App obtiene `id_token` (y `serverAuthCode` si el usuario aceptó Gmail).
2. `POST /auth/google`: backend verifica el `id_token` contra las claves públicas de Google (firma, `aud` = client_id propio, `iss`, `exp`) usando la librería oficial. Nunca se confía en datos del cliente sin verificar.
3. Usuario creado/encontrado por `google_sub` (no por email, que puede cambiar).

### 2.2 Tokens propios
- **Access JWT**: HS256/EdDSA con clave de servidor, TTL 15 min, claims mínimos (`sub`, `exp`, `iat`, `jti`). Sin datos personales en el payload.
- **Refresh token**: opaco (256 bits aleatorios), almacenado como SHA-256, TTL 60 días deslizante, **rotación en cada uso** con `family_id`: si se presenta un token ya rotado (reuso → posible robo), se revoca la familia completa y se exige re-login (AC-1.4).
- Logout revoca el refresh actual; borrado de cuenta revoca todos.
- Almacenamiento en la app: `flutter_secure_storage` (Keystore/Keychain), nunca SharedPreferences.

## 3. Cifrado

| Dato | Mecanismo |
|---|---|
| Tránsito | TLS 1.2+ obligatorio (Caddy, HSTS); certificados automáticos Let's Encrypt |
| Gmail refresh tokens | AES-256-GCM; clave maestra `FINANZIA_KMS_KEY` solo en env del servidor (secret del compose); rotación de clave soportada (guardar `key_version` junto al ciphertext) |
| Backups | `pg_dump` cifrado con age (clave pública; privada fuera del VPS); retención 30 días |
| Contraseñas | N/A — no existen contraseñas propias (ADR-8) |

## 4. Protección de la API

- **Rate limiting** (Redis, sliding window): `/auth/*` 10/min por IP; `/ingest/notifications` 60/min por usuario; global 600/min por usuario; respuesta 429 + `Retry-After`. La IP se toma de `request.client.host`, salvo que `FINANZIA_TRUST_PROXY_HEADERS=true` (Caddy en producción), en cuyo caso se usa el último valor de `X-Forwarded-For` (el añadido por el proxy de confianza; los valores a la izquierda los controla el cliente). `/health*` está exento. Si Redis no responde, el limitador falla abierto y registra una advertencia (decisión MVP: disponibilidad sobre límite). Implementación (Task 5/F4.3): regla `ingest_user` (`/v1/ingest/` por usuario) en la lista de reglas de `RateLimitMiddleware`, evaluada ANTES que la regla global `user_global` (el orden importa: la primera regla que rechaza responde 429); un `POST /v1/ingest/notifications` matchea ambas reglas y consume cupo de las dos.
- **Validación**: Pydantic estricto en todo input; límites de tamaño de body (1 MB general, 64 KB por notificación); listas de enums cerradas (bancos, canales).
- **Cabeceras**: HSTS, `X-Content-Type-Options: nosniff`, CSP restrictiva en cualquier página servida.
- **CORS**: cerrado (la app móvil no lo necesita); si hay web futura, allowlist explícita.
- **Autorización**: toda query filtra por `user_id` del token en la capa repositorio (imposible acceder a recursos ajenos → 404, no 403, para no filtrar existencia).
- **Idempotency-Key**: almacenada 24 h en Redis; replay devuelve la respuesta original. Solo se guarda el cuerpo de la respuesta si pesa ≤ 256 KiB (uno mayor no se persiste y la siguiente solicitud con la misma clave se re-ejecuta); si Redis no responde, el middleware falla abierto (deja pasar la solicitud sin deduplicar) y registra una advertencia, igual que el rate limiter.

## 5. Logging y monitoreo

- Logs estructurados JSON (structlog): request_id, user_id (UUID interno), ruta, latencia, resultado. La `ruta` registrada es siempre la **plantilla** de la ruta (p. ej. `/v1/transactions/{id}`), nunca el path crudo ni el query string, para no filtrar identificadores ni parámetros de búsqueda a los logs. **Prohibido**: cuerpos de mensajes, montos, comercios, emails, tokens (P1). Test de CI que greppea patrones prohibidos en llamadas de log.
- Auditoría de eventos sensibles: login, refresh reuse detectado, conexión/desconexión Gmail, exportación, borrado de cuenta.
- Alertas mínimas MVP: tasa de 5xx, backlog de colas, fallos de renovación de watch, presupuesto LLM global.

## 6. Seguridad del VPS

- SSH solo con llave + fail2ban; firewall: 80/443 únicamente expuestos.
- Contenedores no-root, `read_only` donde aplique, sin privilegios; Postgres y Redis solo en red interna de Docker (no expuestos).
- Actualizaciones de seguridad automáticas del SO (unattended-upgrades).
- Disco cifrado (LUKS) si el proveedor lo permite.

## 7. Seguridad en la app

- Certificate pinning opcional post-MVP; mínimo: TLS estricto sin `badCertificateCallback`.
- El texto de notificaciones no soportadas nunca se persiste ni transmite (spec 006 §3.2).
- Sin analytics de terceros que reciban contenido financiero en MVP.
- Ofuscación de release (`--obfuscate --split-debug-info`).

## 8. Checklist de release (gate de CI/CD)

- [ ] gitleaks sin hallazgos (0 secretos en repo).
- [ ] pip-audit / osv-scanner sin vulnerabilidades críticas/altas sin justificar.
- [ ] Tests de authz (acceso cruzado entre usuarios → 404) verdes.
- [ ] Test de reuso de refresh token verde.
- [ ] Test de verificación OIDC del webhook verde.
- [ ] Revisión manual de nuevos endpoints contra §4.
