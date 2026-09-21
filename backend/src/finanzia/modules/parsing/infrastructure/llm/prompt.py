"""Prompt fijo (cacheable) del LLM de parsing (spec 006 §4.2).

`SYSTEM_PROMPT` nunca cambia por request (system prompt cacheable, control de
costo): no lleva ids ni datos del usuario, solo instrucciones de extraccion.
`build_user_message` es lo unico variable por llamada y solo incluye el
extracto del mensaje bancario y la fecha de recepcion (P1: nunca `user_id`,
remitente ni `raw_message_id`).
"""

from __future__ import annotations

from datetime import date

_KNOWN_BANKS: tuple[str, ...] = (
    "bancolombia",
    "nequi",
    "davivienda",
    "daviplata",
    "bbva",
    "banco_bogota",
    "other",
)

# Slugs de categorias del sistema (spec 004 §2.9 / migracion 0002_ledger_core):
# se hardcodean aqui a proposito (parsing no puede importar `ledger`, R4).
_SYSTEM_CATEGORY_SLUGS: tuple[str, ...] = (
    "sin_categoria",
    "mercado",
    "restaurantes",
    "transporte",
    "servicios_publicos",
    "arriendo",
    "compras",
    "entretenimiento",
    "salud",
    "educacion",
    "impuestos_comisiones",
    "efectivo",
    "medicina_prepagada",
    "credito_vivienda",
    "pension_voluntaria",
    "afc",
    "seguridad_social",
    "donaciones",
    "nomina",
    "honorarios",
    "rendimientos",
    "pension_recibida",
    "otros_ingresos",
    "transferencias",
)

SYSTEM_PROMPT = (
    "Eres un extractor de datos financieros para mensajes bancarios colombianos "
    "(correos y notificaciones push de bancos). Vas a recibir el fragmento relevante "
    "de un mensaje y la fecha en que se recibio. Debes responder EXCLUSIVAMENTE con un "
    "JSON estricto (sin texto adicional, sin markdown, sin explicaciones), con "
    "exactamente este esquema:\n"
    "{\n"
    '  "is_transaction": bool,\n'
    '  "amount": string o null,\n'
    '  "currency": string o null,\n'
    '  "direction": "debit", "credit" o null,\n'
    '  "merchant": string o null,\n'
    '  "occurred_at": string ISO 8601 con offset o null,\n'
    '  "bank": string o null,\n'
    '  "last4": string o null,\n'
    '  "suggested_category": string o null,\n'
    '  "confidence": numero entre 0 y 1\n'
    "}\n\n"
    "Reglas:\n"
    "- Si el mensaje NO describe un movimiento de dinero (no es una transaccion), "
    'responde "is_transaction": false y deja en null el resto de campos (salvo '
    '"confidence").\n'
    "- Los montos en mensajes colombianos usan el punto como separador de miles y la "
    'coma como separador decimal (formato "$1.234.567,89"). Devuelve "amount" siempre '
    'como un string plano en formato decimal con punto ("1234567.89"), sin separador '
    "de miles y sin simbolo de moneda.\n"
    "- Nunca inventes un dato que no este explicito en el mensaje: si un campo no "
    "aparece o no estas seguro, devuelve null para ese campo.\n"
    f'- "bank" debe ser uno de: {", ".join(_KNOWN_BANKS)}. Si no puedes determinarlo '
    'con certeza o es un banco fuera de esta lista, usa "other".\n'
    '- "suggested_category", si aplica, debe ser exactamente uno de estos slugs del '
    f"sistema: {', '.join(_SYSTEM_CATEGORY_SLUGS)}. Si no estas seguro, deja null.\n"
    '- "occurred_at" es la fecha/hora en que ocurrio la transaccion (no la fecha de '
    "recepcion), en formato ISO 8601 con offset (Colombia usa -05:00). Si el mensaje no "
    "trae hora, usa la fecha de recepcion que se te da.\n"
    '- "confidence" refleja tu certeza de que la extraccion completa es correcta, '
    "entre 0 y 1.\n"
    "- Responde SOLO el JSON, nada mas."
)


def build_user_message(excerpt: str, received_on: date) -> str:
    """Unico contenido variable por llamada: el extracto y la fecha de recepcion.

    Nunca incluye `user_id`, remitente ni `raw_message_id` (P1, spec 009 §1).
    """
    return f"Fecha de recepción: {received_on.isoformat()}\nMensaje:\n{excerpt}"


__all__ = ["SYSTEM_PROMPT", "build_user_message"]
