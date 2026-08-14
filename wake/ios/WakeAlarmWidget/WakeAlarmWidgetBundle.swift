import SwiftUI
import WidgetKit

/// AlarmKit renders its alert through ActivityKit, so without this extension
/// the alarm has no UI on the lock screen or in the Dynamic Island.
@main
struct WakeAlarmWidgetBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 26.0, *) {
      WakeAlarmLiveActivity()
    }
  }
}
