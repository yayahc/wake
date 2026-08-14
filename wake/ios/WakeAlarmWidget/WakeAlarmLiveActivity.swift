import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

/// Live Activity presentation for the AlarmKit alert.
///
/// AlarmKit drives this: `ContentState` is `AlarmPresentationState`, and the
/// Stop / Solve quiz buttons are rendered by the system from the
/// `AlarmPresentation` supplied in `WakeAlarmController.schedule`. This view only
/// supplies the surrounding chrome.
@available(iOS 26.0, *)
struct WakeAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<WakeAlarmMetadata>.self) { context in
            lockScreen(for: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .foregroundStyle(context.attributes.tintColor)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(message(for: context))
                        .font(.headline)
                        .lineLimit(2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(subtitle(for: context))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                Text(retryBadge(for: context))
                    .font(.caption2)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            }
        }
    }

    // MARK: - Lock screen

    @ViewBuilder
    private func lockScreen(
        for context: ActivityViewContext<AlarmAttributes<WakeAlarmMetadata>>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.title2)
                .foregroundStyle(context.attributes.tintColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(message(for: context))
                    .font(.headline)
                    .lineLimit(2)
                Text(subtitle(for: context))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Text

    private func message(
        for context: ActivityViewContext<AlarmAttributes<WakeAlarmMetadata>>
    ) -> String {
        let message = context.attributes.metadata?.message ?? ""
        return message.isEmpty ? "Wake up" : message
    }

    private func subtitle(
        for context: ActivityViewContext<AlarmAttributes<WakeAlarmMetadata>>
    ) -> String {
        switch context.state.mode {
        case .alert:
            return "Solve the quiz to stop this alarm."
        case .countdown(let countdown):
            return "Rings \(countdown.fireDate.formatted(date: .omitted, time: .shortened))"
        case .paused:
            return "Paused"
        @unknown default:
            return "Solve the quiz to stop this alarm."
        }
    }

    private func retryBadge(
        for context: ActivityViewContext<AlarmAttributes<WakeAlarmMetadata>>
    ) -> String {
        switch context.state.mode {
        case .countdown(let countdown):
            return countdown.fireDate.formatted(date: .omitted, time: .shortened)
        default:
            return "!"
        }
    }
}