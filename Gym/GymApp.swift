import SwiftUI
import SwiftData

@main
struct GymApp: App {
    @State private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .modelContainer(dataController.container)
                .task {
                    await dataController.seedIfNeeded()
                }
        }
    }
}
