# Spec 005 — Contrato de API

## 1. Convenciones

- Base: `https://api.luka.app/v1` (versionado por prefijo de ruta).
- Autenticación: `Authorization: Bearer <access_jwt>` en todo endpoint salvo los marcados **público**.
- Formato: JSON UTF-8; fechas ISO 8601 con zona (`2026-08-05T14:30:00-05:00`); montos como string decimal (`"152300.00"`) para evitar errores de flotante.
- Paginación: cursor — `?limit=50&cursor=<opaque>`; respuesta `{ "items": [...], "next_cursor": "..." | null }`.
- Errores (RFC 7807 simplificado):

```json
{ "error": { "code": "validation_error", "message": "amount must be positive", "field": "amount" } }
```

`field` y `reason` son opcionales y se omiten cuando no aplican. `reason` es un código estable (snake_case) que afina `code` cuando el cliente necesita distinguir casos con el mismo `code` y `field`; hoy solo lo llevan los 400 de `POST /gmail/connect` (§3). El cliente decide por `code`/`reason`, nunca por el texto de `message`.

| HTTP | code | Cuándo |
|---|---|---|
| 400 | `validation_error` | entrada inválida; reemplaza el 422 por defecto de FastAPI. `field` es el `loc` del error sin el prefijo `body`/`query`/`path` |
| 401 | `unauthorized` / `token_expired` | sin token o vencido |
| 403 | `forbidden` | acción no permitida sobre un recurso propio o visible (p. ej. modificar/borrar una categoría del sistema, o borrar una transacción no manual). **Nunca** para un recurso ajeno: ver 404 |
| 404 | `not_found` | recurso inexistente **o de otro usuario** (spec 009 §4: no se distingue para no filtrar existencia) |
| 409 | `conflict` | p. ej. cuenta duplicada |
| 429 | `rate_limited` | header `Retry-After` |
| 500 | `internal` | sin detalles internos |
| 503 | `upstream_unavailable` | un servicio externo (Google) falló de forma transitoria (timeout, 5xx, 429); el cliente puede reintentar |

- Idempotencia en mutaciones de la app: header `Idempotency-Key: <uuid>`, solo en `POST` (el outbox offline reintenta sin duplicar). Clave en Redis: `(user_id, key)`, TTL 24 h. La misma clave con el mismo cuerpo (hash) reproduce la respuesta original (status, `content-type`, body) agregando `Idempotency-Replayed: true`; la misma clave con un cuerpo distinto responde 409 `conflict` (conflicto real, sin `Retry-After`); mientras la primera solicitud con esa clave sigue en vuelo (candado de 30 s), responde 409 `conflict` con `Retry-After: 1` y el cliente reintenta con la misma key. Solo se persisten respuestas con status < 500.
- Paginación por cursor: el cursor es opaco (`base64url(json)`); orden por defecto `(occurred_at DESC, id DESC)`; con `updated_since`, orden `(updated_at ASC, id ASC)`. `limit` entre 1 y 200 (default 50). Un cursor inválido, vencido o del orden equivocado responde 400 `validation_error` con `field: "cursor"`.
- `GET /health` y `GET /health/ready` son públicos, no llevan el prefijo `/v1` y están exentos de rate limiting.

## 2. Auth (módulo identity)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/google` **público** | Body `{ "id_token": "...", "device_info?" }` (`device_info` opcional, ≤200 caracteres) → verifica firma/audiencia con Google, crea o encuentra usuario. `email_verified=false` → 401 `unauthorized`. Respuesta: `{ access_token, refresh_token, expires_in, user }` |
| POST | `/auth/refresh` **público** | Body `{ "refresh_token", "device_info?" }` (mismo límite) → rota el refresh (familia) y emite nuevo par. Refresh vencido, revocado, reusado o desconocido → 401 `unauthorized` genérico (no se distingue el motivo); `token_expired` es exclusivo del access JWT |
| POST | `/auth/logout` | Body `{ "refresh_token" }` → revoca ese refresh token. Responde 204 siempre, exista o no el token |
| GET | `/me` | Perfil + `consents` + `connections`: `{ "gmail": "active" \| "revoked" \| "error" \| "none", "notifications": "none" \| "granted" }`. `gmail` es el estado guardado de la conexión (ingestion, leído por su fachada pública) o `none` si el usuario no conectó Gmail |
| DELETE | `/me` | Borra la cuenta al instante (RF-11.3, F4.8b), en este orden: desconecta Gmail (para el watch y revoca el grant en Google, best effort), revoca todos los refresh tokens y borra el usuario. El `ON DELETE CASCADE` se lleva movimientos, fuentes, correos guardados, cuentas, categorías propias, reglas y revisión. Queda en auditoría (`account_deleted`, sin PII) y publica `identity.UserDeleted`. Responde 204. El access JWT vigente sigue firmado hasta vencer (≤ 15 min), pero ya no hay usuario: `/me` y un segundo `DELETE` dan 401. La verificación ≤ 72 h y la web de borrado quedan para F6.4/F6.5 |
| GET | `/me/export` | Exportación síncrona en JSON (RF-11.2, F4.8b), con `Content-Disposition: attachment; filename="luka-export.json"`. Contiene `format_version` (1), `exported_at`, `profile` (email, nombre, alta), `accounts`, `categories` (solo las propias), `transactions` (con nombre de categoría y `sources`: canal y fecha, nunca el cuerpo del mensaje), `merchant_rules`, `review_items` (motivo y resolución) y `gmail.status`. Queda en auditoría (`data_exported`). El Excel y el job asíncrono con `job_id` quedan para F6.4 |

## 3. Conexión Gmail (ingestion)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/gmail/connect` | Body `{ "server_auth_code": "..." }` (código de autorización incremental obtenido en la app, 1–2048 caracteres) → el backend lo canjea por refresh token, lo cifra (AES-GCM atado al `user_id`, spec 009 §3), crea el watch y guarda la conexión. Respuesta 200 `{ status, email, watch_expires_at }`. AC-1.2 |
| DELETE | `/gmail/connect` | Detiene el watch y revoca el token en Google (best effort) y borra la conexión; las transacciones no se tocan. 204 siempre, exista o no la conexión (AC-11.1) |
| GET | `/gmail/status` | 200 `{ status, email, last_sync_at, watch_expires_at }` |

Todas las rutas exigen el Bearer y operan solo sobre la conexión del usuario del token. Ninguna respuesta incluye el refresh token.

- `status`: `active` / `revoked` / `error` (estado guardado, spec 004 §2.3) o `disconnected` si el usuario no tiene conexión; en ese caso `email`, `last_sync_at` y `watch_expires_at` son `null`.
- `email` es la cuenta Gmail conectada, que puede diferir del email del usuario.
- Reconectar (`POST` con conexión previa) reemplaza token, email y watch, y conserva `created_at`. Si la conexión previa era de **otra** cuenta Gmail, antes de reemplazarla se detiene su watch y se revoca su grant (best effort) y el cursor arranca de cero; con la misma cuenta no se revoca nada, porque Google revoca el grant completo y mataría también el token recién emitido, y se conserva el cursor (`history_id`) previo si lo había (el próximo sync sigue desde ahí; si venció, cae al resync de 7 días, spec 006 §2.1).
- `error` es recuperable: el cron diario de renovación (spec 006 §2.1) reintenta el watch de toda conexión `error` sin watch o con el watch por vencer y, si sale bien, la deja `active`. Un fallo transitorio en la renovación no cambia el estado. `revoked` solo se recupera reconectando.
- `DELETE` borra la fila solo si sigue siendo de la cuenta que leyó: un `POST` concurrente que reconectó con otra cuenta no se borra.
- Dos usuarios de luka sobre la **misma** cuenta Gmail comparten el grant de Google (es por par cuenta de Google–cliente OAuth, no por usuario de luka): cuando uno desconecta (o reconecta con otra cuenta), el `revoke` invalida también el token del otro, cuya conexión pasa a `revoked` en su próximo sync o renovación y tiene que reconectar. Es un caso raro y se acepta así en el MVP.
- Ninguna ruta espera a Google con una transacción de base de datos abierta: la conexión se lee, la transacción se cierra, se llama a Google y la escritura final corre en una transacción nueva.

```json
{ "status": "active", "email": "ana@gmail.com", "watch_expires_at": "2026-05-08T12:00:00Z" }
```

Errores de `POST /gmail/connect`:

| Caso | Respuesta |
|---|---|
| Código inválido, vencido o ya usado (`invalid_grant`) | 400 `validation_error`, `field: "server_auth_code"`, `reason: "invalid_code"`. No se guarda nada |
| Google no entregó refresh token (la app no pidió acceso offline o no forzó el consentimiento) | 400 `validation_error`, `field: "server_auth_code"`, `reason: "refresh_token_missing"`, con un mensaje que lo indica. No se guarda nada |
| El usuario no concedió `gmail.readonly` en el consentimiento (el `scope` del grant no lo trae) | 400 `validation_error`, `field: "server_auth_code"`, `reason: "scope_not_granted"`, mensaje "permiso de Gmail no concedido". El grant recién emitido se revoca (best effort) solo si el usuario no tiene una conexión `active`: Google revoca el grant completo y mataría esa conexión. No se guarda nada |
| `users.getProfile` responde 403 con el scope concedido (cuota, `accessNotConfigured`) | 503 `upstream_unavailable`; no se revoca nada ni se guarda nada |
| Google caído en el canje (timeout, 5xx, 429) | 503 `upstream_unavailable`. No se guarda nada |
| El canje salió bien pero `watch` falló (transitorio o rechazo) | 200 con `status: "error"` y `watch_expires_at: null`: la conexión (con el token cifrado) queda guardada, porque el código ya se consumió y no se puede volver a canjear. El cron diario de renovación la toma (es `error` sin watch), reintenta el watch y, si sale bien, la deja `active`; una reconexión también la recupera. Si Google revocó el token recién emitido, `status: "revoked"` |

## 4. Webhook Pub/Sub (ingestion) — **público con OIDC**

`POST /webhooks/gmail`

- Autenticación: token OIDC de Google en `Authorization: Bearer` (no el access JWT de la app). Se verifica con `google.oauth2.id_token.verify_token` (firma y `exp`) contra `aud = gmail_push_audience`, más `iss` de Google (`accounts.google.com` o `https://accounts.google.com`), `email == gmail_push_service_account` y `email_verified = true`. El token se verifica **antes** de leer el cuerpo.
- Exenta del rate limit por usuario y de `Idempotency-Key` (prefijo `/v1/webhooks/`): la autentica su propio token.
- Body: envelope estándar de Pub/Sub; `message.data` (base64) contiene `{ emailAddress, historyId }`.
- Comportamiento: resolver las conexiones `active` de esa cuenta Gmail (índice por `email`) → encolar un job arq `sync_gmail(user_id, history_id)` por cada una → responder 204 **antes** de sincronizar o parsear (todo es asíncrono, spec 006 §2.1).

| Caso | Respuesta |
|---|---|
| Aviso válido | 204, jobs encolados |
| Cuenta desconocida o conexión `revoked`/`error` | 204 sin encolar (Pub/Sub no reintenta) |
| Sin token, token ilegible, firma inválida, vencido, otra audiencia, otro service account o email sin verificar | 403 `forbidden` (no se distingue el motivo) |
| Envelope malformado (no JSON, sin `message.data`, base64 o JSON inválido, sin `emailAddress`/`historyId`) | 204 sin encolar y un warning `gmail_push_ignored`. No 400: el token ya probó que viene de nuestra suscripción y Pub/Sub reintenta todo lo que no sea 2xx hasta que vence la retención (7 días); reintentar no arregla un cuerpo ilegible |
| Redis caído al encolar | 503 `upstream_unavailable` para que Pub/Sub reintente |

Logs: solo `gmail_push_received` con `jobs_enqueued`; nunca el `emailAddress` ni el token.

## 5. Ingesta desde el dispositivo (ingestion)

`POST /ingest/notifications` — batch de notificaciones capturadas en Android (RF-3):

```json
{
  "items": [
    {
      "package": "com.bancolombia.app",
      "channel": "notification",           // o "sms_notification"
      "posted_at": "2026-08-05T14:30:00-05:00",
      "title": "Compra aprobada",
      "text": "Compraste $45.900 en RAPPI con tu tarjeta *1234",
      "client_hash": "sha256..."           // idempotencia (external_id)
    }
  ]
}
```

- Respuesta (enmendado, Task 5/F4.3): `{ "accepted": 2, "duplicates": 0, "discarded": 1 }`. `discarded` cuenta los items cuyo paquete/remitente no está en la lista soportada tras la re-validación server-side (AC-3.3); esos items nunca se persisten.
- Límites (spec 009 §4): 1–50 items por batch; `text` ≤ 64 KB; `title` ≤ 500 caracteres; `client_hash` = sha256 hex en minúsculas, usado como `external_id` de la idempotencia por índice `UNIQUE(user_id, channel, external_id)`. `posted_at` debe incluir zona horaria (naive → 400). Cap duro de 1 MB por request (documentado en 009 §4, ruling del controlador).
- `Idempotency-Key` es opcional pero soportado (spec 009 §1): reintentar la misma request con la misma clave replica la respuesta original (`Idempotency-Replayed: true`) sin re-ejecutar el batch. Sin ese header, el batch ya es idempotente por índice (`client_hash`), así que reintentar el mismo batch entero también es seguro.
- Paquetes/remitentes se re-validan en el servidor (AC-3.3): un item con paquete no soportado se descarta sin persistir, aunque el cliente lo haya enviado igual (nada se loguea de su contenido, P1/P8).
- Rate limit específico (spec 009 §4, regla `ingest_user`): 60/min por usuario, además de la regla global de usuario.

`GET /config/capture` (autenticado, Task 5/F4.3) — config remota de captura para el cliente Android (spec 006 §3.1):

```json
{
  "version": 1,
  "banking_apps": ["com.bancolombia.app", "..."],
  "messages_apps": ["com.google.android.apps.messaging", "..."],
  "sms_sender_patterns": ["(?i)bancolombia", "..."],
  "email_senders": { "bancolombia": ["alertasynotificaciones@an.notificacionesbancolombia.com", "..."] }
}
```

- Header `Cache-Control: private, max-age=3600` (excepción documentada a `no-store`: el payload no contiene datos de usuario).

## 6. Transacciones (ledger)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/transactions` | Filtros: `from`, `to`, `kind`, `category_id`, `bank`, `account_id`, `channel`, `q` (texto), `updated_since` (sync). Paginado; los ítems no incluyen `sources` ni `pair` (ver `GET /transactions/{id}`), pero sí `channels[]`: valores únicos de `Channel` de sus fuentes, en el orden estable del enum (`email`, `notification`, `sms_notification`, `manual`, `nfc`); `[]` si no tiene fuentes. Una sola consulta agrupada arma `channels` de toda la página (sin N+1) |
| POST | `/transactions` | Registro manual/NFC. Body: monto, dirección, fecha, comercio, categoría, cuenta opcional, `nfc_tag_id` opcional (marca la fuente con `channel: "nfc"`; el identificador en sí no se persiste) |
| GET | `/transactions/{id}` | Incluye `sources[]` (AC-9.3) y transacción emparejada si es transfer |
| PATCH | `/transactions/{id}` | Editables: `category_id` (dispara merchant_rule si el comercio no está vacío, AC-7.2; `learn_merchant_rule: bool = true` para omitirlo), `notes`, `merchant`, `kind` transfer↔original (AC-6.3/6.4) |
| DELETE | `/transactions/{id}` | Solo transacciones manuales (`parsed_by = "manual"`); sobre una capturada automáticamente → 403 |
| POST | `/transactions/{id}/transfer-pair` | Body `{ "pair_id" }` — emparejar manualmente. Ambas deben ser propias (si no, 404) y de dirección opuesta; si alguna ya está emparejada → 409. No exige monto igual. Queda `transfer_auto: false` |
| DELETE | `/transactions/{id}/transfer-pair` | Desemparejar (registra exclusión mutua que solo bloquea el emparejador automático; un nuevo `transfer-pair` manual entre las mismas dos sigue funcionando) |

## 7. Categorías, cuentas, revisión

| Método | Ruta | Descripción |
|---|---|---|
| GET/POST | `/categories` · PATCH/DELETE `/categories/{id}` | Sistema + propias; las del sistema no se modifican ni se borran (403). Nombre duplicado → 409 `field=name`: se compara sin distinguir mayúsculas contra las propias y las del sistema (renombrar la misma categoría cambiando solo mayúsculas sí se permite). Ajena → 404, también como `category_id` de `POST/PATCH /transactions`. `PATCH` con un `fiscal_tag` distinto lo propaga a las transacciones de la categoría (salvo transferencias, que siguen en `transferencia`) y les toca `updated_at`, para que el pull incremental las traiga. `DELETE` de una propia reasigna sus transacciones a `sin_categoria` (también tocando `updated_at`) y borra las `merchant_rules` que apuntaban a ella |
| GET/POST | `/accounts` · PATCH/DELETE `/accounts/{id}` | Cuentas vinculadas (RF-6). `(bank, last4)` duplicado para el usuario → 409. `DELETE` dejar `account_id` en `NULL` en sus transacciones (`ON DELETE SET NULL`) |
| GET | `/review` | Cola de revisión con `partial_extract` |
| POST | `/review/{raw_message_id}/convert` | Body = transacción completa → crea transacción `parsed_by: manual` y marca resuelto |
| POST | `/review/{raw_message_id}/discard` | Descarta |

**Detalle de `/review` (Task 8, F2.5/F2.6, dueño: ledger — ver spec 004 §2.10, spec 003 §2.3).** Un mensaje crudo que `parsing` no pudo convertir en transacción (`ParseFailed`) queda en la cola; el usuario lo resuelve convirtiéndolo a mano o descartándolo. Ambas acciones marcan el `raw_message` subyacente (`reviewed`/`discarded`, vía `ingestion.public`).

- `GET /review` — paginado por cursor (spec 005 §1; cursor kind `review`, orden `(created_at DESC, raw_message_id DESC)`). `limit`/`cursor` igual que `/transactions`. Respuesta:

  ```json
  { "items": [ {
      "raw_message_id": "uuid", "channel": "email", "bank": "bancolombia" ,
      "sender": "alertasynotificaciones@an.notificacionesbancolombia.com",
      "received_at": "2026-09-19T21:52:00-05:00",
      "reason": "llm_low_confidence",
      "partial_extract": { "amount": "45900" },
      "text": "Bancolombia: Compraste $45.900 en ...", "created_at": "2026-09-19T21:53:10Z"
    } ], "next_cursor": "..." | null }
  ```

  `reason` es uno de los 8 valores cerrados (`no_template`, `llm_disabled`, `llm_budget_exceeded`, `llm_invalid_json`, `llm_invalid_output`, `llm_low_confidence`, `llm_error`, `body_purged`); `text` es el cuerpo del mensaje (`null` si ya fue purgado, spec 004 §2.7). Solo lista items propios y abiertos (sin resolver); un item ajeno nunca aparece (no hay 404 en el listado: es un filtro, no una búsqueda por id).

- `POST /review/{raw_message_id}/convert` — body idéntico a `CreateTransactionRequest` (spec 005 §6) salvo que no acepta `nfc_tag_id` (la fuente siempre es el `raw_message`, no NFC). Crea la transacción con `parsed_by: "manual"` y una fuente (`sources[0]`) con `raw_message_id` = el del mensaje crudo, `channel` = el canal original del mensaje (no `manual`). Respuesta **201** `TransactionResponse` (mismo shape que `POST /transactions`, spec 005 §9.3). Errores: **404** `not_found` si el item no existe o es de otro usuario (009 §4/§8); **409** `conflict` si ya fue convertido o descartado.
- `POST /review/{raw_message_id}/discard` — sin body. Resuelve el item sin crear transacción. Respuesta **200**:

  ```json
  { "raw_message_id": "uuid", "resolution": "discarded", "resolved_at": "2026-09-19T22:00:00Z" }
  ```

  Mismos errores que `convert` (**404**/**409**).

- **Reproceso (`reparsed`).** Cuando llega una plantilla nueva o un arreglo del parser, `just reparse [--since AAAA-MM-DD]` (`uv run python -m luka.tools.reparse`, flags opcionales `--user <uuid>` y `--limit <n>`, 500 por defecto) devuelve al pipeline los `raw_messages` `failed` que aún tienen cuerpo; los purgados (`body IS NULL`, spec 004 §6) se saltan. `--since` es una fecha de Colombia sobre `received_at`. Cada fila pasa `failed → pending` con un UPDATE condicional (si el usuario la convirtió o descartó entretanto, no se toca), con `requeue_attempts = 0`, y se republica su `RawMessageReceived` después del commit (spec 006 §4.4). Si ahora parsea, ledger registra la transacción y, en la misma unidad de trabajo, cierra el item abierto con `resolution: "reparsed"`; si el usuario ya lo `converted`/`discarded` mientras el mensaje seguía en el pipeline, ledger no registra nada (no hay segunda transacción), el item conserva su resolución y el evento queda atendido sin reintento (spec 006 §4.4). Si vuelve a fallar, el `event_id` determinista de `ParseFailed` y el `ON CONFLICT DO NOTHING` de la cola dejan el mismo item abierto, sin duplicarlo. La app deja de ver el item en el siguiente `GET /review`, que solo lista abiertos. El CLI arma la misma composición que el worker (settings, engine, Redis y grupos de consumidores) y solo imprime `reparsed=<n>`. Necesita el worker en marcha para que se consuman los eventos. Correrlo dos veces no duplica nada: la segunda corrida ya no encuentra esas filas en `failed`.

## 8. Insights y reporte fiscal

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/insights/monthly?year=2026&month=8` | Totales, por categoría, comparativa mes anterior (AC-9.1). Excluye transfers. **Diferido:** la app calcula el dashboard en local sobre Drift (008 §3.2), y el endpoint queda para un segundo cliente (web) |
| GET | `/fiscal/report?tax_year=2025` | Reporte por cédulas/renglones (spec 007) + `rules_version` + trazabilidad (`transaction_ids` por cifra) |
| GET | `/fiscal/report.xlsx?tax_year=2025` | Excel (job async si >5 s; respuesta 202 + job) |
| GET | `/fiscal/thresholds?tax_year=2025` | Topes de obligación de declarar en UVT y COP (AC-10.2) |

## 9. Contrato de sincronización offline (app)

Cada ciclo va **push antes que pull**, para que el pull traiga ya el estado que el servidor confirmó en el push.

1. **Pull**: `GET /transactions?updated_since=<cursor>` es incremental — filtra `updated_at >= cursor`, por lo que es idempotente ante reintentos — y el cursor avanza al mayor `updated_at` recibido (primer pull: época `1970-01-01`). La app pide `updated_since = cursor − 5 min` (sin bajar de la época): una fila que commitea tarde con un `updated_at` anterior al cursor no se pierde, y repetir filas es inocuo por el `>=` y el upsert idempotente. Categorías, cuentas y revisión no tienen cursor: cada sync trae la lista completa (`GET /categories`, `/accounts`, `/review`) y reemplaza la copia local entera. Adjuntar una fuente nueva a una transacción ya existente (misma captura vista por otro canal, AC-5.1) actualiza su `updated_at` (solo esa columna, para no pisar un cambio concurrente de la fila), así que el pull incremental la vuelve a traer — con su `channels[]` ya actualizado — sin que la app tenga que pedir el detalle.
2. **Push**: la app drena su `outbox` FIFO contra los endpoints normales. Solo los `POST` (creaciones) llevan `Idempotency-Key`, y un reintento repite el mismo cuerpo. El outbox se relee antes de cada operación, así que las siguientes ya llevan el id del servidor que dejó el canje de una creación y no se envía lo que el usuario canceló durante el ciclo. Cada envío se cuenta (`attempts`) **antes** de salir: borrar una creación la cancela en local solo si nunca se envió; si ya se envió (aunque siga en vuelo o la app muriera durante el request), el servidor pudo haberla guardado y el borrado se encola detrás. Según la respuesta:
   - Red caída, `5xx`, `429` o `409` con `Retry-After` (spec 005 §1) → se reintenta más tarde; el drenado se detiene ahí, sin saltar al siguiente ítem.
   - `401` → termina el ciclo (sesión cerrada).
   - `404` al borrar y `409` al descartar una revisión → cuentan como hechos (el efecto ya existía o ya no aplica).
   - `409` o `404` al convertir una revisión (resuelta en otro dispositivo, vencida o ya convertida por un intento cuya respuesta se perdió) → cuenta como hecho: la app quita la fila optimista con id local, y sus operaciones dependientes, y el pull trae la copia real si existe. Si esa fila era pareja de otra, la otra pierde la pareja y, si quedó como `transfer`, vuelve al tipo según su dirección (lo mismo al cancelar en local una creación nunca enviada).
   - Cualquier otro `4xx` → el ítem queda `rejected` (resolución manual); si era una creación, las operaciones que dependen de su id (p. ej. marcar transfer) también quedan `rejected` sin intentarse. Una operación `rejected` se conserva en el outbox para verla y resolverla a mano (F4.2/F4.8), pero no cuenta como pendiente ni bloquea el pull de sus filas. Si era un patch, emparejar, desemparejar o borrar, la app pide `GET /transactions/{id}` de las transacciones que tocó (objetivo y pareja, salvo ids de creaciones rechazadas; al desemparejar, la pareja es la que el servidor conserva) y deja la copia local como la tiene el servidor, o la borra si responde `404` (las filas locales que la tenían de pareja la pierden y, si eran transferencia, vuelven a gasto o ingreso según su dirección); si la consulta falla, la fila queda con el efecto optimista y el ciclo sigue. Una creación o conversión rechazada deja su fila local como está (es dato del usuario). La resolución manual actúa sobre las operaciones `rejected` que tocan una transacción (como objetivo o como pareja): **reintentar** las devuelve a `pending` en su orden, vuelve a aplicar en local su efecto optimista (la fila muestra otra vez lo que se reintenta; una creación o conversión no se reinserta, porque su fila nunca se quitó) y dispara un ciclo (un borrado confirmado, `204` o `404`, quita la fila local aunque el rechazo la hubiera restaurado); **descartar** las borra, quita en local la fila de una creación descartada y restaura las demás filas con la misma regla de `GET /transactions/{id}` (sin red quedan como están).
3. El servidor nunca asume que la app está al día: toda respuesta de mutación devuelve el recurso completo actualizado (excepto los `204` sin cuerpo, como `DELETE /accounts/{id}` o `logout`, donde no aplica).
4. **Deuda conocida**: los borrados hechos desde otro dispositivo u otro cliente no se propagan al pull — Postgres borra en duro y no hay tombstones —, así que una copia local que no vio ese borrado directo puede seguir mostrando la fila hasta que la toque ella misma.
5. **Deuda conocida**: la `Idempotency-Key` dura 24 h en Redis (§1). Una creación que llegó al servidor pero cuya respuesta se perdió, y que se reintenta después de más de 24 h (p. ej. el teléfono quedó sin red), crea un duplicado en el servidor. A futuro, el servidor debería deduplicar por el id que genera el cliente (el UUID local de la creación) en vez de depender solo del TTL.
