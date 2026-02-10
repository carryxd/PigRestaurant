import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String

    private let existingCategory: DishCategory?

    init(category: DishCategory? = nil) {
        self.existingCategory = category
        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? "🍽️")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("分类信息") {
                    HStack {
                        Text("图标")
                        Spacer()
                        TextField("", text: $icon)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .font(.title)
                    }
                    TextField("分类名称", text: $name)
                }

                if existingCategory != nil {
                    Section {
                        Button("删除分类", role: .destructive) {
                            if let cat = existingCategory {
                                context.delete(cat)
                                try? context.save()
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existingCategory != nil ? "编辑分类" : "新增分类")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingCategory != nil ? "保存" : "添加") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 250)
        #endif
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let cat = existingCategory {
            cat.name = trimmedName
            cat.icon = icon
        } else {
            let descriptor = FetchDescriptor<DishCategory>(sortBy: [SortDescriptor(\DishCategory.sortOrder, order: .reverse)])
            let maxOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? 0
            let cat = DishCategory(name: trimmedName, icon: icon, sortOrder: maxOrder + 1)
            context.insert(cat)
        }

        try? context.save()
        dismiss()
    }
}
