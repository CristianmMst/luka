# Spec 006 — Captura y parsing

## 1. Canales de captura

| Canal | Plataforma | Latencia objetivo | Mecanismo |
|---|---|---|---|
| Correo Gmail | Ambas (server-side) | < 60 s p95 | Gmail watch → Pub/Sub → webhook |
| Notificación bancaria / Google Wallet | Android | < 10 s p95 | NotificationListenerService |
| SMS bancario | Android | < 10 s p95 | Notificación de la app de Mensajes (NO READ_SMS) |
| NFC tag | Android (+iOS foreground) | inmediato | nfc_manager → formulario rápido |
| Manual | Ambas | inmediato | formulario |

## 2. Gmail (server-side)

### 2.1 Ciclo del watch
1. Al conectar Gmail: `users.watch` con el topic Pub/Sub → guarda `history_id` inicial y `watch_expires_at` (7 días).
2. Cron diario (worker): renueva todo watch con `watch_expires_at < now()+48h`.
3. Push recibido: `history.list(startHistoryId=cursor)` → solo mensajes nuevos → avanza cursor. Si el cursor es muy viejo (404 de Gmail), resync con `messages.list` de los últimos 7 días.

### 2.2 Filtro de remitentes
Lista blanca de dominios/remitentes por banco (config versionada, `parsing/config/senders.yaml`,
`version: 1`, un mapa `banks:` con `verified`/`senders` por banco):

```yaml
version: 1
banks:
  bancolombia:  # verified: true — validado con fixture real (F2.3)
    verified: true
    senders: [alertasynotificaciones@an.notificacionesbancolombia.com,
              "@notificacionesbancolombia.com", "@bancolombia.com.co"]
  nequi:        {verified: false, senders: ["@nequi.com.co"]}
  davivienda:   {verified: false, senders: ["@davivienda.com"]}
  daviplata:    {verified: false, senders: ["@daviplata.com"]}
  bbva:         {verified: false, senders: ["@bbva.com.co"]}
  banco_bogota: {verified: false, senders: ["@bancodebogota.com.co"]}
```

Un correo cuyo `From` no matchea ningún patrón se descarta sin persistir el cuerpo (AC-2.4).
Matching (`parsing/domain/allowlist.py`): exacto case-insensitive sobre la dirección (sin el
display name), o sufijo de dominio si el patrón empieza por `@` (matchea el dominio exacto y
subdominios, nunca un dominio "hijo": `@bancolombia.com.co` NO matchea
`x@bancolombia.com.co.evil.com`). Solo Bancolombia está `verified: true` (fixture real, F2.3); los
otros cinco bancos quedan **sin verificar con fixture** — el filtro los acepta igual, pero al no
tener plantilla (F2.7, diferido) siempre caen al LLM genérico.

### 2.3 Extracción del cuerpo
- Preferir `text/plain`; si solo hay HTML, convertir a texto (strip de tags, conservar tablas como líneas).
- Truncar a 8 KB antes de persistir (los correos bancarios relevantes son cortos; evita almacenar adjuntos/branding).
- El cuerpo se compone como `título\n\ntexto` para notificaciones/SMS (correos no tienen título propio, solo `texto`); truncado a 8 KB en frontera de carácter (nunca parte un carácter multibyte). `bank` se resuelve al ingerir (filtro de remitente/paquete) y queda guardado en la fila, no se recalcula después.

## 3. Notificaciones Android (app)

### 3.1 Paquetes soportados (config remota)
La lista de paquetes se descarga del backend (`/config/capture`) para poder ampliarla sin release.
Vive en `parsing/config/capture.yaml` (`version: 1`, D6) y se sirve tal cual (más un mapa
`email_senders` derivado de `senders.yaml`) por `GET /v1/config/capture` (ingestion):

```yaml
version: 1
banking_apps:
  - com.bancolombia.app          # Bancolombia
  - com.nequi.MobileApp          # Nequi
  - com.davivienda.daviviendaapp # Davivienda
  - com.daviplata.app            # DaviPlata
  - com.bbva.bbvacolombia        # BBVA CO
  - com.bancodebogota.bancamovil # Banco de Bogotá
  - com.google.android.apps.walletnfcrel  # Google Wallet
messages_apps:                    # para SMS-vía-notificación
  - com.google.android.apps.messaging
  - com.samsung.android.messaging
sms_sender_patterns:              # aplicados al título de la notificación de Mensajes
  - "^(87400|85540|891888|...)$"  # códigos cortos bancarios (se completan con fixtures)
  - "(?i)bancolombia|nequi|davivienda|bbva"
```

### 3.2 Comportamiento del listener
1. Notificación posted → ¿paquete en `banking_apps`? → capturar `title+text+bigText`.
2. ¿Paquete en `messages_apps`? → aplicar `sms_sender_patterns` al título (remitente del SMS); si no matchea, **ignorar sin leer el resto** (AC-3.3, privacidad).
3. Pre-filtro local barato: la notificación debe contener un signo de moneda/monto (`$`, `COP`, dígitos con separador de miles); si no, se ignora.
4. Encolar en Drift (`outbox`) con `client_hash = sha256(package + posted_at_bucket + text)` → batch a `/ingest/notifications` (funciona offline).
5. El texto de notificaciones ignoradas jamás se persiste ni se transmite.

## 4. Pipeline de parsing (workers)

```mermaid
flowchart LR
    RM[raw_message] --> R{"¿plantilla regex<br/>del banco?"}
    R -- match --> N[normalizar]
    R -- no match --> L{"DeepSeek V4 Flash<br/>JSON schema"}
    L -- "confidence ≥ 0.8" --> N
    L -- "confidence < 0.8 o error" --> Q[review_queue]
    N --> D{"dedupe<br/>índice único"}
    D -- nueva --> T[transactions + evento]
    D -- existente --> S[adjuntar transaction_source]
    T --> X[matcher transferencias]
```

### 4.1 Plantillas por banco
- Una plantilla = regex nombrada + post-proceso (`parsing/config/templates/<banco>.yaml`), con: patrón, campos capturados (`amount`, `merchant`, `last4`, `datetime`, `direction`), formato de fecha y reglas de normalización de monto (`$1.234.567,89` → `1234567.89`).
- Cada plantilla se versiona y referencia en `parsed_by` (`rule:<banco>:<template_id>:v<version>`, p. ej. `rule:bancolombia:compra_tdeb:v1`).
- **Regla de oro**: ninguna plantilla entra sin fixture de mensaje real anonimizado + test.
- Esquema del YAML de plantillas de un banco (`parsing/config/templates/<banco>.yaml`):

```yaml
bank: <banco>              # str, debe coincidir con una clave de senders.yaml
version: 1                 # int, referenciado en parsed_by
relevant_line_prefix: "Bancolombia:"  # str | null — prefijo de la(s) linea(s) util(es)
                                       # del cuerpo (extracto para plantillas y LLM, RNF-5)
templates:
  - id: compra_tdeb         # str, unico dentro del banco
    direction: debit        # debit | credit
    pattern: '...'          # regex con grupos nombrados (amount, date, time obligatorios;
                             # merchant, last4 segun el mensaje)
    date_format: "%d/%m/%Y" # formato strptime de <date>; <time> siempre es %H:%M
    suggested_category: nomina  # opcional
```

- `relevant_line_prefix` reduce el cuerpo a las líneas que empiezan por ese prefijo antes de
  matchear plantillas o llamar al LLM (`extract_excerpt`, `parsing/domain/excerpt.py`); sin
  match cae a un fallback (líneas no vacías sin URLs/teléfonos, truncado a 1500 caracteres).

### 4.2 Fallback LLM — contrato DeepSeek

- Modelo: `deepseek-v4-flash`, API OpenAI-compatible, `response_format: json_object`, `temperature: 0`.
- El adapter implementa `LlmParserPort` (cambiar de proveedor = nuevo adapter).

**System prompt (fijo, cacheable)**: instruye extraer campos de mensajes de bancos colombianos; formato de montos colombiano; devolver `null` en campos ausentes; nunca inventar.

**Esquema de salida requerido**:

```json
{
  "is_transaction": true,
  "amount": "45900.00",
  "currency": "COP",
  "direction": "debit",
  "merchant": "RAPPI",
  "occurred_at": "2026-08-05T14:30:00-05:00",
  "bank": "bancolombia",
  "last4": "1234",
  "suggested_category": "restaurantes",
  "confidence": 0.93
}
```

**Validación post-LLM (Pydantic)**: monto > 0, fecha plausible (±7 días del recibido), banco en enum, `is_transaction=false` → descartar, JSON inválido → 1 reintento → review_queue.

**Control de costos (RNF-5)**: contador mensual de tokens por usuario en Redis; superado el presupuesto → directo a review_queue con motivo `llm_budget_exceeded`.

### 4.3 Normalización
- Comercio: uppercase → strip de sufijos de pasarela (`*`, códigos), colapso de espacios; se usa para `merchant_rules`. Esta normalización completa vive en **ledger** (`_resolve_category`, F1); `parsing` solo limpia el texto capturado por la plantilla (`clean_text`: strip, colapso de espacios, quita puntuación final) — no duplica el normalizador de comercio (D3).
- Categoría automática: 1º regla del usuario (`merchant_rules`), 2º sugerencia del parser/LLM, 3º `sin_categoria`.

### 4.4 Dedupe e idempotencia
- Idempotencia de ingesta: `UNIQUE(user_id, channel, external_id)` en `raw_messages` — el mismo push/notificación repetido no reprocesa (AC-5.2).
- Si la ingesta encuentra un duplicado (`INSERT … ON CONFLICT DO NOTHING` no insertó) cuya fila sigue `pending`, re-publica `RawMessageReceived` (D9): mitiga la falta de outbox cuando el publish original falló tras el commit.
- Vocabulario de resultado de una ingesta: `accepted` (fila nueva, evento publicado), `duplicate` (fila ya existía; republica el evento solo si seguía `pending`) o `discarded` (remitente/paquete no soportado, nada se persiste, AC-2.4).
- Dedupe de transacciones: huella de spec 004 §3 con `ON CONFLICT DO NOTHING`; si conflicto → adjuntar `transaction_source` a la existente (AC-5.1).
- El matcher de transferencias corre tras cada inserción (spec 004 §4).

## 5. NFC (app)

- Tags NDEF con payload propio: `finanzia://quick-add?tag=<uuid>`; el uuid se asocia en la app a una plantilla (categoría + cuenta + nota por defecto).
- Android: intent-filter NDEF → abre la app directo en el formulario rápido incluso cerrada. iOS: lectura en foreground (Core NFC) desde la pantalla de registro.
- Escritura de tags: pantalla en Ajustes (Android) usando `nfc_manager`; un tag puede reescribirse.
- El formulario rápido solo pide monto (categoría/cuenta vienen del tag) → guardar offline → outbox (AC-4.2).

## 6. Métricas del pipeline (observabilidad)

Contadores por banco/canal exportados a logs estructurados: `parsed_by_rule`, `parsed_by_llm`, `sent_to_review`, `discarded`, `dedupe_hits`, `llm_cost_tokens`. Meta de salud: ≥ 80% de mensajes de bancos soportados parseados por regla (las reglas son gratis; el LLM es la red de seguridad).
