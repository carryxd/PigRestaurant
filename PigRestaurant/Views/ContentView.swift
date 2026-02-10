import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DishCategory.sortOrder) private var categories: [DishCategory]
    @State private var selectedCategory: DishCategory?
    @State private var showingAddDish = false
    @State private var showingAddCategory = false
    @State private var editingCategory: DishCategory?
    @State private var editingDish: Dish?
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .tint(.orange)
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
                        Button(role: .destructive) { deleteCategory(cat) } label: {
                            Label("删除分类", systemImage: "trash")
                        }
                    }
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
            ToolbarItem {
                Button(action: { showingAddCategory = true }) {
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
                .searchable(text: $searchText, prompt: "搜索菜品")
                #endif
                .toolbar {
                    #if os(macOS)
                    ToolbarItem {
                        TextField("搜索菜品", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                    #endif
                    ToolbarItem {
                        Button(action: { showingAddDish = true }) {
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
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(Array(filteredDishes.enumerated()), id: \.element.id) { index, dish in
                        DishCardView(dish: dish) {
                            editingDish = dish
                        } onDelete: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                deleteDish(dish)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.6).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03), value: filteredDishes.count)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.gray.opacity(0.06))
    }

    private var gridColumns: [GridItem] {
        #if os(macOS)
        [GridItem(.adaptive(minimum: 190, maximum: 260), spacing: 20)]
        #else
        [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 14)]
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
}

struct DishCardView: View {
    let dish: Dish
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                dishImage
                Text("¥\(dish.price, specifier: "%.0f")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.gradient, in: Capsule())
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(dish.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(dish.updatedAt, style: .relative)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.08),
                        Color.orange.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text("🍽️")
                    .font(.system(size: 44))
                    .opacity(0.5)
            }
            .aspectRatio(4/3, contentMode: .fill)
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
