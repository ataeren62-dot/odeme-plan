import SwiftUI
import UserNotifications

@main
struct OdemePlaniApp: App {
    init() {
        // Show reminders as banners even while the app is open
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            PlanWebView()
                .ignoresSafeArea()
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
