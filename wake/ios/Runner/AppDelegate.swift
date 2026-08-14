import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // App-local plugin: not a pub package, so it is not in the generated registrant.
    if let registrar = registrar(forPlugin: "WakeAlarmPlugin") {
      WakeAlarmPlugin.register(with: registrar)
    }

    // A force-quit during an alert loses the stop intent's callback. Catching up
    // here keeps the re-arm chain alive across launches.
    if #available(iOS 26.0, *) {
      Task { await WakeAlarmController.reconcile() }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
