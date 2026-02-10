import SwiftUI

struct DailyMenuView: View {
    let config: MealConfig
    let dishes: [Dish]
    let weather: WeatherCondition

    @State private var currentMenu: DailyMenu

    init(dailyMenu: DailyMenu, config: MealConfig, dishes: [Dish], weather: WeatherCondition) {
        self.config = config
        self.dishes = dishes
        self.weather = weather
        _currentMenu = State(initialValue: dailyMenu)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                menuSection(title: "主菜", icon: "🥩", dishes: currentMenu.mainDishes)
                menuSection(title: "副菜", icon: "🥬", dishes: currentMenu.sideDishes)
                menuSection(title: "汤品", icon: "🍲", dishes: currentMenu.soups)
                menuSection(title: "主食", icon: "🍚", dishes: currentMenu.staples)
                totalCard
            }
            .padding(14)
        }
        .background(backgroundView)
        .navigationTitle("今日菜谱")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("换一批") {
                    regenerateMenu()
                }
            }
            ToolbarItem {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentMenu.date.formatted(.dateTime.year().month().day().weekday().locale(Locale(identifier: "zh_CN"))))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Text(currentMenu.solarTerm.rawValue)
                    .font(.title2.bold())
                Text(currentMenu.weatherDescription)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(currentMenu.solarTermDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.18), Color.orange.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
        )
    }

    private func menuSection(title: String, icon: String, dishes: [Dish]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(icon) \(title)")
                    .font(.headline)
                Spacer()
                Text("\(dishes.count) 道")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if dishes.isEmpty {
                Text("暂无推荐")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(dishes) { dish in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(dish.name)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text("¥\(dish.price, specifier: "%.0f")")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                        }

                        HStack(spacing: 8) {
                            if !dish.isHot {
                                Label("凉菜", systemImage: "snowflake")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                            if dish.spicyLevel > 0 {
                                Text(String(repeating: "🌶️", count: dish.spicyLevel))
                                    .font(.caption2)
                            }
                            if !dish.suitableForChildren {
                                Label("不宜儿童", systemImage: "figure.child")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if !dish.suitableForElderly {
                                Label("不宜老人", systemImage: "figure.and.child.holdinghands")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
    }

    private var totalCard: some View {
        HStack {
            Text("预估总价")
                .font(.headline)
            Spacer()
            Text("¥\(currentMenu.totalPrice, specifier: "%.0f")")
                .font(.title3.bold())
                .foregroundStyle(.orange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [Color.orange.opacity(0.05), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var shareText: String {
        let names = currentMenu.allDishes.map(\.name).joined(separator: "、")
        return "今日菜谱（\(currentMenu.solarTerm.rawValue)）：\(names)。预估总价¥\(Int(currentMenu.totalPrice))"
    }

    private func regenerateMenu() {
        currentMenu = MenuGenerator.generate(
            config: config,
            dishes: dishes,
            solarTerm: SolarTerm.current(),
            weather: weather
        )
        hapticFeedback(.light)
    }
}
