# AGENTS.md — PigRestaurant (猪咪餐厅)

## Project Overview

Native Swift/SwiftUI restaurant dish management app. iOS 17+ / macOS 14+.
SwiftData persistence, XcodeGen project generation. 13 Swift files, single universal target.
Zero external package dependencies — Apple frameworks + Open-Meteo REST API only.

## Build & Run

```bash
# Prerequisites: Xcode 16+, Swift 5.9, xcodegen (brew install xcodegen)
xcodegen generate                    # .xcodeproj is gitignored — always regenerate

# iOS Simulator
xcodebuild -project PigRestaurant.xcodeproj -scheme PigRestaurant_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# macOS
xcodebuild -project PigRestaurant.xcodeproj -scheme PigRestaurant_macOS \
  -destination 'platform=macOS' build
```

**Tests**: No test target yet. Add target in `project.yml`, run `xcodebuild test`.
**Lint**: No SwiftLint. Follow conventions below.

## Project Structure

```
PigRestaurant/
├── PigRestaurantApp.swift        # @main, scene config, quick actions, @Observable AppState
├── Models/
│   ├── Models.swift              # @Model: DishCategory, Dish (tags, spicyLevel, isHot, suitability)
│   ├── SeedData.swift            # First-launch seed data (6 categories, 50+ dishes)
│   ├── MealConfig.swift          # MealConfig struct (people count, dietary constraints)
│   ├── MenuGenerator.swift       # DailyMenu struct + MenuGenerator (weather/solar-aware scoring)
│   ├── SolarTerm.swift           # 24 solar terms, DietarySuggestion, estimated temperatures
│   └── WeatherService.swift      # Open-Meteo API, LocationManager (CLLocation), WeatherProvider
├── Views/
│   ├── ContentView.swift         # NavigationSplitView, sidebar, grid, DishCardView, FlowLayout,
│   │                             #   hapticFeedback(), HapticStyle, PlatformImage helpers
│   ├── DishDetailView.swift      # Dish detail page (attributes, tags, time records)
│   ├── DishFormView.swift        # Add/edit dish sheet, CameraView (iOS), tag management
│   ├── CategoryFormView.swift    # Add/edit category sheet (emoji-filtered input)
│   ├── MealConfigView.swift      # Meal config sheet (people, async weather loading)
│   └── DailyMenuView.swift       # Generated daily menu display + share
└── Resources/Assets.xcassets/
project.yml                       # XcodeGen — edit THIS, not .xcodeproj
```

## Code Style

### Naming & Imports

- **Types**: PascalCase (`DishCategory`, `DishFormView`). **Vars/funcs/enum cases**: camelCase.
- **Files**: match primary type name (`ContentView.swift`).
- **Models**: `import Foundation` + `import SwiftData`
- **Views**: `import SwiftUI` + `import SwiftData`
- **Platform-specific**: guarded — `#if os(iOS) import PhotosUI #endif`

### SwiftUI Patterns

- Views are **structs**, never classes (exception: `LocationManager` is `ObservableObject` class)
- `@Environment(\.modelContext)` / `@Environment(\.dismiss)` — never pass manually
- `@State` for local state, `@Query` for SwiftData fetches, `@StateObject` for ObservableObject
- Sub-views as `private var name: some View { ... }` computed properties
- `@ViewBuilder` for conditional composition
- `NavigationStack` inside sheets; `NavigationSplitView` for main layout
- Toolbar: `.cancellationAction` for cancel, `.confirmationAction` for save/add
- Sheets via `.sheet(isPresented:)` or `.sheet(item:)` from ContentView
- Async data loading via `.task { }` modifier (e.g., weather in MealConfigView)

### SwiftData Patterns

- `@Model final class` with explicit `init`
- Relationships: `@Relationship(deleteRule: .cascade, inverse: \Dish.category)`
- Save: `try? context.save()` — silent, no error propagation
- Fetch: `FetchDescriptor<T>` with `SortDescriptor`
- Seed guard: `context.fetchCount(descriptor) == 0`

### Platform Conditionals

Always handle **both** platforms when behavior diverges:
```swift
#if os(iOS)
.navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
.frame(minWidth: 420, minHeight: 380)
#endif
```

### Formatting & Error Handling

- 4-space indentation, trailing closures, chained modifiers on separate lines
- Opening brace on same line, blank line between logical sections
- `try? context.save()` — errors silently discarded (current pattern)
- Guard clauses for early return: `guard !trimmedName.isEmpty else { return }`
- No custom error types. Network errors fallback silently (weather → solar term estimate)

### UI Strings & Helpers

- **All Chinese (Simplified)**, hardcoded — no localization. New strings must be Chinese.
- `hapticFeedback(.light|.medium|.warning|.success|.error)` — global func in ContentView.swift, iOS-only
- `platformImage(from: Data) -> PlatformImage?` / `Image(platformImage:)` — cross-platform image helpers
- `FlowLayout` — custom `Layout` in DishFormView.swift for tag chips (used in DishFormView + DishDetailView)
- Dish images stored as `Data?`, JPEG 0.8 quality for camera captures

### UI Interaction Patterns

- **Delete confirmation**: two-step — set `@State var itemToDelete: T?`, then `.alert` with custom `Binding`
- **Context menus**: on list rows and card views — edit + delete actions
- **Swipe actions** (iOS only): `.swipeActions(edge: .trailing, allowsFullSwipe: false)`
- **Animations**: `withAnimation(.easeInOut)` for state changes, `.spring()` for interactive transitions
- **Card badges**: show only meaningful info (spicy only if >0, cold only if !isHot, unsuitable only if false)
- **Form validation**: inline error messages (e.g., price field), disable save button on invalid input

## Architecture Decisions

1. **Zero package dependencies** — Apple frameworks + REST API only
2. **XcodeGen** — edit `project.yml`, never `.xcodeproj`
3. **Single ModelContainer** at app level with seed-on-first-launch
4. **`@Observable` AppState** for app-level state (quick actions)
5. **Sheet-based editing** — modal sheets, not inline
6. **Cascade delete** — deleting category removes all its dishes
7. **Open-Meteo weather** — free REST API, no API key, fallback to solar term estimate
8. **CoreLocation** — `requestWhenInUseAuthorization`, fallback to Beijing (39.9, 116.4)

## Gotchas

- `.xcodeproj` is **gitignored** — run `xcodegen generate` after clone or `project.yml` changes
- SwiftData `@Query` macros cause **LSP false-positive errors** — project builds fine, ignore them
- `Dish.updatedAt` must be set manually on edit (`dish.updatedAt = Date()`)
- New files in `PigRestaurant/` are auto-discovered by XcodeGen — no manifest update needed
- `ContentView.swift` contains `DishCardView`, `FlowLayout`, `hapticFeedback()`, `PlatformImage` helpers
- `DishFormView.swift` contains `CameraView` (iOS) and `FlowLayout` definition
- `WeatherService.swift` contains `LocationManager` class — the only ObservableObject in the project
- Dish model has `tags`, `spicyLevel`, `isHot`, `suitableForElderly`, `suitableForChildren` — all must be editable in DishFormView and visible in DishDetailView

## Common Agent Tasks

### Add a New View
1. Create `PigRestaurant/Views/MyView.swift` — `import SwiftUI` + `import SwiftData`
2. Follow sheet pattern: `NavigationStack` → `Form` → `.toolbar` with cancel/confirm
3. Present from ContentView via `.sheet(isPresented:)` or `.sheet(item:)`

### Add a Model Property
1. Add to `@Model` class in `Models.swift` with default value
2. SwiftData handles lightweight migration automatically
3. Update DishFormView (editing), DishDetailView (display), DishCardView (badge if relevant)

### Form View Template
Reference `CategoryFormView.swift` (simplest) or `DishFormView.swift` (with images/tags). Pattern:
- `init(model:)` stores optional existing model, inits `@State` from it
- `NavigationStack` > `Form` > `.navigationTitle` (编辑/新增) > `.toolbar` (取消 + 保存/添加)
- `save()`: trim input → guard → create or update → `try? context.save()` → `dismiss()`
- iOS: `.navigationBarTitleDisplayMode(.inline)` — macOS: `.frame(minWidth:minHeight:)`
