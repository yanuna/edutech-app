import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyCover: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    setupContentProtection()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - Content protection (iOS)
  //
  // NOTE (honest limits): iOS gives apps NO API to block a still screenshot.
  // What we CAN do reliably is:
  //   1. Hide content in the app switcher / when backgrounded (privacy cover).
  //   2. Cover the screen while a screen RECORDING or AirPlay MIRRORING is
  //      active (UIScreen.isCaptured) — this blanks the recording.
  // A screenshot can be detected (userDidTakeScreenshot) but not prevented.
  // For guaranteed screenshot-blocking, Android's FLAG_SECURE is the real fix.

  private func setupContentProtection() {
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(obscure),
                   name: UIApplication.willResignActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(reveal),
                   name: UIApplication.didBecomeActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(captureChanged),
                   name: UIScreen.capturedDidChangeNotification, object: nil)
    captureChanged()
  }

  @objc private func captureChanged() {
    if UIScreen.main.isCaptured { obscure() } else { reveal() }
  }

  private func keyWindow() -> UIWindow? {
    return window
      ?? UIApplication.shared.connectedScenes
          .compactMap { ($0 as? UIWindowScene)?.keyWindow }
          .first
      ?? UIApplication.shared.windows.first
  }

  @objc private func obscure() {
    guard privacyCover == nil, let win = keyWindow() else { return }
    let cover = UIView(frame: win.bounds)
    cover.backgroundColor = .black
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.tag = 0x5EC0

    let label = UILabel(frame: cover.bounds)
    label.text = "🔒 Protected content hidden"
    label.textColor = .white
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16, weight: .semibold)
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.addSubview(label)

    win.addSubview(cover)
    win.bringSubviewToFront(cover)
    privacyCover = cover
  }

  @objc private func reveal() {
    // Keep the cover while a recording/mirroring session is still active.
    if UIScreen.main.isCaptured { return }
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
