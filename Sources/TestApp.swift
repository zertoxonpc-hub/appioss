import SwiftUI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("CA MARCHE BELLE EST BIEN")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}