import Flutter
import Foundation
import UIKit

/// Cola de pagos con Apple Pay (F4.3b, spec 006 §3.3). La llena la App
/// Intent `RegistrarPagoWallet` cuando la automatización "Transacción" de
/// Atajos corre al pagar, y la vacía Dart (`IosWalletNotificationSource`)
/// al abrir la app. Es un archivo JSON en Application Support, protegido
/// hasta el primer desbloqueo: la intent corre en el proceso de la app, sin
/// extensión ni App Group.
final class WalletQueue {
  static let shared = WalletQueue()

  /// Como la cola de Android (spec 006 §3.2): lo más viejo se descarta.
  private let maxItems = 5000
  private let lock = NSLock()

  private struct Item: Codable {
    let id: Int
    let card: String
    let merchant: String
    let amount: String
    let postedAtMs: Int64
    let offsetMinutes: Int
  }

  private struct Store: Codable {
    /// Usuario en sesión. Sin él (sesión cerrada) no se guarda nada.
    var owner: String?
    var nextId: Int
    var items: [Item]
  }

  private var fileURL: URL {
    let base = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("wallet_queue.json")
  }

  /// Guarda un pago; `false` si no hay sesión a la cual asignarlo.
  func append(card: String, merchant: String, amount: String, at date: Date) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    var store = load()
    guard store.owner != nil else { return false }
    let offset = TimeZone.current.secondsFromGMT(for: date) / 60
    store.items.append(
      Item(
        id: store.nextId,
        card: card,
        merchant: merchant,
        amount: amount,
        postedAtMs: Int64(date.timeIntervalSince1970 * 1000),
        offsetMinutes: offset))
    store.nextId += 1
    if store.items.count > maxItems {
      store.items.removeFirst(store.items.count - maxItems)
    }
    save(store)
    return true
  }

  func pending(limit: Int) -> [[String: Any]] {
    lock.lock()
    defer { lock.unlock() }
    return load().items.prefix(limit).map { item -> [String: Any] in
      [
        "id": item.id,
        "card": item.card,
        "merchant": item.merchant,
        "amount": item.amount,
        "postedAtMs": item.postedAtMs,
        "offsetMinutes": item.offsetMinutes,
      ]
    }
  }

  func remove(ids: [Int]) {
    lock.lock()
    defer { lock.unlock() }
    var store = load()
    let drop = Set(ids)
    store.items.removeAll { drop.contains($0.id) }
    save(store)
  }

  /// Deja la cola a [userId]: si lo guardado era de otro, lo borra (P6).
  func claim(for userId: String) {
    lock.lock()
    defer { lock.unlock() }
    var store = load()
    if store.owner != userId {
      store = Store(owner: userId, nextId: store.nextId, items: [])
    }
    save(store)
  }

  /// Cierre de sesión: se borra la cola y se deja de guardar.
  func clear() {
    lock.lock()
    defer { lock.unlock() }
    try? FileManager.default.removeItem(at: fileURL)
  }

  private func load() -> Store {
    guard let data = try? Data(contentsOf: fileURL),
      let store = try? JSONDecoder().decode(Store.self, from: data)
    else { return Store(owner: nil, nextId: 1, items: []) }
    return store
  }

  private func save(_ store: Store) {
    let url = fileURL
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let data = try? JSONEncoder().encode(store) else { return }
    try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
}

/// `MethodChannel("co.luka/capture")` de iOS: el mismo nombre que el
/// listener de Android, con los métodos que usa `IosWalletNotificationSource`.
enum WalletCaptureChannel {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "co.luka/capture", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      let queue = WalletQueue.shared
      switch call.method {
      case "pending":
        result(queue.pending(limit: args["limit"] as? Int ?? 50))
      case "remove":
        queue.remove(ids: args["ids"] as? [Int] ?? [])
        result(nil)
      case "claimFor":
        guard let userId = args["userId"] as? String else {
          result(FlutterError(code: "bad_args", message: "userId", details: nil))
          return
        }
        queue.claim(for: userId)
        result(nil)
      case "clear":
        queue.clear()
        result(nil)
      case "openShortcuts":
        guard let url = URL(string: "shortcuts://") else {
          result(FlutterError(code: "unavailable", message: nil, details: nil))
          return
        }
        UIApplication.shared.open(url) { opened in
          result(
            opened ? nil : FlutterError(code: "unavailable", message: nil, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
