"""Catalogo de categorias del sistema (spec 004 SS2.8.1). Solo stdlib (P3).

Espejo de dominio de los 24 registros que la migracion `0002_ledger_core`
inserta de forma literal (las migraciones no importan dominio: son snapshots
inmutables). Si este catalogo cambia, se necesita una migracion nueva.
"""

import uuid
from dataclasses import dataclass

from luka.modules.ledger.domain.enums import FiscalTag

_NAMESPACE = "https://luka.app/categories/{slug}"


def system_category_id(slug: str) -> uuid.UUID:
    """UUID deterministico (uuid5) de una categoria del sistema a partir de su slug."""
    return uuid.uuid5(uuid.NAMESPACE_URL, _NAMESPACE.format(slug=slug))


@dataclass(frozen=True, slots=True)
class SystemCategory:
    """Categoria del sistema: `user_id` siempre NULL en la tabla `categories`."""

    slug: str
    name: str
    fiscal_tag: FiscalTag
    id: uuid.UUID


def _row(slug: str, name: str, fiscal_tag: FiscalTag) -> SystemCategory:
    return SystemCategory(slug=slug, name=name, fiscal_tag=fiscal_tag, id=system_category_id(slug))


SYSTEM_CATEGORIES: tuple[SystemCategory, ...] = (
    _row("sin_categoria", "Sin categoría", FiscalTag.NO_DEDUCIBLE),
    _row("mercado", "Mercado y supermercado", FiscalTag.NO_DEDUCIBLE),
    _row("restaurantes", "Restaurantes y domicilios", FiscalTag.NO_DEDUCIBLE),
    _row("transporte", "Transporte y movilidad", FiscalTag.NO_DEDUCIBLE),
    _row("servicios_publicos", "Servicios públicos e internet", FiscalTag.NO_DEDUCIBLE),
    _row("arriendo", "Arriendo y administración", FiscalTag.NO_DEDUCIBLE),
    _row("compras", "Compras y ropa", FiscalTag.NO_DEDUCIBLE),
    _row("entretenimiento", "Entretenimiento y suscripciones", FiscalTag.NO_DEDUCIBLE),
    _row("salud", "Salud y farmacia", FiscalTag.NO_DEDUCIBLE),
    _row("educacion", "Educación", FiscalTag.NO_DEDUCIBLE),
    _row(
        "impuestos_comisiones",
        "Impuestos, comisiones y cuotas de manejo",
        FiscalTag.NO_DEDUCIBLE,
    ),
    _row("efectivo", "Retiros de efectivo", FiscalTag.NO_DEDUCIBLE),
    _row("medicina_prepagada", "Medicina prepagada y seguros de salud", FiscalTag.DEDUCIBLE_SALUD),
    _row("credito_vivienda", "Cuota crédito de vivienda", FiscalTag.DEDUCIBLE_VIVIENDA),
    _row(
        "pension_voluntaria",
        "Aportes voluntarios a pensión",
        FiscalTag.APORTE_PENSION_VOLUNTARIA,
    ),
    _row("afc", "Ahorro AFC", FiscalTag.APORTE_AFC),
    _row(
        "seguridad_social",
        "Salud y pensión obligatorias (PILA)",
        FiscalTag.APORTE_OBLIGATORIO,
    ),
    _row("donaciones", "Donaciones", FiscalTag.DONACION),
    _row("nomina", "Nómina y salario", FiscalTag.INGRESO_LABORAL),
    _row(
        "honorarios",
        "Honorarios y servicios independientes",
        FiscalTag.INGRESO_HONORARIOS,
    ),
    _row(
        "rendimientos",
        "Rendimientos, intereses y arriendos recibidos",
        FiscalTag.INGRESO_CAPITAL,
    ),
    _row("pension_recibida", "Mesada pensional", FiscalTag.INGRESO_PENSION),
    _row("otros_ingresos", "Otros ingresos", FiscalTag.INGRESO_NO_LABORAL),
    _row(
        "transferencias",
        "Transferencias entre cuentas propias",
        FiscalTag.TRANSFERENCIA,
    ),
)

SIN_CATEGORIA_ID: uuid.UUID = system_category_id("sin_categoria")
TRANSFERENCIAS_ID: uuid.UUID = system_category_id("transferencias")


def system_category_by_slug(slug: str) -> SystemCategory | None:
    """Devuelve la categoria del sistema con ese slug, o `None` si no existe."""
    for category in SYSTEM_CATEGORIES:
        if category.slug == slug:
            return category
    return None
