# Spec 002 — Requisitos

Formato: historias de usuario con criterios de aceptación **Given/When/Then**. Los IDs (RF-x, RNF-x) son la referencia de trazabilidad usada por los demás specs y por `roadmap/tasks.md`.

## A. Requisitos funcionales

### RF-1 · Autenticación con Google

*Como usuario, quiero registrarme e iniciar sesión con mi cuenta de Google para no crear otra contraseña y dejar mi Gmail conectado desde el inicio.*

- **AC-1.1** Given un usuario nuevo, When completa Google Sign-In, Then se crea su cuenta con email/nombre/foto de Google y queda autenticado.
- **AC-1.2** Given el onboarding, When el usuario acepta el permiso incremental `gmail.readonly`, Then el backend guarda el refresh token cifrado y activa el watch de Gmail.
- **AC-1.3** Given un usuario que rechaza el permiso de Gmail, When termina el onboarding, Then puede usar la app (manual/notificaciones) y conectar Gmail después desde Ajustes.
- **AC-1.4** Given un token de acceso expirado, When la app llama a la API, Then el refresh token rotativo emite uno nuevo sin re-login; si el refresh fue revocado, se fuerza re-login.

### RF-2 · Captura por correos de Gmail

*Como usuario, quiero que los correos de confirmación de mis bancos se conviertan en transacciones automáticamente.*

- **AC-2.1** Given Gmail conectado, When llega un correo de un remitente bancario soportado, Then la transacción aparece en la app en < 60 segundos (p95).
- **AC-2.2** Given un correo bancario que las reglas no reconocen, When el LLM lo parsea con confianza suficiente, Then se crea la transacción marcada `parsed_by: llm`.
- **AC-2.3** Given un correo que ni reglas ni LLM entienden, Then entra a la cola de revisión con el texto relevante visible para el usuario.
- **AC-2.4** Given un correo no bancario, Then se descarta sin almacenar su contenido.
- **AC-2.5** Given que el watch de Gmail expira cada 7 días, Then el sistema lo renueva automáticamente a diario y reconcilia el historial perdido tras cualquier interrupción (`history.list` desde el último `historyId`).

### RF-3 · Captura por notificaciones (Android)

*Como usuario Android, quiero que los pagos que hago (incluidos NFC/contactless) se registren al instante desde las notificaciones de mis apps bancarias.*

- **AC-3.1** Given el permiso de acceso a notificaciones concedido, When una app bancaria soportada o Google Wallet publica una notificación de pago, Then la transacción aparece en la app en < 10 segundos (p95).
- **AC-3.2** Given una notificación de la app de Mensajes cuyo remitente coincide con un patrón de SMS bancario, Then se procesa igual que una notificación bancaria (así se cubren los SMS sin permisos `READ_SMS`).
- **AC-3.3** Given una notificación de una app fuera de la lista de paquetes soportados, Then se ignora localmente y su contenido nunca sale del dispositivo.
- **AC-3.4** Given el permiso revocado por el usuario o el sistema, Then la app lo detecta y muestra cómo reactivarlo, sin romper el resto de la captura.

### RF-4 · Registro manual y tag NFC

*Como usuario, quiero registrar gastos en efectivo en 2 toques acercando el teléfono a un tag NFC.*

- **AC-4.1** Given un tag NFC escrito por la app, When el usuario lo acerca al teléfono (app abierta o por deep link del sistema en Android), Then se abre el formulario rápido con la categoría preconfigurada del tag.
- **AC-4.2** Given el formulario rápido, When el usuario ingresa el monto y confirma, Then la transacción se guarda localmente y se sincroniza (funciona offline).
- **AC-4.3** La app permite escribir/borrar tags NDEF con `nfc_manager` (Android; iOS solo lectura en foreground).
- **AC-4.4** El registro manual completo (sin NFC) está disponible en ambas plataformas.

### RF-5 · Deduplicación multi-fuente

*Como usuario, quiero ver cada compra una sola vez aunque llegue por correo, notificación y SMS.*

- **AC-5.1** Given una compra capturada por notificación, When llega el correo de la misma compra (mismo banco, mismo monto, ±10 min, mismos últimos dígitos), Then NO se crea una segunda transacción; el correo se adjunta como fuente adicional.
- **AC-5.2** Given el mismo mensaje procesado dos veces (reintento de Pub/Sub, reenvío), Then el estado final es idéntico a procesarlo una vez (idempotencia).
- **AC-5.3** Given dos compras legítimas del mismo monto en el mismo comercio con más de 10 minutos de diferencia, Then se registran como dos transacciones.

### RF-6 · Transferencias interbancarias

*Como usuario multibanco, quiero que mover plata entre mis propias cuentas no aparezca como gasto ni ingreso.*

- **AC-6.1** Given dos cuentas vinculadas del usuario, When se capturan un débito y un crédito del mismo monto entre ellas dentro de una ventana de 48 h, Then ambas transacciones se marcan `transfer` y se enlazan entre sí.
- **AC-6.2** Given transacciones marcadas `transfer`, Then no suman en gastos, ingresos, dashboard ni reporte fiscal.
- **AC-6.3** Given un emparejamiento incorrecto, When el usuario lo desmarca, Then ambas vuelven a gasto/ingreso y el sistema no vuelve a emparejarlas automáticamente.
- **AC-6.4** El usuario puede marcar manualmente cualquier transacción como transferencia (p. ej. retiro de efectivo).

### RF-7 · Categorías y clasificación

- **AC-7.1** Toda transacción recibe una categoría automática (del parser/LLM o por regla de comercio aprendida); el usuario puede corregirla.
- **AC-7.2** Given una corrección de categoría, When el usuario la confirma, Then se crea una regla `comercio → categoría` propia del usuario que aplica a futuras transacciones.
- **AC-7.3** Cada categoría tiene una etiqueta fiscal (ver spec 007): `ingreso_laboral`, `deducible_salud`, `deducible_vivienda`, `aporte_pension_voluntaria`, `no_deducible`, etc.
- **AC-7.4** Existen categorías del sistema (no eliminables) y categorías personalizadas del usuario.

### RF-8 · Cola de revisión

- **AC-8.1** Los mensajes no parseados aparecen en una lista con el texto fuente; el usuario puede convertirlos en transacción (formulario prellenado con lo que sí se extrajo) o descartarlos.
- **AC-8.2** Given 3+ mensajes del mismo formato resueltos por usuarios, Then el equipo dispone de la información para crear una nueva plantilla regex (métrica interna de cobertura de parsing).

### RF-9 · Dashboard e historial

- **AC-9.1** Dashboard mensual: total gastos, total ingresos, balance, top categorías, comparación con el mes anterior. Excluye transferencias.
- **AC-9.2** Historial filtrable por fecha, banco, cuenta, categoría, fuente y texto libre; paginado.
- **AC-9.3** Detalle de transacción: muestra todas las fuentes que la evidencian (correo/notificación/SMS) y permite editar categoría, notas y flag de transferencia.

### RF-10 · Reporte anual de renta (formulario 210)

*Como declarante, quiero las cifras de mi año gravable organizadas por cédulas/renglones del 210 para diligenciar el portal DIAN o entregárselas a mi contador.*

- **AC-10.1** Given un año gravable seleccionado, Then el reporte agrupa: ingresos por cédula general (laboral, honorarios, capital, no laboral), deducciones detectadas (salud prepagada, intereses de vivienda, aportes voluntarios pensión/AFC, dependientes si el usuario lo declara), y totales por renglón según la config del año.
- **AC-10.2** El reporte indica si el usuario supera los topes de obligación de declarar (patrimonio/ingresos/consumos en UVT del año), con los valores UVT usados.
- **AC-10.3** Exportable a Excel (una hoja resumen por cédulas + una hoja de detalle de transacciones que soporta cada cifra).
- **AC-10.4** Cada cifra del reporte es trazable: tocarla muestra las transacciones que la componen.
- **AC-10.5** El reporte declara el año gravable y la versión de reglas fiscales usada (P5).

### RF-11 · Privacidad y control de datos

- **AC-11.1** El usuario puede desconectar Gmail (revoca token y detiene watch) sin perder sus transacciones.
- **AC-11.2** El usuario puede exportar todos sus datos (JSON + Excel).
- **AC-11.3** El usuario puede borrar su cuenta: eliminación total (transacciones, mensajes crudos, tokens) en ≤ 72 h, irreversible.
- **AC-11.4** El contenido crudo de correos/notificaciones se elimina automáticamente a los 90 días de procesado.

### RF-12 · Gastos fijos y recordatorios

*Como usuario, quiero registrar mis pagos fijos de cada mes (Spotify el 22, el arriendo el 5) para ver cuáles ya se pagaron y recibir un aviso antes de que me descuenten la plata.*

- **AC-12.1** Given un usuario con sesión, When registra un gasto fijo con nombre, monto exacto y día del mes (1–31), Then aparece en la lista del mes con su fecha de vencimiento; un día que el mes no tiene (31 en abril) vence el último día del mes (spec 011 §3).
- **AC-12.2** Given un gasto fijo pendiente, When la captura registra un gasto cuyo comercio contiene alguna palabra del nombre ("Spotify" en "SPOTIFY P3A9C1"), con el monto exacto y la fecha entre 5 días antes y 5 días después del vencimiento, Then la ocurrencia del mes queda pagada con esa transacción y la app la muestra tachada, sin importar el canal (Gmail, notificación, SMS, Apple Pay, manual o NFC).
- **AC-12.3** Given un gasto fijo creado después de que el pago del mes ya se capturó, Then la ocurrencia nace pagada (barrido retroactivo, spec 011 §4).
- **AC-12.4** Given una ocurrencia, Then el usuario puede marcarla como pagada sin movimiento, elegir el movimiento que la pagó, omitirla este mes o deshacer. Si deshace un emparejamiento automático, ese movimiento no se vuelve a emparejar solo con esa ocurrencia.
- **AC-12.5** Given una ocurrencia pendiente y el permiso de notificaciones concedido, When faltan 1 o 2 días para el vencimiento (lo elige el usuario), Then llega al celular una notificación push a las 09:00 hora de Colombia: "Se acerca tu pago de Spotify. El 22 de octubre se te descontarán $16.900 de tu cuenta." Si el pago ya se detectó o la ocurrencia se omitió, no llega.
- **AC-12.6** Given el permiso de notificaciones negado o revocado, Then los gastos fijos se siguen registrando y tachando; solo se pierde el aviso, y la pantalla explica cómo activarlo.
- **AC-12.7** Given el mismo evento de captura procesado varias veces, o el cron de avisos corriendo dos veces, Then hay a lo sumo un emparejamiento por transacción y a lo sumo un aviso por ocurrencia (P2).
- **AC-12.8** Given un gasto fijo, Then no crea transacciones ni suma en el dashboard ni en el reporte fiscal: el dinero lo cuenta solo la transacción capturada.

## B. Requisitos no funcionales

### RNF-1 · Seguridad
Detalle en spec 009. Resumen verificable:
- JWT de acceso ≤ 15 min; refresh rotativo con detección de reuso.
- Tokens de Gmail cifrados en reposo; TLS 1.2+ en todo tráfico.
- Rate limiting por usuario e IP en endpoints de auth e ingesta.
- 0 secretos en repo/app móvil (verificado con gitleaks en el gate del despliegue).

### RNF-2 · Escalabilidad
- API stateless: escalar = añadir réplicas; sin sesión en memoria.
- Parsing 100% en workers; un pico de N correos no degrada la latencia de la API (colas absorben).
- Objetivo de diseño MVP: 10.000 usuarios activos, ~50 correos/usuario/mes, picos de 100 mensajes/s en ingesta.
- `transactions` diseñada para particionado por fecha sin migración destructiva.

### RNF-3 · Rendimiento
- API p95 < 300 ms en endpoints de lectura (sin contar red móvil).
- Correo → transacción visible: < 60 s (p95). Notificación → transacción: < 10 s (p95).
- Cold start de la app < 2 s en gama media; listas con paginación incremental.

### RNF-4 · Disponibilidad y resiliencia
- Objetivo 99.5% mensual (MVP en 1 VPS; el diseño permite HA después).
- Caída del backend: Pub/Sub reintenta con backoff; al volver, `history.list` reconcilia lo perdido. La app opera offline (P4).
- Backups diarios cifrados de Postgres con restauración probada.

### RNF-5 · Costos operativos (MVP)
- LLM: presupuesto máximo por usuario/mes con corte automático (fallback: cola de revisión). Estimado: correo promedio ~1K tokens → DeepSeek V4 Flash ≈ $0.0002/correo.
- Infra objetivo MVP: 1 VPS (~$10–20/mes) + Pub/Sub (gratis a este volumen).

### RNF-6 · Compliance
Detalle en spec 010: verificación OAuth + CASA antes de superar 100 usuarios de Gmail; declaración de NotificationListener en Play Console; política de privacidad y tratamiento de datos (Ley 1581).

### RNF-7 · Calidad
- Cobertura de tests del dominio (dedupe, transferencias, fiscal, parsers) ≥ 90%.
- Antes de cada push a `main`, en local: lint (ruff / flutter analyze), tests y verificación de fronteras de módulos (import-linter) (`just lint`, `just test`, `just app-ci`). La auditoría de dependencias y gitleaks corren en GitHub como gate del despliegue del backend.
- Cada banco soportado tiene fixtures de correos/notificaciones reales anonimizados.

## C. Matriz de trazabilidad

| Requisito | Spec técnico | Fase (roadmap) |
|---|---|---|
| RF-1 | 003, 005, 009 | F1 |
| RF-2 | 005, 006 | F2, F3 |
| RF-3 | 006, 008 | F4 |
| RF-4 | 008 | F4 |
| RF-5 | 004, 006 | F2 |
| RF-6 | 004, 006 | F2 |
| RF-7 | 004, 005, 007 | F1, F5 |
| RF-8 | 005, 006, 008 | F2, F4 |
| RF-9 | 005, 008 | F4 |
| RF-10 | 007 | F5 |
| RF-11 | 005, 009, 010 | F1, F6 |
| RF-12 | 004, 005, 008, 009, 010, 011 | F7 |
| RNF-1..7 | 003, 009, 010 | transversal |
