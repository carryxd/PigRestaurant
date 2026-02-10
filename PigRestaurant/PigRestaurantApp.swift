import SwiftUI
import SwiftData

@main
struct PigRestaurantApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [DishCategory.self, Dish.self]) { result in
            switch result {
            case .success(let container):
                SeedData.seedIfNeeded(context: container.mainContext)
            case .failure(let error):
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
}
