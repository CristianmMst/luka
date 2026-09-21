# Fixtures de correos bancarios (insumo de F2.3, spec 006 §4.1)

Correos reales capturados el 2026-09-20 desde el Gmail del autor y **anonimizados**:
montos, últimos dígitos, llaves Bre-B, nombres de personas y empleador fueron alterados;
comercios, remitentes, asuntos, estructura y formatos de fecha/monto se conservan tal cual.

Cada fixture tiene un encabezado con metadatos y un bloque `expected` (lo que la plantilla
debe extraer), separado del cuerpo por `---`. El cuerpo es el texto plano extraído del HTML.

| Archivo | Canal | Patrón |
|---|---|---|
| `bancolombia/compra_tdeb.txt` | email | `Compraste $<monto es-CO> en <COMERCIO> con tu T.Deb *<last4>, el DD/MM/YYYY a las HH:MM` |
| `bancolombia/compra_tdeb_2.txt` | email | igual, otro comercio/monto |
| `bancolombia/transferencia_llave.txt` | email | `<NOMBRE>, transferiste $<monto en-US> a la llave <n> desde tu cuenta *<last4> a <NOMBRE> el DD/MM/YY a las HH:MM` |
| `bancolombia/nomina.txt` | email | `Recibiste un pago de Nomina de <EMPRESA> por $<monto en-US> en tu cuenta de Ahorros el DD/MM/YYYY a las HH:MM` |
| `other/nu_pago.txt` | email | Nu Colombia (fuera del alcance MVP → debe caer al LLM genérico) |

Observaciones para los normalizadores (F2.3):

- Bancolombia mezcla **dos formatos de monto**: `$176.824,00` (es-CO) en compras y `$2,910,744.00` (en-US) en transferencias y nómina.
- Mezcla **dos formatos de fecha**: `01/05/2026` (compras, nómina) y `01/05/26` (transferencias). Hora local de Colombia (`-05:00`).
- Remitente Bancolombia: `alertasynotificaciones@an.notificacionesbancolombia.com`; asunto fijo: `Alertas y Notificaciones`.
- El cuerpo útil es UNA línea que empieza por `Bancolombia:`; el resto es boilerplate de seguridad que debe descartarse antes de enviar nada al LLM (RNF-5, costo por token).
- `T.Deb *1234` → cuenta vinculada por `(bank=bancolombia, last4)`; en nómina no hay last4 (→ `----` en la huella de dedupe).
- Aún faltan fixtures de Nequi, Davivienda, Daviplata, BBVA y Banco de Bogotá: el buzón consultado no tenía correos de esos bancos.
