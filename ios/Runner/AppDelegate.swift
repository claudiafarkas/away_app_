import Flutter
import UIKit
import GoogleMaps


@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pendingSharedUrl: String?
  private var shareIntentChannel: FlutterMethodChannel?

  private func configureShareIntentChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(name: "away/share_intent", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "getInitialSharedUrl":
        result(self.pendingSharedUrl)
        self.pendingSharedUrl = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    shareIntentChannel = channel
  }

  private func captureSharedUrl(from url: URL) -> Bool {
    if url.scheme?.lowercased() == "away", url.host?.lowercased() == "import" {
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
         let value = components.queryItems?.first(where: { $0.name == "url" })?.value,
         !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        pendingSharedUrl = value
        return true
      }
    }
    return false
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide Google Maps API key before registering plugins.
    // Value comes from ios/Flutter/Secrets.xcconfig (gitignored).
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    if let launchUrl = launchOptions?[.url] as? URL {
      _ = captureSharedUrl(from: launchUrl)
    }

    configureShareIntentChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if captureSharedUrl(from: url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
