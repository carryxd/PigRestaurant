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
    @State private var spicyLevel: Int
    @State private var isHot: Bool
    @State private var suitableForElderly: Bool
    @State private var suitableForChildren: Bool
    @State private var tags: [String]
    @State private var newTag: String = ""
    @State private var isRecognizing = false
    @State private var recognitionError: String?
    @AppStorage("zhipuAPIKey") private var apiKey = "f007567810874f33aabb61cb51cbe4e5.nyOcOnCAa47cbIYC"
    #if os(iOS)
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingImageSource = false
    @State private var showingAICamera = false
    #endif

    private let existingDish: Dish?

    init(dish: Dish? = nil, category: DishCategory? = nil) {
        self.existingDish = dish
        _name = State(initialValue: dish?.name ?? "")
        _price = State(initialValue: dish.map { String(format: "%.1f", $0.price) } ?? "")
        _selectedCategory = State(initialValue: dish?.category ?? category)
        _imageData = State(initialValue: dish?.imageData)
        _spicyLevel = State(initialValue: dish?.spicyLevel ?? 0)
        _isHot = State(initialValue: dish?.isHot ?? true)
        _suitableForElderly = State(initialValue: dish?.suitableForElderly ?? true)
        _suitableForChildren = State(initialValue: dish?.suitableForChildren ?? true)
        _tags = State(initialValue: dish?.tags ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                #if os(iOS)
                Section {
                    Button {
                        showingAICamera = true
                    } label: {
                        HStack {
                            Spacer()
                            if isRecognizing {
                                ProgressView()
                                    .padding(.trailing, 6)
                                Text("AI 识别中...")
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "camera.viewfinder")
                                Text("AI识别拍照")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.orange)
                    .disabled(isRecognizing)
                }
                #endif

                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "character.cursor.ibeam")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        TextField("菜品名称", text: $name)
                    }
                    HStack(spacing: 14) {
                        Image(systemName: "yensign.circle")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        TextField("价格", text: $price)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                    if !price.isEmpty && Double(price) == nil {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text("请输入有效的数字价格")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.leading, 34)
                    }
                    HStack(spacing: 14) {
                        Image(systemName: "folder")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        Picker("分类", selection: $selectedCategory) {
                            Text("未选择").tag(nil as DishCategory?)
                            ForEach(categories) { cat in
                                Text("\(cat.icon) \(cat.name)").tag(cat as DishCategory?)
                            }
                        }
                        .labelsHidden()
                    }
                } header: {
                    Text("基本信息")
                }

                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "flame")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        Picker("辣度", selection: $spicyLevel) {
                            Text("不辣").tag(0)
                            Text("微辣 🌶️").tag(1)
                            Text("中辣 🌶️🌶️").tag(2)
                            Text("重辣 🌶️🌶️🌶️").tag(3)
                        }
                        .labelsHidden()
                    }
                    HStack(spacing: 14) {
                        Image(systemName: isHot ? "flame.circle.fill" : "snowflake")
                            .foregroundStyle(isHot ? .orange : .blue)
                            .frame(width: 20)
                        Toggle("热菜", isOn: $isHot)
                    }
                    HStack(spacing: 14) {
                        Image(systemName: "figure.and.child.holdinghands")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        Toggle("适合老人", isOn: $suitableForElderly)
                    }
                    HStack(spacing: 14) {
                        Image(systemName: "figure.child")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        Toggle("适合儿童", isOn: $suitableForChildren)
                    }
                } header: {
                    Text("菜品属性")
                }

                Section {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.subheadline)
                                Button {
                                    withAnimation(.easeInOut) {
                                        tags.removeAll { $0 == tag }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.12), in: Capsule())
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "tag")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        TextField("添加标签", text: $newTag)
                            .onSubmit { addTag() }
                        Button("添加") { addTag() }
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("标签")
                }

                Section {
                    imageSection
                } header: {
                    Text("菜品图片")
                }
            }
            .navigationTitle(existingDish != nil ? "编辑菜品" : "添加菜品")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        withAnimation(.easeInOut) {
                            imageData = data
                        }
                    }
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showingAICamera) {
                CameraView { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        withAnimation(.easeInOut) {
                            imageData = data
                        }
                        recognizeDish(data: data)
                    }
                }
                .ignoresSafeArea()
            }
            .alert("识别失败", isPresented: Binding<Bool>(
                get: { recognitionError != nil },
                set: { if !$0 { recognitionError = nil } }
            )) {
                Button("确定", role: .cancel) { recognitionError = nil }
            } message: {
                Text(recognitionError ?? "")
            }
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingDish != nil ? "保存" : "添加") {
                        hapticFeedback(.success)
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || (!price.isEmpty && Double(price) == nil))
                }
            }
            .onAppear {
                if selectedCategory == nil, let first = categories.first {
                    selectedCategory = first
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
    }

    @ViewBuilder
    private var imageSection: some View {
        if let data = imageData, let img = platformImage(from: data) {
            Image(platformImage: img)
                .resizable()
                .aspectRatio(4/3, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        #if os(iOS)
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label("从相册选择", systemImage: "photo.on.rectangle")
                .foregroundStyle(.orange)
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    withAnimation(.easeInOut) {
                        imageData = data
                    }
                }
            }
        }

        Button {
            showingCamera = true
        } label: {
            Label("拍照", systemImage: "camera")
                .foregroundStyle(.orange)
        }
        #else
        Button { pickImageMac() } label: {
            Label("选择图片", systemImage: "photo.on.rectangle.angled")
                .foregroundStyle(.orange)
        }
        #endif

        if imageData != nil {
            Button(role: .destructive) {
                withAnimation(.easeInOut) { imageData = nil }
            } label: {
                Label("移除图片", systemImage: "trash")
            }
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
            dish.spicyLevel = spicyLevel
            dish.isHot = isHot
            dish.suitableForElderly = suitableForElderly
            dish.suitableForChildren = suitableForChildren
            dish.tags = tags
            dish.updatedAt = Date()
        } else {
            let dish = Dish(
                name: trimmedName,
                price: parsedPrice,
                imageData: imageData,
                category: selectedCategory,
                tags: tags,
                suitableForElderly: suitableForElderly,
                suitableForChildren: suitableForChildren,
                isHot: isHot,
                spicyLevel: spicyLevel
            )
            context.insert(dish)
        }

        try? context.save()
        dismiss()
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation(.easeInOut) {
            tags.append(trimmed)
        }
        newTag = ""
    }

    private func recognizeDish(data: Data) {
        isRecognizing = true
        recognitionError = nil
        Task {
            do {
                let result = try await AIService.recognizeDish(imageData: data, apiKey: apiKey)
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        name = result.name
                        price = String(format: "%.1f", result.estimatedPrice)
                        spicyLevel = min(max(result.spicyLevel, 0), 3)
                        isHot = result.isHot
                        suitableForElderly = result.suitableForElderly
                        suitableForChildren = result.suitableForChildren
                        tags = result.tags
                        isRecognizing = false
                    }
                }
            } catch {
                await MainActor.run {
                    recognitionError = error.localizedDescription
                    isRecognizing = false
                }
            }
        }
    }
}

#if os(iOS)
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
