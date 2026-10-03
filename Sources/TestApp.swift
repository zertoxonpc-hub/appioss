import SwiftUI
import UserNotifications

// Permet d'afficher la notification même quand l'app est ouverte
class NotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

let notifDelegate = NotifDelegate()

func envoyerNotification() {
    let contenu = UNMutableNotificationContent()
    contenu.title = "TestApp"
    contenu.body = "CA MARCHE BELLE EST BIEN"
    contenu.sound = .default

    let declencheur = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let requete = UNNotificationRequest(identifier: UUID().uuidString,
                                        content: contenu,
                                        trigger: declencheur)
    UNUserNotificationCenter.current().add(requete)
}

@main
struct TestApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = notifDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                Button(action: envoyerNotification) {
                    Text("Envoyer la notification")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(14)
                }
            }
        }
    }
}