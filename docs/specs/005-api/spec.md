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
| 400 | `validation_error` | entrada inválida |
| 401 | `unauthorized` / `token_expired` | sin token o vencido |
| 403 | `forbidden` | recurso de otro usuario |
| 404 | `not_found` | |
| 409 | `conflict` | p. ej. cuenta duplicada |
| 429 | `rate_limited` | header `Retry-After` |
| 500 | `internal` | sin detalles internos |

- Idempotencia en mutaciones de la app: header `Idempotency-Key: <uuid>` (el outbox offline reintenta sin duplicar).

## 2. Auth (módulo identity)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/google` **público** | Body `{ "id_token": "..." }` → verifica firma/audiencia con Google, crea o encuentra usuario. Respuesta: `{ access_token, refresh_token, expires_in, user }` |
| POST | `/auth/refresh` **público** | Body `{ "refresh_token" }` → rota el refresh (familia) y emite nuevo par. Reuso de token rotado → 401 + revocación de familia |
| POST | `/auth/logout` | Revoca el refresh token actual |
| GET | `/me` | Perfil + estado de conexiones (`gmail: active/none/error`, notificaciones) |
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

- Respuesta: `{ "accepted": 3, "duplicates": 1 }`.
- Rate limit específico (spec 009). El dispositivo solo envía notificaciones de paquetes de la lista soportada (AC-3.3); el servidor re-valida contra la misma lista.

## 6. Transacciones (ledger)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/transactions` | Filtros: `from`, `to`, `kind`, `category_id`, `bank`, `account_id`, `channel`, `q` (texto), `updated_since` (sync). Paginado |
| POST | `/transactions` | Registro manual/NFC. Body: monto, dirección, fecha, comercio, categoría, cuenta opcional, `nfc_tag_id` opcional |
| GET | `/transactions/{id}` | Incluye `sources[]` (AC-9.3) y transacción emparejada si es transfer |
| PATCH | `/transactions/{id}` | Editables: `category_id` (dispara merchant_rule, AC-7.2), `notes`, `merchant`, `kind` transfer↔original (AC-6.3/6.4) |
| DELETE | `/transactions/{id}` | Solo transacciones manuales |
| POST | `/transactions/{id}/transfer-pair` | Body `{ "pair_id" }` — emparejar manualmente |
| DELETE | `/transactions/{id}/transfer-pair` | Desemparejar (registra exclusión) |

## 7. Categorías, cuentas, revisión

| Método | Ruta | Descripción |
|---|---|---|
| GET/POST | `/categories` · PATCH/DELETE `/categories/{id}` | Sistema + propias; las del sistema no se modifican (403) |
| GET/POST | `/accounts` · PATCH/DELETE `/accounts/{id}` | Cuentas vinculadas (RF-6) |
| GET | `/review` | Cola de revisión con `partial_extract` |
| POST | `/review/{raw_message_id}/convert` | Body = transacción completa → crea transacción `parsed_by: manual` y marca resuelto |
| POST | `/review/{raw_message_id}/discard` | Descarta |

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
