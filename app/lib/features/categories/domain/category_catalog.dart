/// Íconos que puede tener una categoría propia (se guardan por clave en
/// `categories.icon`; la presentación los traduce a Material). El primero es
/// el de por defecto.
const categoryIconKeys = <String>[
  'label',
  'pets',
  'cart',
  'home',
  'health',
  'car',
  'coffee',
  'book',
  'gift',
  'flight',
  'phone',
  'bolt',
  'music',
  'fitness',
  'clothes',
  'school',
];

/// Colores de la paleta "Esmeralda andina" para categorías propias; todos
/// dejan un ícono blanco con contraste AA. El primero es el de por defecto.
const categoryColors = <String>[
  '#0E4D3F',
  '#17774E',
  '#45617A',
  '#B4432B',
  '#8A6A00',
  '#6B4C9A',
  '#A23B6B',
  '#3F4F48',
];

/// Etiqueta fiscal por defecto: no altera el reporte de renta.
const defaultFiscalTag = 'no_deducible';

enum FiscalGroup { expenses, contributions, income }

typedef FiscalTagGroup = ({FiscalGroup group, List<String> tags});

/// Etiquetas fiscales (spec 007 §2) que puede elegir el usuario, en el orden
/// del selector. `transferencia` no está: la da el tipo del movimiento.
const userFiscalTagGroups = <FiscalTagGroup>[
  (
    group: FiscalGroup.expenses,
    tags: ['no_deducible', 'deducible_salud', 'deducible_vivienda', 'donacion'],
  ),
  (
    group: FiscalGroup.contributions,
    tags: ['aporte_pension_voluntaria', 'aporte_afc', 'aporte_obligatorio'],
  ),
  (
    group: FiscalGroup.income,
    tags: [
      'ingreso_laboral',
      'ingreso_honorarios',
      'ingreso_capital',
      'ingreso_pension',
      'ingreso_no_laboral',
    ],
  ),
];

bool isUserFiscalTag(String tag) =>
    userFiscalTagGroups.any((g) => g.tags.contains(tag));
