import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \DishCategory.sortOrder) private var categories: [DishCategory]
    var appState: AppState?
    @State private var selectedCategory: DishCategory?
    @State private var showingAddDish = false
    @State private var showingAddCategory = false
    @State private var editingCategory: DishCategory?
    @State private var editingDish: Dish?
    @State private var searchText = ""
    @State private var dishToDelete: Dish?
    @State private var categoryToDelete: DishCategory?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var randomDish: Dish?
    @State private var showingMealConfig = false
    @State private var showingSettings = false
    @State private var showingPersonList = false

    var body: some View {
        ZStack {
            #if os(iOS)
            Color(.systemGroupedBackground).ignoresSafeArea()
            if isCompactiPhone {
                iPhoneBody
            } else {
                splitViewBody
            }
            #else
            splitViewBody
            #endif
        }
        .tint(.orange)
        .environment(\.locale, Locale(identifier: "zh_CN"))
        .sheet(isPresented: $showingAddDish) {
            DishFormView(category: selectedCategory)
        }
        .sheet(item: $editingDish) { dish in
            DishFormView(dish: dish)
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryFormView()
        }
        .sheet(item: $editingCategory) { cat in
            CategoryFormView(category: cat)
        }
        .sheet(isPresented: $showingMealConfig) {
            MealConfigView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPersonList) {
            DiningPersonListView()
        }
        .alert("确认删除", isPresented: Binding(
            get: { dishToDelete != nil },
            set: { if !$0 { dishToDelete = nil } }
        )) {
            Button("取消", role: .cancel) { dishToDelete = nil }
            Button("删除", role: .destructive) {
                if let dish = dishToDelete {
                    hapticFeedback(.warning)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteDish(dish)
                    }
                    dishToDelete = nil
                }
            }
        } message: {
            if let dish = dishToDelete {
                Text("确定要删除「\(dish.name)」吗？此操作不可撤销。")
            }
        }
        .alert("确认删除分类", isPresented: Binding(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("取消", role: .cancel) { categoryToDelete = nil }
            Button("删除", role: .destructive) {
                if let cat = categoryToDelete {
                    hapticFeedback(.warning)
                    deleteCategory(cat)
                    categoryToDelete = nil
                }
            }
        } message: {
            if let cat = categoryToDelete {
                Text("确定要删除「\(cat.name)」及其所有菜品吗？")
            }
        }
        .alert("🎲 今天吃什么", isPresented: Binding(
            get: { randomDish != nil },
            set: { if !$0 { randomDish = nil } }
        )) {
            Button("换一个") { pickRandomDish() }
            Button("好的", role: .cancel) { randomDish = nil }
        } message: {
            if let dish = randomDish {
                Text("推荐你吃：\(dish.name)\n价格：¥\(String(format: "%.0f", dish.price))")
            }
        }
        .onChange(of: appState?.quickAction) { _, action in
            guard let action else { return }
            switch action {
            case .addDish:
                showingAddDish = true
            case .randomDish:
                pickRandomDish()
            }
            appState?.quickAction = nil
        }
        .onAppear {
            if selectedCategory == nil, let first = categories.first {
                selectedCategory = first
            }
        }
    }

    // MARK: - iPhone Compact Layout

    #if os(iOS)
    @State private var showingCategoryPicker = false
    @State private var showingAddCategoryInPicker = false

    private var iPhoneBody: some View {
        NavigationStack {
            dishGrid
                .navigationTitle(selectedCategory.map { "\($0.icon) \($0.name)" } ?? "🐷 猪咪餐厅")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索菜品")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            hapticFeedback(.light)
                            showingCategoryPicker = true
                        } label: {
                            Label("分类", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            hapticFeedback(.light)
                            showingSettings = true
                        } label: {
                            Label("设置", systemImage: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            hapticFeedback(.light)
                            showingPersonList = true
                        } label: {
                            Label("就餐人员", systemImage: "person.2")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            hapticFeedback(.light)
                            showingMealConfig = true
                        } label: {
                            Label("每日菜谱", systemImage: "wand.and.stars")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            hapticFeedback(.light)
                            showingAddDish = true
                        } label: {
                            Label("添加菜品", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(for: Dish.self) { dish in
                    DishDetailView(dish: dish)
                }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showingCategoryPicker) {
            categoryPickerSheet
        }
    }

    private var categoryPickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories) { cat in
                        HStack(spacing: 10) {
                            Text(cat.icon)
                                .font(.title3)
                                .frame(width: 28)
                            Text(cat.name)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(cat.dishes.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                            if cat == selectedCategory {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = cat
                            hapticFeedback(.light)
                            showingCategoryPicker = false
                        }
                        .contextMenu {
                            Button { editingCategory = cat } label: {
                                Label("编辑分类", systemImage: "pencil")
                            }
                            Divider()
                            Button(role: .destructive) { categoryToDelete = cat } label: {
                                Label("删除分类", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { categoryToDelete = cat } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button { editingCategory = cat } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onMove { source, destination in
                        moveCategoriesOrder(from: source, to: destination)
                    }
                } header: {
                    Text("菜品分类")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("🐷 猪咪餐厅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        hapticFeedback(.light)
                        showingAddCategoryInPicker = true
                    } label: {
                        Label("新增分类", systemImage: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategoryInPicker) {
                CategoryFormView()
            }
        }
        .presentationDetents([.medium, .large])
    }
    #endif

    // MARK: - Split View Layout (iPad / macOS)

    private var splitViewBody: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detail
        }
        .navigationDestination(for: Dish.self) { dish in
            DishDetailView(dish: dish)
        }
        .navigationSplitViewStyle(splitViewStyle)
    }

    private var sidebar: some View {
        List(selection: $selectedCategory) {
            Section {
                ForEach(categories) { cat in
                    HStack(spacing: 10) {
                        Text(cat.icon)
                            .font(.title3)
                            .frame(width: 28)
                        Text(cat.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(cat.dishes.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                    .tag(cat)
                    .contextMenu {
                        Button { editingCategory = cat } label: {
                            Label("编辑分类", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) { categoryToDelete = cat } label: {
                            Label("删除分类", systemImage: "trash")
                        }
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { categoryToDelete = cat } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button { editingCategory = cat } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    #endif
                }
                .onMove { source, destination in
                    moveCategoriesOrder(from: source, to: destination)
                }
            } header: {
                Text("菜品分类")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("🐷 猪咪餐厅")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            #endif
            ToolbarItem {
                Button(action: {
                    hapticFeedback(.light)
                    showingSettings = true
                }) {
                    Label("设置", systemImage: "gearshape")
                }
            }
            ToolbarItem {
                Button(action: {
                    hapticFeedback(.light)
                    showingPersonList = true
                }) {
                    Label("就餐人员", systemImage: "person.2")
                }
            }
            ToolbarItem {
                Button(action: {
                    hapticFeedback(.light)
                    showingMealConfig = true
                }) {
                    Label("每日菜谱", systemImage: "calendar.badge.clock")
                }
            }
            ToolbarItem {
                Button(action: {
                    hapticFeedback(.light)
                    showingAddCategory = true
                }) {
                    Label("新增分类", systemImage: "folder.badge.plus")
                }
            }
        }
        .onAppear {
            if selectedCategory == nil, let first = categories.first {
                selectedCategory = first
            }
        }
    }

    private var filteredDishes: [Dish] {
        guard let cat = selectedCategory else { return [] }
        let dishes = cat.dishes.sorted { $0.updatedAt > $1.updatedAt }
        if searchText.isEmpty { return dishes }
        return dishes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var detail: some View {
        Group {
            if let cat = selectedCategory {
                dishGrid
                    .navigationTitle("\(cat.icon) \(cat.name)")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索菜品")
                #endif
                .toolbar {
                    #if os(iOS)
                    if isCompactiPhone {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                hapticFeedback(.light)
                                columnVisibility = .all
                            } label: {
                                Label("分类", systemImage: "sidebar.leading")
                            }
                        }
                    }
                    #endif
                    #if os(macOS)
                    ToolbarItem {
                        TextField("搜索菜品", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                    #endif
                    ToolbarItem {
                        Button(action: {
                            hapticFeedback(.light)
                            showingAddDish = true
                        }) {
                            Label("添加菜品", systemImage: "plus")
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("选择一个分类", systemImage: "fork.knife")
                        .font(.title2)
                } description: {
                    Text("从左侧选择菜品分类开始浏览")
                }
            }
        }
    }

    private var dishGrid: some View {
        ScrollView {
            if filteredDishes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)
                    Text("暂无菜品")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("点击右上角 + 添加菜品")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(Array(filteredDishes.enumerated()), id: \.element.id) { index, dish in
                        NavigationLink(value: dish) {
                            DishCardView(dish: dish) {
                                hapticFeedback(.light)
                                editingDish = dish
                            } onDelete: {
                                dishToDelete = dish
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.6).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03), value: filteredDishes.count)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(.systemGroupedBackground))
        #endif
    }

    private var gridColumns: [GridItem] {
        #if os(macOS)
        [GridItem(.adaptive(minimum: 170, maximum: 260), spacing: 16)]
        #else
        if sizeClass == .regular {
            return [GridItem(.adaptive(minimum: 180, maximum: 280), spacing: 16)]
        }
        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        #endif
    }

    private var splitViewStyle: some NavigationSplitViewStyle {
        #if os(iOS)
        .prominentDetail
        #else
        .automatic
        #endif
    }

    private var isCompactiPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    private func deleteCategory(_ cat: DishCategory) {
        withAnimation {
            if selectedCategory == cat {
                selectedCategory = categories.first { $0 != cat }
            }
            context.delete(cat)
            try? context.save()
        }
    }

    private func deleteDish(_ dish: Dish) {
        context.delete(dish)
        try? context.save()
    }

    private func moveCategoriesOrder(from source: IndexSet, to destination: Int) {
        var ordered = categories.sorted { $0.sortOrder < $1.sortOrder }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, cat) in ordered.enumerated() {
            cat.sortOrder = i
        }
        try? context.save()
        hapticFeedback(.light)
    }

    private func pickRandomDish() {
        let allDishes = categories.flatMap { $0.dishes }
        guard !allDishes.isEmpty else { return }
        randomDish = allDishes.randomElement()
        hapticFeedback(.medium)
    }
}

func hapticFeedback(_ style: HapticStyle) {
    #if os(iOS)
    switch style {
    case .light:
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .medium:
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    case .warning:
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    case .success:
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    case .error:
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    #endif
}

enum HapticStyle {
    case light, medium, warning, success, error
}

struct DishCardView: View {
    let dish: Dish
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                dishImage

                LinearGradient(
                    colors: [
                        .black.opacity(0.0),
                        .black.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    HStack(alignment: .top) {
                        HStack(spacing: 5) {
                            if !dish.isHot {
                                temperatureBadge
                            }
                            if dish.spicyLevel > 0 {
                                spicyBadge
                            }
                        }

                        Spacer(minLength: 8)

                        priceBadge
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        if !dish.suitableForChildren {
                            unsuitableBadge(
                                title: "儿童",
                                icon: "figure.child"
                            )
                        }
                        if !dish.suitableForElderly {
                            unsuitableBadge(
                                title: "老人",
                                icon: "figure.seated.side"
                            )
                        }
                        if dish.cookingTime > 0 {
                            cookingTimeBadge
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(dish.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(dish.updatedAt, style: .relative)
                        .font(.caption)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 13)
            .padding(.top, 12)
            .padding(.bottom, 13)
        }
        .background(.thinMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.orange.opacity(isHovering ? 0.3 : 0.16), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.06), radius: isHovering ? 12 : 6, y: isHovering ? 6 : 3)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button { onEdit() } label: {
                Label("编辑", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var dishImage: some View {
        if let data = dish.imageData, let img = platformImage(from: data) {
            Image(platformImage: img)
                .resizable()
                .aspectRatio(4/3, contentMode: .fill)
                .clipped()
        } else {
            ZStack {
                RadialGradient(
                    colors: [
                        Color.orange.opacity(0.7),
                        Color.orange.opacity(0.16)
                    ],
                    center: .topLeading,
                    startRadius: 8,
                    endRadius: 260
                )

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                    .padding(12)

                VStack(spacing: 8) {
                    Text(placeholderCharacter)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 2)

                    Text(dish.category?.icon ?? "🍲")
                        .font(.system(size: 22))
                        .opacity(0.92)
                }

                Circle()
                    .fill(.white.opacity(0.24))
                    .frame(width: 64, height: 64)
                    .offset(x: 56, y: -34)

                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 26, height: 26)
                    .offset(x: -62, y: 34)
            }
            .aspectRatio(4/3, contentMode: .fill)
        }
    }

    private var placeholderCharacter: String {
        dish.name.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? "菜"
    }

    private var temperatureText: String {
        dish.isHot ? "热菜" : "凉菜"
    }

    private var temperatureIcon: String {
        dish.isHot ? "flame.fill" : "snowflake"
    }

    private var temperatureColor: Color {
        dish.isHot ? .orange : .blue
    }

    private var spicyColor: Color {
        dish.spicyLevel == 0 ? .secondary : .orange
    }

    private var spicyDetailText: String {
        if dish.spicyLevel == 0 {
            return "不辣"
        }

        let spicyLabel: String
        switch dish.spicyLevel {
        case 1:
            spicyLabel = "微辣"
        case 2:
            spicyLabel = "中辣"
        default:
            spicyLabel = "特辣"
        }
        return String(repeating: "🌶", count: dish.spicyLevel) + " " + spicyLabel
    }

    private var spicyBadge: some View {
        Text(dish.spicyLevel == 0 ? "不辣" : String(repeating: "🌶", count: dish.spicyLevel))
            .font(.caption2.weight(.bold))
            .foregroundStyle(spicyColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var temperatureBadge: some View {
        Label(temperatureText, systemImage: temperatureIcon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(temperatureColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var cookingTimeBadge: some View {
        Label("⏱ \(dish.cookingTime)分钟", systemImage: "timer")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var priceBadge: some View {
        HStack(spacing: 3) {
            Text("¥")
                .font(.caption.weight(.heavy))
            Text(dish.price, format: .number.precision(.fractionLength(0)))
                .font(.system(.headline, design: .rounded, weight: .heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [
                    .orange,
                    .orange.opacity(0.74)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .orange.opacity(0.34), radius: 8, y: 3)
    }

    private func unsuitableBadge(title: String, icon: String) -> some View {
        Image(systemName: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 24, height: 24)
            .background(.black.opacity(0.36), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "xmark")
                    .font(.system(size: 6, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 10, height: 10)
                    .background(.red.opacity(0.8), in: Circle())
                    .offset(x: 2, y: -2)
            }
    }
}

#if os(macOS)
typealias PlatformImage = NSImage
extension Image {
    init(platformImage: NSImage) {
        self.init(nsImage: platformImage)
    }
}
func platformImage(from data: Data) -> NSImage? { NSImage(data: data) }
#else
typealias PlatformImage = UIImage
extension Image {
    init(platformImage: UIImage) {
        self.init(uiImage: platformImage)
    }
}
func platformImage(from data: Data) -> UIImage? { UIImage(data: data) }
#endif
