import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

/// Presentation for a firing Wake alarm.
///
/// The buttons themselves are drawn by AlarmKit from the AlarmPresentation
/// built in WakeAlarmController; this only supplies the surrounding content.
@available(iOS 26.0, *)
struct WakeAlarmLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<WakeAlarmMetadata>.self) { context in
      lockScreen(for: context.attributes.metadata)
        .padding()
        .activityBackgroundTint(.black.opacity(0.65))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "alarm.waves.left.and.right.fill")
            .font(.title2)
            .foregroundStyle(.orange)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.metadata.message)
              .font(.headline)
            Text("Solve the quiz to stop it")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      } compactLeading: {
        Image(systemName: "alarm.fill")
          .foregroundStyle(.orange)
      } compactTrailing: {
        Text("Wake")
          .font(.caption2)
      } minimal: {
        Image(systemName: "alarm.fill")
          .foregroundStyle(.orange)
      }
    }
  }

  @ViewBuilder
  private func lockScreen(for metadata: WakeAlarmMetadata) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "alarm.waves.left.and.right.fill")
        .font(.largeTitle)
        .foregroundStyle(.orange)
      VStack(alignment: .leading, spacing: 4) {
        Text(metadata.message)
          .font(.headline)
          .foregroundStyle(.white)
        // Stated up front so the Stop button does not read as a way out.
        Text("It comes back until you solve the quiz")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
      }
      Spacer()
    }
  }
}
