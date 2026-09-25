# Fixtures de correos bancarios (insumo de F2.3, spec 006 §4.1)

Correos reales capturados el 2026-09-20 desde el Gmail del autor y **anonimizados**:
montos, últimos dígitos, llaves Bre-B, nombres de personas y empleador fueron alterados;
comercios, remitentes, asuntos, estructura y formatos de fecha/monto se conservan tal cual.

Cada fixture tiene un encabezado con metadatos y un bloque `expected` (lo que la plantilla
debe extraer), separado del cuerpo por `---`. El cuerpo es el texto plano extraído del HTML.

**Contrato del encabezado** (YAML, parseado por `backend/tests/support/email_fixtures.py`):

| Campo | Obligatorio | Significado |
|---|---|---|
| `from` | sí | remitente (`Nombre <addr>` o `addr`); insumo del filtro de remitentes (spec 006 §2.2) |
| `subject` | sí | asunto del correo (nunca se usa para matchear banco/plantilla) |
| `received_at` | sí | timestamp de recepción (ISO-8601, aware); ancla de la ventana `occurred_at ± 7 días` |
| `expected` | sí | lo que la plantilla/LLM debe extraer; campos libres según el caso |
| `expected.discarded_by_sender_filter` | no | `true` si el fixture existe para probar el filtro de remitentes (AC-2.4): el correo se descarta antes de persistir nada, no hay plantilla que probar |
| `note` | no | contexto adicional para quien lea o mantenga el fixture |

| Archivo | Canal | Patrón |
|---|---|---|
| `bancolombia/compra_tdeb.txt` | email | `Compraste $<monto es-CO> en <COMERCIO> con tu T.Deb *<last4>, el DD/MM/YYYY a las HH:MM` |
| `bancolombia/compra_tdeb_2.txt` | email | igual, otro comercio/monto |
| `bancolombia/transferencia_llave.txt` | email | `<NOMBRE>, transferiste $<monto en-US> a la llave <n> desde tu cuenta *<last4> a <NOMBRE> el DD/MM/YY a las HH:MM` |
| `bancolombia/transferencia_llave_wrap.txt` | email | igual, pero cortado a ~76 caracteres: la frase empieza a mitad de línea, tras "¡Listo! Todo salió bien con tus movimientos" |
| `bancolombia/transferencia_llave_recibida_wrap.txt` | email | `<NOMBRE>, recibiste una transferencia de <NOMBRE> por $<monto en-US> en tu cuenta *<last4> conectada a la llave <alias> el DD/MM/YY a las HH:MM`, cortado a ~76 caracteres igual que el anterior |
| `bancolombia/nomina.txt` | email | `Recibiste un pago de Nomina de <EMPRESA> por $<monto en-US> en tu cuenta de Ahorros el DD/MM/YYYY a las HH:MM` |
| `other/nu_pago.txt` | email | descartado por remitente (AC-2.4); cuerpo reutilizado en test unitario del LLM |

Observaciones para los normalizadores (F2.3):

- Bancolombia mezcla **dos formatos de monto**: `$176.824,00` (es-CO) en compras y `$2,910,744.00` (en-US) en transferencias y nómina.
- Mezcla **dos formatos de fecha**: `01/05/2026` (compras, nómina) y `01/05/26` (transferencias). Hora local de Colombia (`-05:00`).
- Remitente Bancolombia: `alertasynotificaciones@an.notificacionesbancolombia.com`; asunto fijo: `Alertas y Notificaciones`.
- El cuerpo útil es la frase que contiene `Bancolombia:` (al inicio de línea, o a mitad de línea si el correo viene cortado a ~76 caracteres — `*_wrap.txt`); el resto es boilerplate de seguridad que debe descartarse antes de enviar nada al LLM (RNF-5, costo por token).
- `T.Deb *1234` → cuenta vinculada por `(bank=bancolombia, last4)`; en nómina no hay last4 (→ `----` en la huella de dedupe).
- Aún faltan fixtures de Nequi, Davivienda, Daviplata, BBVA y Banco de Bogotá: el buzón consultado no tenía correos de esos bancos.
- `other/nu_pago.txt`: Nu no está en la lista blanca de remitentes (`parsing/config/senders.yaml`), así que se descarta en la ingesta sin persistir el cuerpo (AC-2.4, D5) — no genera fila en `raw_messages` ni prueba ninguna plantilla. Su cuerpo se reutiliza únicamente como input del test unitario de `validate_extraction`/`FakeLlmParser` (mapeo JSON→`ParsedTransaction` con `bank="other"`, verificando que el impuesto 4xmil no contamine el monto).
