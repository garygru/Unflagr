import SwiftUI

@main
struct UnflagrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 300, height: 300)
        .windowResizability(.contentMinSize)
    }
}
