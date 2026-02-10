import SwiftUI
import SwiftData

struct DiningPersonFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var likesSpicy: Bool
    @State private var likesSour: Bool
    @State private var likesSweet: Bool
    @State private var likesLight: Bool
    @State private var dislikesSpicy: Bool
    @State private var dislikesSour: Bool
    @State private var dislikesSweet: Bool
    @State private var dislikesOily: Bool
    @State private var isChild: Bool
    @State private var isElderly: Bool
    @State private var notes: String

    private let existingPerson: DiningPerson?

    init(person: DiningPerson? = nil) {
        self.existingPerson = person
        _name = State(initialValue: person?.name ?? "")
        _emoji = State(initialValue: person?.emoji ?? "😀")
        _likesSpicy = State(initialValue: person?.likesSpicy ?? false)
        _likesSour = State(initialValue: person?.likesSour ?? false)
        _likesSweet = State(initialValue: person?.likesSweet ?? false)
        _likesLight = State(initialValue: person?.likesLight ?? false)
        _dislikesSpicy = State(initialValue: person?.dislikesSpicy ?? false)
        _dislikesSour = State(initialValue: person?.dislikesSour ?? false)
        _dislikesSweet = State(initialValue: person?.dislikesSweet ?? false)
        _dislikesOily = State(initialValue: person?.dislikesOily ?? false)
        _isChild = State(initialValue: person?.isChild ?? false)
        _isElderly = State(initialValue: person?.isElderly ?? false)
        _notes = State(initialValue: person?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Text(emoji.isEmpty ? "😀" : emoji)
                            .font(.system(size: 44))
                            .frame(width: 64, height: 64)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("图标 emoji", text: $emoji)
                                .font(.title3)
                                .onChange(of: emoji) { _, newValue in
                                    let filtered = newValue.filter { $0.unicodeScalars.allSatisfy { scalar in
                                        scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
                                            || scalar.value > 0x238C
                                    }}
                                    if let first = filtered.first {
                                        let emojiStr = String(first)
                                        if emoji != emojiStr { emoji = emojiStr }
                                    } else if !newValue.isEmpty {
                                        emoji = ""
                                    }
                                }
                            TextField("姓名", text: $name)
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("基本信息")
                }

                Section {
                    Toggle("儿童", isOn: $isChild)
                    Toggle("老人", isOn: $isElderly)
                } header: {
                    Text("身份")
                }

                Section {
                    Toggle("爱辣", isOn: $likesSpicy)
                    Toggle("爱酸", isOn: $likesSour)
                    Toggle("爱甜", isOn: $likesSweet)
                    Toggle("爱清淡", isOn: $likesLight)
                } header: {
                    Text("喜欢的口味")
                }

                Section {
                    Toggle("忌辣", isOn: $dislikesSpicy)
                    Toggle("忌酸", isOn: $dislikesSour)
                    Toggle("忌甜", isOn: $dislikesSweet)
                    Toggle("忌油腻", isOn: $dislikesOily)
                } header: {
                    Text("不喜欢的口味")
                }

                Section {
                    TextField("备注（可选）", text: $notes)
                } header: {
                    Text("备注")
                }
            }
            .navigationTitle(existingPerson != nil ? "编辑人员" : "新增人员")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingPerson != nil ? "保存" : "添加") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let person = existingPerson {
            person.name = trimmedName
            person.emoji = emoji.isEmpty ? "😀" : emoji
            person.likesSpicy = likesSpicy
            person.likesSour = likesSour
            person.likesSweet = likesSweet
            person.likesLight = likesLight
            person.dislikesSpicy = dislikesSpicy
            person.dislikesSour = dislikesSour
            person.dislikesSweet = dislikesSweet
            person.dislikesOily = dislikesOily
            person.isChild = isChild
            person.isElderly = isElderly
            person.notes = notes
        } else {
            let person = DiningPerson(
                name: trimmedName,
                emoji: emoji.isEmpty ? "😀" : emoji,
                likesSpicy: likesSpicy,
                likesSour: likesSour,
                likesSweet: likesSweet,
                likesLight: likesLight,
                dislikesSpicy: dislikesSpicy,
                dislikesSour: dislikesSour,
                dislikesSweet: dislikesSweet,
                dislikesOily: dislikesOily,
                isChild: isChild,
                isElderly: isElderly,
                notes: notes
            )
            context.insert(person)
        }

        try? context.save()
        dismiss()
    }
}
