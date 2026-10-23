import Foundation
import UIKit

enum FoldStage: String {
  case closed
  case halfOpen = "half_open"
  case fullyOpen = "fully_open"
  case unknown
}

enum ScreenOrientation: String {
  case portrait
  case landscape
  case unknown
}

struct FoldState {
  let stage: FoldStage
  let hingeAngle: Double
  let orientation: ScreenOrientation
  let timestampMs: Int64

  func toDictionary() -> [String: Any] {
    return [
      "stage": stage.rawValue,
      "hingeAngle": hingeAngle,
      "orientation": orientation.rawValue,
      "timestamp": timestampMs,
    ]
  }
}

/// Holds the latest fold posture and notifies `onUpdate` when it changes.
/// Fed by the SwiftUI hinge observer; shared so the observer and the channel
/// bridge talk to the same instance.
final class FoldStateMonitor {

  var onUpdate: ((FoldState) -> Void)?
  private(set) var lastState: FoldState?

  static let shared = FoldStateMonitor()

  func start() {
    if let lastState {
      deliver(lastState)
    }
  }

  func stop() {}

  func submit(stage: FoldStage, angle: Double, orientation: ScreenOrientation) {
    let state = FoldState(
      stage: stage,
      hingeAngle: angle,
      orientation: orientation,
      timestampMs: now()
    )

    let changed = lastState == nil
      || lastState?.stage != state.stage
      || lastState?.orientation != state.orientation

    lastState = state
    if changed {
      deliver(state)
    }
  }

  func updateOrientation(_ orientation: ScreenOrientation) {
    guard lastState?.orientation != orientation else { return }
    let previous = lastState
    let state = FoldState(
      stage: previous?.stage ?? .unknown,
      hingeAngle: previous?.hingeAngle ?? 0,
      orientation: orientation,
      timestampMs: now()
    )
    lastState = state
    deliver(state)
  }

  private func now() -> Int64 {
    Int64(Date().timeIntervalSince1970 * 1000)
  }

  private func deliver(_ state: FoldState) {
    if Thread.isMainThread {
      onUpdate?(state)
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.onUpdate?(state)
      }
    }
  }
}
