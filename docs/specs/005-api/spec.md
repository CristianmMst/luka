# Spec 005 — Contrato de API

## 1. Convenciones

- Base: `https://api.finanzia.app/v1` (versionado por prefijo de ruta).
- Autenticación: `Authorization: Bearer <access_jwt>` en todo endpoint salvo los marcados **público**.
- Formato: JSON UTF-8; fechas ISO 8601 con zona (`2026-08-05T14:30:00-05:00`); montos como string decimal (`"152300.00"`) para evitar errores de flotante.
- Paginación: cursor — `?limit=50&cursor=<opaque>`; respuesta `{ "items": [...], "next_cursor": "..." | null }`.
- Errores (RFC 7807 simplificado):

```json
{ "error": { "code": "validation_error", "message": "amount must be positive", "field": "amount" } }
```

| HTTP | code | Cuándo |
|---|---|---|
| 400 | `validation_error` | entrada inválida; reemplaza el 422 por defecto de FastAPI. `field` es el `loc` del error sin el prefijo `body`/`query`/`path` |
| 401 | `unauthorized` / `token_expired` | sin token o vencido |
| 403 | `forbidden` | acción no permitida sobre un recurso propio o visible (p. ej. modificar/borrar una categoría del sistema, o borrar una transacción no manual). **Nunca** para un recurso ajeno: ver 404 |
| 404 | `not_found` | recurso inexistente **o de otro usuario** (spec 009 §4: no se distingue para no filtrar existencia) |
| 409 | `conflict` | p. ej. cuenta duplicada |
| 429 | `rate_limited` | header `Retry-After` |
| 500 | `internal` | sin detalles internos |

- Idempotencia en mutaciones de la app: header `Idempotency-Key: <uuid>`, solo en `POST` (el outbox offline reintenta sin duplicar). Clave en Redis: `(user_id, key)`, TTL 24 h. La misma clave con el mismo cuerpo (hash) reproduce la respuesta original (status, `content-type`, body) agregando `Idempotency-Replayed: true`; la misma clave con un cuerpo distinto responde 409 `conflict` (conflicto real, sin `Retry-After`); mientras la primera solicitud con esa clave sigue en vuelo (candado de 30 s), responde 409 `conflict` con `Retry-After: 1` y el cliente reintenta con la misma key. Solo se persisten respuestas con status < 500.
- Paginación por cursor: el cursor es opaco (`base64url(json)`); orden por defecto `(occurred_at DESC, id DESC)`; con `updated_since`, orden `(updated_at ASC, id ASC)`. `limit` entre 1 y 200 (default 50). Un cursor inválido, vencido o del orden equivocado responde 400 `validation_error` con `field: "cursor"`.
- `GET /health` y `GET /health/ready` son públicos, no llevan el prefijo `/v1` y están exentos de rate limiting.

## 2. Auth (módulo identity)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/google` **público** | Body `{ "id_token": "...", "device_info?" }` (`device_info` opcional, ≤200 caracteres) → verifica firma/audiencia con Google, crea o encuentra usuario. `email_verified=false` → 401 `unauthorized`. Respuesta: `{ access_token, refresh_token, expires_in, user }` |
| POST | `/auth/refresh` **público** | Body `{ "refresh_token", "device_info?" }` (mismo límite) → rota el refresh (familia) y emite nuevo par. Refresh vencido, revocado, reusado o desconocido → 401 `unauthorized` genérico (no se distingue el motivo); `token_expired` es exclusivo del access JWT |
| POST | `/auth/logout` | Body `{ "refresh_token" }` → revoca ese refresh token. Responde 204 siempre, exista o no el token |
| GET | `/me` | Perfil + `consents` + `connections`. En Fase 1, `connections` es `{ "gmail": "none", "notifications": "none" \| "granted" }` |
| DELETE | `/me` | Inicia borrado de cuenta (RF-11.3). Respuesta 202 |
| GET | `/me/export` | Genera exportación completa (job async) → `{ job_id }`; se consulta en `/me/export/{job_id}` (RF-11.2) |

## 3. Conexión Gmail (ingestion)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/gmail/connect` | Body `{ "server_auth_code": "..." }` (código de autorización incremental obtenido en la app) → backend lo canjea por refresh token, lo cifra, guarda y crea el watch. AC-1.2 |
| DELETE | `/gmail/connect` | Revoca token en Google, borra conexión, detiene watch (AC-11.1) |
| GET | `/gmail/status` | `{ status, last_sync_at, watch_expires_at }` |

## 4. Webhook Pub/Sub (ingestion) — **público con OIDC**

`POST /webhooks/gmail`

- Autenticación: token OIDC de Google en `Authorization` (audience = URL del webhook, service account del push). Firma inválida → 403.
- Body: envelope estándar de Pub/Sub; `message.data` (base64) contiene `{ emailAddress, historyId }`.
- Comportamiento: resolver usuario → encolar job de sync (`history.list` desde cursor) → responder 204 **antes** de parsear (el parsing es asíncrono). Errores transitorios → 5xx para que Pub/Sub reintente.

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
| GET | `/transactions` | Filtros: `from`, `to`, `kind`, `category_id`, `bank`, `account_id`, `channel`, `q` (texto), `updated_since` (sync). Paginado; los ítems no incluyen `sources` ni `pair` (ver `GET /transactions/{id}`) |
| POST | `/transactions` | Registro manual/NFC. Body: monto, dirección, fecha, comercio, categoría, cuenta opcional, `nfc_tag_id` opcional (marca la fuente con `channel: "nfc"`; el identificador en sí no se persiste) |
| GET | `/transactions/{id}` | Incluye `sources[]` (AC-9.3) y transacción emparejada si es transfer |
| PATCH | `/transactions/{id}` | Editables: `category_id` (dispara merchant_rule si el comercio no está vacío, AC-7.2; `learn_merchant_rule: bool = true` para omitirlo), `notes`, `merchant`, `kind` transfer↔original (AC-6.3/6.4) |
| DELETE | `/transactions/{id}` | Solo transacciones manuales (`parsed_by = "manual"`); sobre una capturada automáticamente → 403 |
| POST | `/transactions/{id}/transfer-pair` | Body `{ "pair_id" }` — emparejar manualmente. Ambas deben ser propias (si no, 404) y de dirección opuesta; si alguna ya está emparejada → 409. No exige monto igual. Queda `transfer_auto: false` |
| DELETE | `/transactions/{id}/transfer-pair` | Desemparejar (registra exclusión mutua que solo bloquea el emparejador automático; un nuevo `transfer-pair` manual entre las mismas dos sigue funcionando) |

## 7. Categorías, cuentas, revisión

| Método | Ruta | Descripción |
|---|---|---|
| GET/POST | `/categories` · PATCH/DELETE `/categories/{id}` | Sistema + propias; las del sistema no se modifican ni se borran (403). Nombre duplicado → 409. Ajena → 404. `DELETE` de una propia reasigna sus transacciones a `sin_categoria` y borra las `merchant_rules` que apuntaban a ella |
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

## 8. Insights y reporte fiscal

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/insights/monthly?year=2026&month=8` | Totales, por categoría, comparativa mes anterior (AC-9.1). Excluye transfers |
| GET | `/fiscal/report?tax_year=2025` | Reporte por cédulas/renglones (spec 007) + `rules_version` + trazabilidad (`transaction_ids` por cifra) |
| GET | `/fiscal/report.xlsx?tax_year=2025` | Excel (job async si >5 s; respuesta 202 + job) |
| GET | `/fiscal/thresholds?tax_year=2025` | Topes de obligación de declarar en UVT y COP (AC-10.2) |

## 9. Contrato de sincronización offline (app)

1. **Pull**: `GET /transactions?updated_since=<cursor>` (y equivalentes de categorías/cuentas/revisión) → la app actualiza Drift y avanza cursor por tabla.
2. **Push**: la app drena su `outbox` FIFO contra los endpoints normales con `Idempotency-Key`; en 409/validación el ítem se marca para resolución manual.
3. El servidor nunca asume que la app está al día: toda respuesta de mutación devuelve el recurso completo actualizado.
