"""Errores de dominio de parsing (stdlib puro, P3)."""


class ParsingError(Exception):
    """Error base de dominio de parsing."""


class AmountInvalid(ParsingError):  # noqa: N818 - nombre descriptivo, no de excepcion generica
    """`parse_amount` no pudo derivar un monto valido (> 0)."""


class DateInvalid(ParsingError):  # noqa: N818
    """`parse_local_datetime` no pudo derivar una fecha/hora valida."""


class TemplateConfigError(ParsingError):
    """Config de plantillas/allowlists invalida (regex, campos faltantes, tipos)."""


class TemplateExtractionInvalid(ParsingError):  # noqa: N818
    """Una plantilla matcheo pero el post-proceso produjo datos invalidos:
    monto invalido o `occurred_at` fuera de `received_at +/- 7 dias`.
    """


class LlmUnavailable(ParsingError):  # noqa: N818
    """El adapter del LLM no pudo completar la llamada (timeout/5xx/red, D11).

    `ParseRawMessage` la traduce de inmediato a `ParseFailed(reason=llm_error)`
    en vez de dejarla propagar (evita reintentos ciegos + DLQ opaca).
    """


__all__ = [
    "AmountInvalid",
    "DateInvalid",
    "LlmUnavailable",
    "ParsingError",
    "TemplateConfigError",
    "TemplateExtractionInvalid",
]
