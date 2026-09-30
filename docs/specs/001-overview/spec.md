# Spec 001 — Visión y alcance

## 1. Visión

**luka** elimina el registro manual de gastos: captura automáticamente cada transacción del usuario desde sus correos bancarios, las notificaciones de su celular y sus SMS bancarios, la clasifica con etiquetas fiscales colombianas, y al final del año genera las cifras de la declaración de renta organizadas según el formulario 210 de la DIAN — listas para copiar al portal o entregar al contador.

## 2. Problema

1. Registrar gastos manualmente es tedioso; la mayoría de la gente abandona las apps de finanzas en semanas.
2. En Colombia, preparar la declaración de renta implica reconstruir un año de movimientos entre extractos de varios bancos; es lento y propenso a errores.
3. Las apps existentes de presupuesto no entienden el contexto fiscal colombiano (cédulas, UVT, deducciones de salud/vivienda/pensión).

## 3. Usuarios objetivo

| Persona | Descripción | Necesidad principal |
|---|---|---|
| Empleado declarante | Asalariado que declara renta cada año | Reporte 210 automático con deducciones detectadas |
| Independiente/freelancer | Ingresos variables en varias cuentas | Visibilidad de ingresos/gastos + soporte para renta |
| Usuario multibanco | Cuentas en 2+ bancos (p. ej. Bancolombia + Nequi) | Vista unificada sin duplicados ni dobles conteos por transferencias |

Mercado inicial: Colombia. La app es de **uso masivo** (multiusuario, registro abierto), no personal.

## 4. Propuesta de valor

- **Captura sin fricción**: el usuario conecta su Gmail al registrarse (mismo flujo del login con Google) y activa el lector de notificaciones; desde ese momento las transacciones aparecen solas.
- **Tiempo real**: un pago NFC/datáfono aparece en la app segundos después, capturado desde la notificación del banco o de Google Wallet.
- **Fiscalmente inteligente**: cada transacción lleva etiqueta fiscal; el reporte anual sale organizado por cédulas/renglones del 210.
- **Sin duplicados**: la misma compra llega por correo + notificación + SMS y se registra una sola vez.
- **Sin dobles conteos**: transferencias entre cuentas propias se detectan y excluyen de gastos/ingresos.

## 5. Alcance

### MVP (v1)

- Registro/login con Google Sign-In; conexión de Gmail (scope `gmail.readonly`) en el onboarding.
- Captura por: correos Gmail (push), notificaciones Android (apps bancarias + Google Wallet + app de Mensajes para SMS), registro manual, tag NFC físico.
- Parsing híbrido (plantillas por banco + DeepSeek V4 Flash) con cola de revisión manual.
- Bancos soportados al lanzamiento: **Bancolombia, Nequi, Davivienda, Daviplata, BBVA Colombia, Banco de Bogotá**. Otros correos bancarios caen al LLM genérico.
- Deduplicación multi-fuente y detección de transferencias entre cuentas propias.
- Categorías (personalizables) con etiqueta fiscal; corrección manual reentrenable (reglas por comercio).
- Dashboard mensual, historial, cola de revisión.
- Gastos fijos mensuales: se tachan solos cuando la captura detecta el pago y avisan 7 y 2 días antes a las 9:00 a. m., y el día antes a las 9:00 a. m. y a las 5:00 p. m. (hora de Colombia): por push de Firebase en Android y con avisos locales en iPhone (spec 011).
- Reporte anual estilo formulario 210 (JSON + Excel) y simulación básica de si está obligado a declarar (topes UVT).
- iOS: misma app sin listener de notificaciones/SMS (captura vía Gmail + manual + NFC en foreground + pagos con Apple Pay por una automatización de Atajos, iOS 17+, spec 006 §3.3).

### Fuera de alcance del MVP (backlog)

- Presentación directa ante la DIAN (no existe API pública).
- Open banking / conexión directa a bancos (Belvo/Palenca) — candidato v2.
- Presupuestos avanzados, metas de ahorro, inversiones.
- Soporte multi-país.
- Outlook/otros proveedores de correo.
- Cálculo exacto del impuesto a pagar (el MVP reporta cifras por cédula; la liquidación completa del 210 es v2).

## 6. Restricciones estructurales (resumen — detalle en specs 009/010)

- Leer SMS con `READ_SMS` está prohibido por Google Play para apps que no sean el SMS handler; se capturan vía la notificación de la app de Mensajes.
- iOS no permite leer SMS ni notificaciones de otras apps. La única fuente automática en el teléfono es la automatización "Transacción" de Atajos (pagos con Wallet), que el usuario crea a mano.
- Gmail `gmail.readonly` es *restricted scope*: >100 usuarios requiere verificación OAuth + auditoría CASA anual.
- No existe API en Android/iOS para observar transacciones NFC de otras apps; la captura "NFC" real ocurre vía la notificación del pago.

## 7. Glosario

| Término | Definición |
|---|---|
| **Transacción** | Movimiento de dinero normalizado: monto, moneda, fecha, comercio/contraparte, tipo (gasto/ingreso/transferencia), cuenta, categoría |
| **Fuente (source)** | Evidencia cruda de una transacción: correo, notificación, SMS-notificación o registro manual |
| **Huella de dedupe** | Clave derivada `(user, banco, monto, ventana temporal, últimos dígitos de cuenta)` que identifica la misma transacción llegada por distintas fuentes |
| **Transferencia interbancaria** | Par débito/crédito entre dos cuentas propias del mismo usuario; no es gasto ni ingreso |
| **Cuenta vinculada** | Cuenta/tarjeta que el usuario declara como propia (banco + últimos dígitos), usada por el matcher de transferencias |
| **Cola de revisión** | Mensajes que ni las reglas ni el LLM pudieron parsear con confianza; el usuario los resuelve manualmente |
| **Cédula** | Categoría de renta del formulario 210 (general, pensiones, dividendos...) |
| **UVT** | Unidad de Valor Tributario; las reglas fiscales se expresan en UVT y se resuelven con la tabla del año gravable |
| **Año gravable** | Año calendario que cubre el reporte de renta |
| **Watch** | Suscripción de Gmail API que publica en Pub/Sub cuando llega correo; expira cada 7 días y se renueva a diario |
| **Gasto fijo** | Pago que el usuario declara que se repite cada mes (comercio, monto aproximado y día); luka espera la transacción que lo paga, no la crea (spec 011) |
| **Ocurrencia** | La instancia de un gasto fijo en un mes concreto, con su fecha de vencimiento y estado: pendiente, pagada (tachada) u omitida |
| **Recordatorio push** | Aviso de un gasto fijo aún no pagado, 7 y 2 días antes a las 9:00 a. m., y el día antes a las 9:00 a. m. y a las 5:00 p. m.: en Android lo envía el backend por Firebase Cloud Messaging y en iPhone lo programa el teléfono |
