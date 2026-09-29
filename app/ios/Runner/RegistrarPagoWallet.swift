import AppIntents
import Foundation

/// Acción "Registrar pago en finanzia" de Atajos (F4.3b, spec 006 §3.3). La
/// automatización "Transacción" (iOS 17+) la corre al pagar con Wallet y le
/// pasa tarjeta, comercio y monto; aquí solo se encola, sin abrir la app.
/// El texto que parsea el backend lo arma Dart al enviar.
@available(iOS 16.0, *)
struct RegistrarPagoWallet: AppIntent {
  static var title: LocalizedStringResource = "Registrar pago en finanzia"
  static var description = IntentDescription(
    "Guarda un pago con Apple Pay; finanzia lo envía cuando abres la app.")
  static var openAppWhenRun = false

  @Parameter(title: "Tarjeta")
  var tarjeta: String

  @Parameter(title: "Comercio")
  var comercio: String

  @Parameter(title: "Monto")
  var monto: String

  static var parameterSummary: some ParameterSummary {
    Summary("Registrar \(\.$monto) en \(\.$comercio) con \(\.$tarjeta)")
  }

  func perform() async throws -> some IntentResult {
    guard
      WalletQueue.shared.append(
        card: tarjeta, merchant: comercio, amount: monto, at: Date())
    else { throw WalletIntentError.signedOut }
    return .result()
  }
}

@available(iOS 16.0, *)
enum WalletIntentError: Error, CustomLocalizedStringResourceConvertible {
  case signedOut

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .signedOut: return "Abre finanzia e inicia sesión para registrar tus pagos."
    }
  }
}
