import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Oggi", systemImage: "figure.run", value: AppTab.today) {
                TodayView()
            }

            Tab("Programma", systemImage: "calendar", value: AppTab.program) {
                ProgramView()
            }

            Tab("Esercizi", systemImage: "list.bullet.clipboard", value: AppTab.exercises) {
                ExercisesView()
            }

            Tab("Progressi", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.progress) {
                GymProgressView()
            }

            Tab("Profilo", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

enum AppTab: Hashable {
    case today, program, exercises, progress, profile
}

#Preview {
    ContentView()
        .modelContainer(DataController.previewContainer)
}
