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
                Section {
                    HStack(spacing: 16) {
                        Text(icon.isEmpty ? "🍽️" : icon)
                            .font(.system(size: 44))
                            .frame(width: 64, height: 64)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("图标 emoji", text: $icon)
                                .font(.title3)
                                .onChange(of: icon) { _, newValue in
                                    let filtered = newValue.filter { $0.unicodeScalars.allSatisfy { scalar in
                                        scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
                                            || scalar.value > 0x238C
                                    }}
                                    if let first = filtered.first {
                                        let emoji = String(first)
                                        if icon != emoji { icon = emoji }
                                    } else if !newValue.isEmpty {
                                        icon = ""
                                    }
                                }
                            TextField("分类名称", text: $name)
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("分类信息")
                }

                if existingCategory != nil {
                    Section {
                        Button(role: .destructive) {
                            if let cat = existingCategory {
                                context.delete(cat)
                                try? context.save()
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("删除此分类", systemImage: "trash")
                                    .fontWeight(.medium)
                                Spacer()
                            }
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
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 220)
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
