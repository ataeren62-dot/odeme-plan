import SwiftUI
import WebKit
import UserNotifications

/// Shows the plan (web/index.html, bundled in the app) and connects it to iOS:
/// the plan is saved to a file, payment reminders become local notifications,
/// and backups open the share sheet.
struct PlanWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "native")

        // Hand the saved plan (or, on a first install, the bundled backup) to the page before it runs
        var boot = "window.__native=true;"
        if let saved = PlanStore.load() {
            boot += "window.__nativeState=\(saved);"
        }
        if let seedURL = Bundle.main.url(forResource: "odeme-yedek", withExtension: "json", subdirectory: "web"),
           let seed = try? String(contentsOf: seedURL, encoding: .utf8) {
            boot += "window.__seed=\(seed);"
        }
        controller.addUserScript(WKUserScript(source: boot, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.webView = webView

        if let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") {
            webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
            switch type {
            case "save":
                if let data = body["data"] as? String { PlanStore.save(data) }
            case "schedule":
                if let items = body["items"] as? [[String: Any]] {
                    Reminders.schedule(items) { [weak self] status in self?.reply("notif", status) }
                }
            case "share":
                if let name = body["name"] as? String, let text = body["text"] as? String {
                    share(name: name, text: text)
                }
            default:
                break
            }
        }

        private func reply(_ name: String, _ value: String) {
            DispatchQueue.main.async {
                let js = "window.__nativeReply&&window.__nativeReply(\(Self.jsString(name)),\(Self.jsString(value)))"
                self.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        /// A string as a JavaScript literal (via JSON, so quotes and newlines are escaped)
        private static func jsString(_ s: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [s]),
                  let array = String(data: data, encoding: .utf8) else { return "\"\"" }
            return String(array.dropFirst().dropLast())
        }

        private func share(name: String, text: String) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? text.write(to: url, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                guard let webView = self.webView, var top = webView.window?.rootViewController else { return }
                while let presented = top.presentedViewController { top = presented }
                let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                sheet.popoverPresentationController?.sourceView = webView
                top.present(sheet, animated: true)
            }
        }
    }
}

/// The plan, saved as JSON in the app's Documents folder
enum PlanStore {
    private static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("plan.json")
    }

    static func load() -> String? {
        guard let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty else { return nil }
        return text
    }

    static func save(_ text: String) {
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}

/// Replaces all pending reminders with: 18:00 the evening before, and 09:00 on the day of each payment
enum Reminders {
    static func schedule(_ items: [[String: Any]], completion: @escaping (String) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { completion("denied"); return }
            center.removeAllPendingNotificationRequests()

            let calendar = Calendar.current
            let now = Date()
            var count = 0
            for item in items {
                guard count < 60,
                      let id = item["id"] as? String,
                      let date = item["date"] as? String,
                      let title = item["title"] as? String else { continue }
                let body = item["body"] as? String ?? ""
                let parts = date.split(separator: "-").compactMap { Int($0) }
                guard parts.count == 3 else { continue }

                var morning = DateComponents()
                morning.year = parts[0]
                morning.month = parts[1]
                morning.day = parts[2]
                morning.hour = 9
                morning.minute = 0
                guard let dayOf = calendar.date(from: morning) else { continue }

                let fires: [(String, Date, String)] = [
                    ("\(id)-eve", dayOf.addingTimeInterval(-15 * 3600), "Yarın: \(title)"),
                    ("\(id)-day", dayOf, "Bugün: \(title)")
                ]
                for (key, when, heading) in fires where when > now && count < 60 {
                    let content = UNMutableNotificationContent()
                    content.title = heading
                    content.body = body
                    content.sound = .default
                    let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: when)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    center.add(UNNotificationRequest(identifier: key, content: content, trigger: trigger))
                    count += 1
                }
            }
            completion("ok:\(count)")
        }
    }
}
