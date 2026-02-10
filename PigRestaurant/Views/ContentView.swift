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
            ForEach(categories) { cat in
                Label {
                    Text(cat.name)
                } icon: {
                    Text(cat.icon)
                }
                .tag(cat)
                .contextMenu {
                    Button("编辑分类") { editingCategory = cat }
                    Button("删除分类", role: .destructive) { deleteCategory(cat) }
                }
            }
        }
        .navigationTitle("🐷 猪咪餐厅")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
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
                VStack(spacing: 0) {
                    dishGrid
                        .navigationTitle("\(cat.icon) \(cat.name)")
                }
                #if os(iOS)
                .searchable(text: $searchText, prompt: "搜索菜品")
                #endif
                .toolbar {
                    #if os(macOS)
                    ToolbarItem {
                        TextField("搜索菜品", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 160)
                    }
                    #endif
                    ToolbarItem {
                        Button(action: { showingAddDish = true }) {
                            Label("添加菜品", systemImage: "plus")
                        }
                    }
                }
            } else {
                ContentUnavailableView("选择一个分类", systemImage: "fork.knife", description: Text("从左侧选择菜品分类开始浏览"))
            }
        }
    }

    private var dishGrid: some View {
        ScrollView {
            if filteredDishes.isEmpty {
                ContentUnavailableView("暂无菜品", systemImage: "fork.knife.circle", description: Text("点击右上角 + 添加菜品"))
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredDishes) { dish in
                        DishCardView(dish: dish) {
                            editingDish = dish
                        } onDelete: {
                            deleteDish(dish)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var gridColumns: [GridItem] {
        #if os(macOS)
        [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16)]
        #else
        [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)]
        #endif
    }

    private func deleteCategory(_ cat: DishCategory) {
        if selectedCategory == cat {
            selectedCategory = categories.first { $0 != cat }
        }
        context.delete(cat)
        try? context.save()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dishImage
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("¥\(dish.price, specifier: "%.1f")")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contextMenu {
            Button("编辑", action: onEdit)
            Button("删除", role: .destructive, action: onDelete)
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
                Color(.systemGray5)
                Text("🍽️")
                    .font(.system(size: 40))
                    .opacity(0.4)
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
