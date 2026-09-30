# Spec 010 — Compliance

App de uso masivo: estas obligaciones son bloqueantes de lanzamiento, no opcionales. Cada sección tiene un hito en `roadmap/tasks.md`.

## 1. Google OAuth — scope restringido de Gmail

`gmail.readonly` es **restricted scope**. Implicaciones:

| Etapa | Límite | Requisito |
|---|---|---|
| Desarrollo/MVP | ≤ 100 usuarios con Gmail conectado, consent screen "no verificada" | Ninguno formal; pantalla muestra advertencia |
| Lanzamiento público | Sin límite | **Verificación OAuth de Google** + **auditoría CASA** anual |

### Modo de prueba (desarrollo, F3.1–F3.6)

Mientras la pantalla de consentimiento del proyecto GCP (`luka-510204`) esté en modo de prueba
("Público en prueba" en Google Auth Platform):

- Solo los usuarios de prueba declarados en la consola pueden completar el consentimiento y
  conectar Gmail; cualquier otra cuenta de Google lo rechaza antes de llegar al backend.
- Google muestra el aviso "esta app no está verificada" durante el flujo: es el comportamiento
  esperado de un scope restringido sin verificar, no un error de configuración.
- Los grants de scopes restringidos en modo de prueba **vencen a los 7 días**, sin importar la
  actividad del usuario; pasado ese plazo, la próxima llamada a Google falla con `invalid_grant`,
  la conexión pasa a `revoked` (spec 006 §2.1) y el usuario reconecta desde Ajustes (spec 008
  §3.7). El límite de 7 días desaparece al pasar a producción verificada (§Lanzamiento público).

### Verificación OAuth
- Solicitar en Google Cloud Console: video demo del flujo, justificación del scope ("leer únicamente correos de notificaciones bancarias para registrar transacciones del propio usuario"), política de privacidad pública en dominio propio, homepage del producto.
- Principio de **scope mínimo**: solo `gmail.readonly` + `openid email profile`. Nunca pedir scopes de escritura.

### CASA (Cloud Application Security Assessment)
- Framework de App Defense Alliance basado en OWASP ASVS; laboratorio autorizado; recertificación **anual**.
- Costo estimado: USD $500–$4,500 (tier estándar de laboratorio) — presupuestar en el plan de lanzamiento; puede subir según alcance.
- El cumplimiento de spec 009 (ASVS L2) deja el sistema listo para el assessment: la auditoría no debe requerir rediseño.
- **Gate operativo**: el backend monitorea el conteo de conexiones Gmail activas; al llegar a 80 se activa la alerta de iniciar verificación/CASA antes de abrir más cupos.

### Alternativa de contingencia
Si CASA se retrasa: modo degradado sin Gmail (captura solo por notificaciones + manual) para nuevos usuarios, manteniendo Gmail para los ≤100 existentes.

## 2. Google Play

| Política | Obligación | Cómo cumplimos |
|---|---|---|
| SMS/Call Log | Prohibido `READ_SMS`/`RECEIVE_SMS` salvo default handler | **No usamos esos permisos**: SMS capturados vía notificación de la app de Mensajes (ADR-4) |
| Acceso a notificaciones | Permiso sensible: requiere ser funcionalidad núcleo, divulgación prominente y consentimiento | Onboarding con pantalla de divulgación explícita antes del ajuste del sistema; declaración en Play Console (Data Safety + formulario de permisos); la funcionalidad ES núcleo (captura de transacciones) |
| Data Safety | Declarar datos recolectados, uso y compartición | Formulario: info financiera (transacciones) — recolectada, no compartida ni vendida; contenido de notificaciones — procesado, retención 90 días |
| Finanzas personales | Categoría con políticas propias (no somos préstamos) | Declararse como herramienta de finanzas personales; sin funciones de crédito |
| Cuenta borrable | Play exige borrado de cuenta in-app y por web | RF-11.3 + página web de solicitud de borrado |

**App Store (iOS)**: sin listener ni SMS → sin fricción especial; cumplir 5.1.1 (privacidad) y 3.1 (sin compras externas). Privacy Nutrition Label equivalente al Data Safety: info financiera (los pagos con Apple Pay que el usuario envía por su automatización de Atajos: tarjeta, comercio, monto), ligada al usuario, no usada para rastreo. La captura la activa el usuario creando la automatización; la app no la crea ni la lee. Hoy se distribuye sin App Store (build sin firmar + SideStore, F4.3b).

## 3. Colombia — Ley 1581/2012 (habeas data) y régimen de protección de datos

- **Responsable del tratamiento**: definir la entidad legal antes del lanzamiento (persona natural o SAS) e inscribir bases de datos en el RNBD (Registro Nacional de Bases de Datos) si aplica según el tamaño de la entidad.
- **Política de tratamiento de datos personales**: documento público (web + app) que declare: datos tratados (identificación, financieros derivados de correos/notificaciones), finalidades (registro de transacciones, reporte fiscal), derechos del titular (conocer, actualizar, rectificar, suprimir), canal de PQRs y término de respuesta legal.
- **Autorización previa e informada**: checkbox explícito (no pre-marcado) en el onboarding, con registro de fecha/versión aceptada (`users.consents`).
- **Derechos del titular implementados en producto**: exportación (RF-11.2), supresión total (RF-11.3), rectificación (edición de datos).
- **Datos financieros = datos sensibles en la práctica**: tratamiento con las medidas de spec 009; no compartir con terceros salvo procesadores necesarios (infra, LLM) bajo contrato.

## 4. Procesadores de datos (terceros)

| Tercero | Datos que recibe | Base |
|---|---|---|
| Google (OAuth/Gmail/Pub/Sub) | Identidad, metadatos de correo | Consentimiento del usuario; términos de Google API Services (incluye Limited Use Policy: los datos de Gmail solo para la funcionalidad visible al usuario, nunca para ads ni entrenamiento) |
| DeepSeek (LLM) | Cuerpo de mensajes bancarios (sin identidad del usuario) | Necesario para el servicio; documentar términos de retención del proveedor y ofrecer en la política de privacidad; revisar opción zero-retention/opt-out de entrenamiento antes del lanzamiento |
| Proveedor VPS | Hospedaje de todos los datos | Contrato/términos; disco cifrado |

**Limited Use Policy de Google (crítico)**: los datos obtenidos vía Gmail API no pueden usarse para publicidad, ni transferirse salvo para proveer la funcionalidad, ni ser leídos por humanos salvo soporte con consentimiento. El envío del cuerpo de correos a DeepSeek para parsing está permitido como "procesamiento necesario para la funcionalidad visible al usuario", pero debe declararse en la política de privacidad y en la verificación OAuth.

## 5. Documentos legales a producir (pre-lanzamiento)

1. Política de privacidad y tratamiento de datos (web pública, ES).
2. Términos y condiciones (incluye disclaimer fiscal de spec 007 §1).
3. Página web mínima del producto (requisito de verificación OAuth) con enlace de borrado de cuenta.

## 6. Checklist de lanzamiento masivo

- [ ] Verificación OAuth aprobada por Google.
- [ ] CASA aprobado (certificado vigente < 12 meses).
- [ ] Declaraciones de Play Console (Data Safety + permisos) aprobadas.
- [ ] Política de privacidad y T&C publicados y enlazados en app/stores.
- [ ] Registro RNBD evaluado/realizado según entidad legal.
- [ ] DPA/términos de DeepSeek y VPS archivados.
- [ ] Gate de 80 conexiones Gmail activo con alerta.
