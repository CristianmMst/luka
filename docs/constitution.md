# Constitución del proyecto luka

Principios innegociables. Toda decisión de diseño, spec o implementación debe cumplirlos; si un cambio los contradice, se actualiza primero este documento mediante discusión explícita.

## P1 — Seguridad primero

Es una app de finanzas de uso masivo: maneja correos bancarios, tokens de Gmail y hábitos de gasto.

- Ningún secreto (API keys, tokens, claves de cifrado) vive en el repositorio ni en la app móvil; solo en el servidor, vía variables de entorno o secret manager.
- Tokens de terceros (Gmail refresh tokens) siempre cifrados en reposo (AES-GCM/Fernet).
- Todo endpoint autenticado por defecto; lo público es la excepción explícita.
- Los logs jamás contienen PII, contenido de correos, montos ni tokens.
- Dependencias auditadas en CI (pip-audit / osv-scanner); vulnerabilidad crítica bloquea release.

## P2 — El dedupe es sagrado

La misma compra puede llegar por 3 canales (correo, notificación, SMS). **Nunca debe existir una transacción duplicada.**

- La garantía final de unicidad es un índice único en PostgreSQL (huella de dedupe), no lógica de aplicación.
- Toda ingesta es idempotente: reprocesar el mismo mensaje N veces produce exactamente el mismo estado.

## P3 — Dominio puro y testeable

- La lógica de negocio (dedupe, matcher de transferencias, reglas fiscales, parsers) es código puro sin dependencias de framework, base de datos ni red.
- Cada regla de negocio tiene tests unitarios que corren sin infraestructura.
- Los módulos del backend solo se comunican por interfaces públicas o eventos de dominio; las fronteras se verifican con tooling (import-linter) en CI.

## P4 — Offline-first en la app

- La UI lee siempre de la base local (Drift); la red es un detalle de sincronización.
- La app debe ser 100% usable sin conexión (consultar, registrar manual, corregir categorías); la sincronización reconcilia al reconectar.

## P5 — Exactitud fiscal verificable

- Las reglas del formulario 210 y las tablas UVT viven en archivos de configuración versionados por año gravable, nunca hardcodeadas.
- Cada regla fiscal tiene casos de prueba con valores esperados calculados a mano.
- El reporte siempre indica el año gravable y la versión de reglas usada.
- Las transferencias entre cuentas propias jamás cuentan como ingreso ni gasto.

## P6 — Privacidad y habeas data (Ley 1581/2012)

- Consentimiento explícito antes de leer Gmail o notificaciones; cada permiso se pide en contexto y es revocable.
- El usuario puede exportar todos sus datos y borrar su cuenta con eliminación total e irreversible.
- El contenido crudo de correos/notificaciones se retiene solo lo necesario para reprocesos y auditoría (máx. 90 días) y luego se elimina.

## P7 — Escalar sin reescribir

- Monolito modular: fronteras de módulo pensadas para extraer servicios sin refactor masivo.
- API stateless (12-factor); cualquier estado compartido vive en Postgres/Redis.
- Trabajo pesado (parsing, LLM, reportes) siempre en workers asíncronos, nunca en el request path.

## P8 — Spec-Driven Development

- Ningún comportamiento se implementa sin spec que lo describa con criterios de aceptación.
- Si implementación y spec divergen, el spec se corrige en el mismo PR.
- Los specs no contienen "TBD": toda ambigüedad se resuelve antes de implementar.
