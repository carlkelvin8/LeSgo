import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var mapsAPIKeyConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsKey.isEmpty,
       !mapsKey.hasPrefix("$(") {
      mapsAPIKeyConfigured = GMSServices.provideAPIKey(mapsKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.lesgo.app/google_maps",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "configure" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let self = self else {
        result(FlutterError(code: "APP_UNAVAILABLE", message: "App delegate unavailable", details: nil))
        return
      }

      if self.mapsAPIKeyConfigured {
        result(true)
        return
      }

      guard let arguments = call.arguments as? [String: Any],
            let apiKey = arguments["apiKey"] as? String,
            !apiKey.isEmpty,
            !apiKey.hasPrefix("YOUR_"),
            !apiKey.hasPrefix("your-"),
            !apiKey.hasPrefix("$(") else {
        result(false)
        return
      }

      self.mapsAPIKeyConfigured = GMSServices.provideAPIKey(apiKey)
      result(self.mapsAPIKeyConfigured)
    }
  }
}
