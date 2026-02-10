import SwiftUI
import SwiftData

struct MealConfigView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var config = MealConfig()
    @State private var dailyMenu: DailyMenu?
    @State private var showDailyMenu = false
    @State private var allDishes: [Dish] = []
    @State private var weather = WeatherProvider.fallbackWeather()
    @State private var isLoadingWeather = true
    @State private var isAIGenerating = false
    @State private var aiError: String?
    @StateObject private var locationManager = LocationManager()
    @AppStorage("zhipuAPIKey") private var apiKey = "f007567810874f33aabb61cb51cbe4e5.nyOcOnCAa47cbIYC"
    @Query(sort: \DiningPerson.createdAt) private var allPersons: [DiningPerson]
    @State private var selectedPersons: Set<String> = []
    @State private var showingPersonList = false

    private let solarTerm = SolarTerm.current()

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                diningPersonsSection
                participantSection
                dietaryInfoSection
                generateSection
            }
            .navigationTitle("每日菜谱")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showDailyMenu) {
                if let menu = dailyMenu {
                    DailyMenuView(dailyMenu: menu, config: config, dishes: allDishes, weather: weather)
                }
            }
            .onAppear {
                loadDishes()
                updateTotalPeople()
            }
            .task {
                await loadWeather()
            }
            .onChange(of: config.adultMen) { _, _ in updateTotalPeople() }
            .onChange(of: config.adultWomen) { _, _ in updateTotalPeople() }
            .onChange(of: config.children) { _, _ in updateTotalPeople() }
            .onChange(of: config.elderly) { _, _ in updateTotalPeople() }
            .onChange(of: selectedPersons) { _, _ in updateFromSelectedPersons() }
            .sheet(isPresented: $showingPersonList) {
                DiningPersonListView()
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 520)
        #endif
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label(formattedDate, systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 10) {
                    Label(solarTerm.rawValue, systemImage: "leaf")
                    Label(weatherLine, systemImage: "cloud.sun")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("今日概览")
        }
    }

    private var diningPersonsSection: some View {
        Section {
            if allPersons.isEmpty {
                Text("暂无就餐人员，点击下方按钮添加")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(allPersons) { person in
                    HStack(spacing: 12) {
                        Text(person.emoji)
                            .font(.title3)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .fontWeight(.medium)
                            Text(person.tasteDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedPersons.contains(person.name) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            if selectedPersons.contains(person.name) {
                                selectedPersons.remove(person.name)
                            } else {
                                selectedPersons.insert(person.name)
                            }
                        }
                        hapticFeedback(.light)
                    }
                }
            }

            Button {
                hapticFeedback(.light)
                showingPersonList = true
            } label: {
                Label("管理就餐人员", systemImage: "person.badge.plus")
                    .font(.subheadline)
            }
        } header: {
            Text("就餐人员")
        } footer: {
            if !selectedDiningPersons.isEmpty {
                Text("已选 \(selectedDiningPersons.count) 人，将自动计算人数和饮食偏好")
            }
        }
    }

    private var participantSection: some View {
        Section {
            Stepper("成年男性: \(config.adultMen)", value: $config.adultMen, in: 0...10)
            Stepper("成年女性: \(config.adultWomen)", value: $config.adultWomen, in: 0...10)
            Stepper("儿童: \(config.children)", value: $config.children, in: 0...10)
            Stepper("老人: \(config.elderly)", value: $config.elderly, in: 0...10)

            HStack {
                Text("总人数")
                Spacer()
                Text("\(config.totalPeople)")
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("就餐人数")
        }
    }

    private var dietaryInfoSection: some View {
        Section {
            if dietaryConstraints.isEmpty {
                Text("无特殊限制，按均衡搭配推荐")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(dietaryConstraints, id: \.self) { constraint in
                    Label(constraint, systemImage: "checkmark.seal")
                        .font(.subheadline)
                }
            }
        } header: {
            Text("饮食提示")
        }
    }

    private var generateSection: some View {
        Section {
            Button {
                generateDailyMenu()
            } label: {
                HStack {
                    Spacer()
                    Label("算法生成菜谱", systemImage: "wand.and.stars")
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(config.totalPeople == 0 || allDishes.isEmpty)

            Button {
                Task { await generateAIMenu() }
            } label: {
                HStack {
                    Spacer()
                    if isAIGenerating {
                        ProgressView()
                            .tint(.white)
                        Text("AI 推荐中...")
                            .font(.headline)
                    } else {
                        Label("AI 智能推荐", systemImage: "sparkles")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(config.totalPeople == 0 || allDishes.isEmpty || isAIGenerating)

            if allDishes.isEmpty {
                Text("暂无可用菜品，请先添加菜品")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("AI 推荐失败", isPresented: Binding<Bool>(
            get: { aiError != nil },
            set: { if !$0 { aiError = nil } }
        )) {
            Button("好的", role: .cancel) { aiError = nil }
        } message: {
            Text(aiError ?? "")
        }
    }

    private var dietaryConstraints: [String] {
        var notes: [String] = []
        if config.children > 0 {
            notes.append("有儿童，避免辛辣")
        }
        if config.elderly > 0 {
            notes.append("有老人，建议少油少盐")
        }
        if config.totalPeople >= 6 {
            notes.append("人数较多，建议增加汤品")
        }
        for person in selectedDiningPersons {
            if person.dislikesSpicy { notes.append("\(person.name)忌辣") }
            if person.dislikesOily { notes.append("\(person.name)忌油腻") }
            if person.likesLight { notes.append("\(person.name)爱清淡") }
        }
        return Array(Set(notes))
    }

    private var formattedDate: String {
        Date.now.formatted(.dateTime.year().month().day().weekday().locale(Locale(identifier: "zh_CN")))
    }

    private var weatherLine: String {
        if isLoadingWeather {
            return "加载中..."
        }
        return "\(weather.condition.rawValue) \(Int(weather.temperature))°C"
    }

    private func updateTotalPeople() {
        config.totalPeople = config.adultMen + config.adultWomen + config.children + config.elderly
    }

    private var selectedDiningPersons: [DiningPerson] {
        allPersons.filter { selectedPersons.contains($0.name) }
    }

    private func updateFromSelectedPersons() {
        let selected = selectedDiningPersons
        guard !selected.isEmpty else { return }
        let childCount = selected.filter { $0.isChild }.count
        let elderlyCount = selected.filter { $0.isElderly }.count
        let adultCount = selected.count - childCount - elderlyCount
        let menCount = adultCount / 2
        let womenCount = adultCount - menCount
        config.adultMen = menCount
        config.adultWomen = womenCount
        config.children = childCount
        config.elderly = elderlyCount
        config.totalPeople = selected.count
    }

    private func loadDishes() {
        let descriptor = FetchDescriptor<Dish>()
        allDishes = (try? context.fetch(descriptor)) ?? []
    }

    private func loadWeather() async {
        isLoadingWeather = true
        let location = await locationManager.requestLocation()
        weather = await WeatherProvider.currentWeather(location: location)
        isLoadingWeather = false
    }

    private func generateDailyMenu() {
        loadDishes()
        guard config.totalPeople > 0, !allDishes.isEmpty else { return }
        dailyMenu = MenuGenerator.generate(
            config: config,
            dishes: allDishes,
            solarTerm: solarTerm,
            weather: weather
        )
        showDailyMenu = true
        hapticFeedback(.success)
    }

    @MainActor
    private func generateAIMenu() async {
        loadDishes()
        guard config.totalPeople > 0, !allDishes.isEmpty else { return }

        isAIGenerating = true
        defer { isAIGenerating = false }

        // Serialize Dish data on main thread to avoid SwiftData thread-safety crash
        let dishListText = allDishes.map { dish in
            let spicy = dish.spicyLevel > 0 ? "辣度\(dish.spicyLevel)" : "不辣"
            let temp = dish.isHot ? "热菜" : "凉菜"
            let tags = dish.tags.joined(separator: ",")
            return "\(dish.name)(¥\(Int(dish.price)),\(temp),\(spicy),标签:\(tags))"
        }.joined(separator: "\n")

        var fullPromptText = dishListText
        if !selectedDiningPersons.isEmpty {
            let personInfo = selectedDiningPersons.map { "\($0.name): \($0.tasteDescription)" }.joined(separator: "\n")
            fullPromptText = "【就餐人员口味偏好】\n\(personInfo)\n\n" + dishListText
        }

        let dishMap = Dictionary(allDishes.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last })

        do {
            let result = try await AIService.recommendMenu(
                dishListText: fullPromptText,
                config: config,
                weather: weather,
                solarTerm: solarTerm,
                apiKey: apiKey
            )

            let mains = result.mainDishes.compactMap { dishMap[$0] }
            let sides = result.sideDishes.compactMap { dishMap[$0] }
            let soups = result.soups.compactMap { dishMap[$0] }
            let staples = result.staples.compactMap { dishMap[$0] }
            let allSelected = mains + sides + soups + staples

            dailyMenu = DailyMenu(
                date: Date(),
                mainDishes: mains,
                sideDishes: sides,
                soups: soups,
                staples: staples,
                solarTerm: solarTerm,
                solarTermDescription: result.reason,
                weatherDescription: weather.dietaryPreference.description,
                totalPrice: allSelected.reduce(0) { $0 + $1.price }
            )
            showDailyMenu = true
            hapticFeedback(.success)
        } catch {
            aiError = error.localizedDescription
            hapticFeedback(.error)
        }
    }
}
