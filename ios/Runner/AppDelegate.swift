import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var gameServicesBridge: GameServicesBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let bridge = GameServicesBridge(
      messenger: engineBridge.applicationRegistrar.messenger(),
      presenterProvider: { [weak self] in self?.activeRootViewController() }
    )
    gameServicesBridge = bridge
    bridge.initializeSilently()
  }

  private func activeRootViewController() -> UIViewController? {
    for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
      if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
        return root
      }
    }
    return window?.rootViewController
  }
}
