import SwiftUI
import SwiftData

struct DiningPersonListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DiningPerson.createdAt) private var persons: [DiningPerson]

    @State private var showingAddPerson = false
    @State private var editingPerson: DiningPerson?
    @State private var personToDelete: DiningPerson?

    var body: some View {
        NavigationStack {
            Group {
                if persons.isEmpty {
                    ContentUnavailableView {
                        Label("暂无就餐人员", systemImage: "person.2.slash")
                            .font(.title2)
                    } description: {
                        Text("点击右上角 + 添加就餐人员")
                    }
                } else {
                    List {
                        ForEach(persons) { person in
                            HStack(spacing: 12) {
                                Text(person.emoji)
                                    .font(.title2)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(person.name)
                                        .fontWeight(.medium)
                                    Text(person.tasteDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingPerson = person
                            }
                            .contextMenu {
                                Button {
                                    editingPerson = person
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    personToDelete = person
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            #if os(iOS)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    personToDelete = person
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                Button {
                                    editingPerson = person
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            #endif
                        }
                    }
                }
            }
            .navigationTitle("就餐人员")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        hapticFeedback(.light)
                        showingAddPerson = true
                    } label: {
                        Label("添加人员", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                DiningPersonFormView()
            }
            .sheet(item: $editingPerson) { person in
                DiningPersonFormView(person: person)
            }
            .alert("确认删除", isPresented: Binding(
                get: { personToDelete != nil },
                set: { if !$0 { personToDelete = nil } }
            )) {
                Button("取消", role: .cancel) { personToDelete = nil }
                Button("删除", role: .destructive) {
                    if let person = personToDelete {
                        hapticFeedback(.warning)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            context.delete(person)
                            try? context.save()
                        }
                        personToDelete = nil
                    }
                }
            } message: {
                if let person = personToDelete {
                    Text("确定要删除「\(person.name)」吗？此操作不可撤销。")
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
    }
}
