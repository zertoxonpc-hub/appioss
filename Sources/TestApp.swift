import SwiftUI
import UserNotifications

class NotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

let notifDelegate = NotifDelegate()

@main
struct TestApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var auth = Auth()
    @StateObject private var bank = Bank()

    init() {
        UNUserNotificationCenter.current().delegate = notifDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if auth.unlocked {
                    MainView().environmentObject(bank)
                } else {
                    LockView().environmentObject(auth)
                }
            }
            .onAppear { auth.authenticate() }
            .onChange(of: scenePhase) { phase in
                if phase == .background { auth.lock() }
                if phase == .active { auth.authenticate() }
            }
        }
    }
}