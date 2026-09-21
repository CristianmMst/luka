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


__all__ = [
    "AmountInvalid",
    "DateInvalid",
    "ParsingError",
    "TemplateConfigError",
    "TemplateExtractionInvalid",
]
