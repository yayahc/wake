import AlarmKit
import Flutter
import Foundation
import UIKit

/// Method channel bridge between Flutter and `WakeAlarmController`.
///
/// This file imports Flutter and must stay out of the widget extension target.
/// The controller, store and intents are shared with the extension because the
/// intents run outside the app process and still need to re-arm.
final class WakeAlarmPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: WakeAlarmIdentity.methodChannel,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(WakeAlarmPlugin(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 26.0, *) else {
            result(FlutterError(
                code: "unsupported",
                message: "AlarmKit requires iOS 26 or later.",
                details: nil
            ))
            return
        }

        switch call.method {
        case "requestAuthorization":
            Task {
                let granted = await WakeAlarmController.requestAuthorization()
                await MainActor.run { result(granted) }
            }

        case "schedule":
            guard let args = call.arguments as? [String: Any],
                  let alarmId = args["alarmId"] as? Int,
                  let message = args["message"] as? String,
                  let ringAtMillis = args["ringAtMillis"] as? NSNumber
            else {
                result(Self.badArguments("schedule"))
                return
            }
            let ringAt = Date(timeIntervalSince1970: ringAtMillis.doubleValue / 1000)
            Task {
                do {
                    let id = try await WakeAlarmController.arm(
                        alarmId: alarmId,
                        message: message,
                        ringAt: ringAt
                    )
                    await MainActor.run { result(id.uuidString) }
                } catch {
                    await MainActor.run {
                        result(FlutterError(
                            code: "schedule_failed",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }

        case "cancel":
            guard let args = call.arguments as? [String: Any],
                  let alarmId = args["alarmId"] as? Int
            else {
                result(Self.badArguments("cancel"))
                return
            }
            Task {
                try? await WakeAlarmController.cancelAll(alarmId: alarmId)
                await MainActor.run { result(nil) }
            }

        case "pendingQuiz":
            result(WakeAlarmController.pendingQuiz().map(Self.encode))

        case "markQuizSolved":
            guard let args = call.arguments as? [String: Any],
                  let idString = args["id"] as? String,
                  let id = UUID(uuidString: idString)
            else {
                result(Self.badArguments("markQuizSolved"))
                return
            }
            WakeAlarmController.markQuizSolved(id: id)
            result(nil)

        case "reconcile":
            Task {
                await WakeAlarmController.reconcile()
                await MainActor.run { result(nil) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helpers

    @available(iOS 26.0, *)
    private static func encode(_ record: WakeAlarmRecord) -> [String: Any] {
        [
            "id": record.id.uuidString,
            "alarmId": record.alarmId,
            "message": record.message,
            "ringAtMillis": Int(record.ringAt.timeIntervalSince1970 * 1000),
            "retryCount": record.retryCount,
        ]
    }

    private static func badArguments(_ method: String) -> FlutterError {
        FlutterError(
            code: "bad_arguments",
            message: "Missing or malformed arguments for \(method).",
            details: nil
        )
    }
}