import SwiftUI
import UIKit

// onHingeChange / DeviceHinge require the iOS 27.1 SDK.
#if canImport(SwiftUI, _version: 8.0.85)

@available(iOS 27.1, *)
private struct HingeObserverView: View {
  @State private var size: CGSize = .zero

  var body: some View {
    Color.clear
      .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
      } action: { newSize in
        size = newSize
        FoldStateMonitor.shared.updateOrientation(orientation(for: newSize))
      }
      .onHingeChange { _, newContext in
        let reading = newContext.hinge
        let stage: FoldStage
        let angleDegrees: Double

        if let reading {
          switch reading.status {
          case .closed:
            stage = .closed
          case .partiallyOpen:
            stage = .halfOpen
          case .fullyOpen:
            stage = .fullyOpen
          default:
            stage = .unknown
          }
          angleDegrees = reading.angle.degrees
        } else {
          stage = .unknown
          angleDegrees = 0
        }

        FoldStateMonitor.shared.submit(
          stage: stage,
          angle: angleDegrees,
          orientation: orientation(for: size)
        )
      }
  }

  private func orientation(for size: CGSize) -> ScreenOrientation {
    guard size != .zero else { return .unknown }
    return size.width > size.height ? .landscape : .portrait
  }
}

#endif

enum HingeObserverHosting {
  static func install(in parent: UIViewController) {
    #if canImport(SwiftUI, _version: 8.0.85)
    guard #available(iOS 27.1, *) else { return }

    let host = UIHostingController(rootView: HingeObserverView())
    host.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.isUserInteractionEnabled = false
    host.view.backgroundColor = .clear
    host.view.alpha = 0.001

    parent.addChild(host)
    parent.view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: parent.view.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
    ])
    host.didMove(toParent: parent)
    #endif
  }
}
