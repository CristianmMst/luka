# Spec 007 — Motor fiscal (Colombia, formulario 210)

## 1. Alcance

El motor fiscal produce el **insumo de la declaración de renta de personas naturales** (formulario 210): cifras agregadas del año gravable organizadas por cédulas y conceptos, más la verificación de topes de obligación de declarar. **No** liquida el impuesto final ni presenta ante la DIAN (fuera de alcance MVP, spec 001 §5).

Disclaimer obligatorio en UI y exportes: *"Este reporte es un insumo informativo; verifica las cifras con tu contador. finanzia no presta asesoría tributaria."*

## 2. Etiquetas fiscales (`fiscal_tag`)

Toda categoría lleva exactamente una etiqueta. Enum cerrado (ampliable por versión de reglas):

| fiscal_tag | Descripción | Ejemplos de categorías |
|---|---|---|
| `ingreso_laboral` | Salarios y pagos laborales | nómina |
| `ingreso_honorarios` | Honorarios/servicios independientes | pagos de clientes |
| `ingreso_capital` | Rendimientos, intereses, arriendos recibidos | intereses CDT |
| `ingreso_no_laboral` | Otros ingresos | ventas ocasionales |
| `ingreso_pension` | Pensiones | mesada pensional |
| `deducible_salud` | Medicina prepagada / seguros de salud | prepagada |
| `deducible_vivienda` | Intereses de crédito hipotecario / leasing habitacional | cuota crédito vivienda (componente intereses) |
| `aporte_pension_voluntaria` | Aportes voluntarios a pensión | AFP voluntaria |
| `aporte_afc` | Cuentas AFC | ahorro AFC |
| `aporte_obligatorio` | Salud/pensión obligatorias (informativo INCRNGO) | PILA independiente |
| `donacion` | Donaciones certificables | ONGs |
| `no_deducible` | Gasto ordinario sin efecto fiscal | mercado, restaurantes... |
| `transferencia` | Implícita en `kind=transfer`; excluida de todo | — |

Notas de asignación automática: los intereses de vivienda suelen requerir separar capital/intereses — el MVP clasifica la cuota completa como candidata y el reporte la lista con advertencia "verificar componente de intereses con el certificado del banco". Igual criterio para dependientes (no detectable): entrada manual en Ajustes → reporte.

## 3. Configuración por año gravable

Archivo versionado `fiscal/config/co_<año>.yaml` (P5: nada hardcodeado):

```yaml
version: co-2025.1
tax_year: 2025
uvt_value: 49799            # COP por UVT del año gravable (ejemplo; se fija con el valor oficial DIAN)
filing_thresholds_uvt:      # topes de obligación de declarar (art. 592 ET y reglamentos del año)
  patrimonio_bruto: 4500
  ingresos_brutos: 1400
  consumos_tc: 1400
  compras_consumos: 1400
  consignaciones: 1400
limits_uvt:                 # límites de beneficios del año
  deduccion_vivienda_anual: 1200
  salud_prepagada_mensual: 16
  aportes_voluntarios_pct: 0.30      # % ingreso, con tope
  aportes_voluntarios_uvt: 3800
  rentas_exentas_pct_general: 0.25   # renta exenta laboral 25%
  rentas_exentas_tope_uvt: 790
cedulas:
  general:
    subcedulas: [laboral, capital, no_laboral]
  pensiones: {}
  dividendos: {}            # MVP: solo listado informativo si se detectan
```

- Los valores UVT/topes del ejemplo son placeholder de estructura; **cada año se cargan de la resolución oficial de la DIAN** y se validan con casos de prueba calculados a mano (P5).
- `rules_version` acompaña cada reporte generado (AC-10.5).

## 4. Algoritmo del reporte

Entrada: `user_id`, `tax_year`. Universo: transacciones con `occurred_at` en el año gravable, excluyendo `kind=transfer`.

1. **Ingresos**: agrupar `kind=income` por `fiscal_tag` → mapear a cédula/subcédula según config.
2. **INCRNGO** (informativo): `aporte_obligatorio`.
3. **Deducciones y rentas exentas detectadas**: sumar `deducible_salud`, `deducible_vivienda`, `aporte_pension_voluntaria`, `aporte_afc`, `donacion`, aplicando límites UVT del año (mensual para prepagada, anual para vivienda, % + tope para voluntarios). El reporte muestra **ambos** valores: detectado y limitado.
4. **Datos manuales**: dependientes (checkbox + número), patrimonio declarado por el usuario (opcional, para el tope) — formulario en Ajustes → sección fiscal.
5. **Topes de obligación de declarar** (AC-10.2): comparar ingresos brutos, consumos con tarjeta (suma de débitos `credit_card`), consignaciones (suma de créditos) y patrimonio manual contra `filing_thresholds_uvt × uvt_value`; resultado por criterio: superado/no superado.
6. **Salida** (`payload` JSONB + Excel):

```json
{
  "tax_year": 2025,
  "rules_version": "co-2025.1",
  "uvt_value": "49799",
  "obligation_check": {
    "ingresos_brutos": {"value": "82500000.00", "threshold": "69718600.00", "exceeded": true},
    "consumos_tc":     {"value": "31200000.00", "threshold": "69718600.00", "exceeded": false}
  },
  "cedula_general": {
    "ingresos": {
      "laboral":    {"total": "78000000.00", "transaction_count": 24},
      "honorarios": {"total": "4500000.00",  "transaction_count": 6}
    },
    "deducciones": {
      "salud_prepagada":   {"detected": "5400000.00", "capped": "5400000.00", "limit_desc": "16 UVT/mes"},
      "intereses_vivienda":{"detected": "14200000.00", "capped": "14200000.00", "warning": "verificar componente de intereses"}
    }
  },
  "traceability": { "cedula_general.ingresos.laboral": ["tx_id...", "..."] }
}
```

7. **Trazabilidad** (AC-10.4): cada cifra lista los `transaction_ids` que la componen; la app permite navegar de cifra → transacciones.

## 5. Excel de exportación (AC-10.3)

- Hoja 1 "Resumen 210": tabla por cédula/concepto con valores detectados/limitados, topes y advertencias.
- Hoja 2 "Detalle": todas las transacciones del año con fecha, comercio, monto, categoría, fiscal_tag, fuente.
- Hoja 3 "Parámetros": año, versión de reglas, valor UVT, fecha de generación, disclaimer.
- Generación con openpyxl en worker (job async, spec 005 §8).

## 6. Casos de prueba obligatorios (P5)

1. Usuario con solo nómina → toda la cifra en cédula general/laboral; deducciones cero.
2. Prepagada que excede 16 UVT/mes → `capped < detected`.
3. Transferencias entre cuentas propias en el año → no aparecen en ninguna cifra (AC-6.2).
4. Ingresos justo en el tope de 1400 UVT → `exceeded: false`; +1 COP → `true`.
5. Año sin config cargada → error explícito `rules_not_available`, nunca cifras vacías silenciosas.
6. Reporte regenerado con la misma data → idéntico (determinismo).
