import SwiftUI
import LocalAuthentication

final class Auth: ObservableObject {
    @Published var unlocked = false
    private var busy = false

    func authenticate() {
        guard !unlocked, !busy else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            unlocked = true
            return
        }
        busy = true
        ctx.evaluatePolicy(.deviceOwnerAuthentication,
                           localizedReason: "Déverrouiller ta banque") { ok, _ in
            DispatchQueue.main.async {
                self.busy = false
                if ok { self.unlocked = true }
            }
        }
    }

    func lock() { unlocked = false }
}