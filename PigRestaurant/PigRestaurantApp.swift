import SwiftUI
import SwiftData

enum QuickAction: String {
    case addDish = "com.xiaduan.pigrestaurant.addDish"
    case randomDish = "com.xiaduan.pigrestaurant.randomDish"
}

@Observable
class AppState {
    var quickAction: QuickAction?
}

@main
struct PigRestaurantApp: App {
    @State private var appState = AppState()
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppearanceMode.system.rawValue

    let container: ModelContainer

    init() {
        let schema = Schema([DishCategory.self, Dish.self, DiningPerson.self])
        let config = ModelConfiguration(
            cloudKitDatabase: .automatic
        )
        do {
            let c = try ModelContainer(for: schema, configurations: [config])
            SeedData.seedIfNeeded(context: c.mainContext)
            self.container = c
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case AppearanceMode.light.rawValue: return .light
        case AppearanceMode.dark.rawValue: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    setupQuickActions()
                    #if os(iOS)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.backgroundColor = UIColor.systemGroupedBackground
                    }
                    #endif
                }
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 960, height: 680)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    }

    private func setupQuickActions() {
        #if os(iOS)
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickAction.addDish.rawValue,
                localizedTitle: "添加菜品",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickAction.randomDish.rawValue,
                localizedTitle: "今天吃什么",
                localizedSubtitle: "随机推荐一道菜",
                icon: UIApplicationShortcutIcon(systemImageName: "dice"),
                userInfo: nil
            ),
        ]
        #endif
    }
}
