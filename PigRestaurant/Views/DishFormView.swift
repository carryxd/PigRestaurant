import SwiftUI
import SwiftData
#if os(iOS)
import PhotosUI
#endif

struct DishFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DishCategory.sortOrder) private var categories: [DishCategory]

    @State private var name: String
    @State private var price: String
    @State private var selectedCategory: DishCategory?
    @State private var imageData: Data?
    #if os(iOS)
    @State private var photoItem: PhotosPickerItem?
    #endif

    private let existingDish: Dish?

    init(dish: Dish? = nil, category: DishCategory? = nil) {
        self.existingDish = dish
        _name = State(initialValue: dish?.name ?? "")
        _price = State(initialValue: dish.map { String(format: "%.1f", $0.price) } ?? "")
        _selectedCategory = State(initialValue: dish?.category ?? category)
        _imageData = State(initialValue: dish?.imageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("菜品名称", text: $name)
                    TextField("价格", text: $price)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Picker("分类", selection: $selectedCategory) {
                        Text("未选择").tag(nil as DishCategory?)
                        ForEach(categories) { cat in
                            Text("\(cat.icon) \(cat.name)").tag(cat as DishCategory?)
                        }
                    }
                }

                Section("图片") {
                    imageSection
                }
            }
            .navigationTitle(existingDish != nil ? "编辑菜品" : "添加菜品")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingDish != nil ? "保存" : "添加") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if selectedCategory == nil, let first = categories.first {
                    selectedCategory = first
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 350)
        #endif
    }

    @ViewBuilder
    private var imageSection: some View {
        if let data = imageData, let img = platformImage(from: data) {
            Image(platformImage: img)
                .resizable()
                .aspectRatio(4/3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }

        #if os(iOS)
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label("选择图片", systemImage: "photo.on.rectangle")
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
        #else
        Button("选择图片") { pickImageMac() }
        #endif

        if imageData != nil {
            Button("移除图片", role: .destructive) { imageData = nil }
        }
    }

    #if os(macOS)
    private func pickImageMac() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            imageData = try? Data(contentsOf: url)
        }
    }
    #endif

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let parsedPrice = Double(price) ?? 0

        if let dish = existingDish {
            dish.name = trimmedName
            dish.price = parsedPrice
            dish.category = selectedCategory
            dish.imageData = imageData
            dish.updatedAt = Date()
        } else {
            let dish = Dish(name: trimmedName, price: parsedPrice, imageData: imageData, category: selectedCategory)
            context.insert(dish)
        }

        try? context.save()
        dismiss()
    }
}
