import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    installHingeObserverWhenReady()
  }

  // The root FlutterViewController isn't always attached when the scene
  // connects, so retry until it is.
  private func installHingeObserverWhenReady(attempt: Int = 0) {
    if let root = window?.rootViewController {
      HingeObserverHosting.install(in: root)
      return
    }
    guard attempt < 20 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.installHingeObserverWhenReady(attempt: attempt + 1)
    }
  }
}
