import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Avisos locales de gastos fijos (spec 011 §5.1): con este delegado iOS
    // los muestra también con la app abierta y avisa cuando se tocan.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // Cola de pagos con Apple Pay (F4.3b, spec 006 §3.3).
    if let registrar = self.registrar(forPlugin: "WalletCapture") {
      WalletCaptureChannel.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
