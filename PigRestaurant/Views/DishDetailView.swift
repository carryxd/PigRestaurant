import SwiftUI
import SwiftData

struct DishDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let dish: Dish
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                dishImage

                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    Divider()
                    attributeSection
                    Divider()
                    infoSection
                    if !dish.tags.isEmpty {
                        Divider()
                        tagsSection
                    }
                    Divider()
                    timeSection
                }
                .padding(20)
            }
        }
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(dish.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    hapticFeedback(.light)
                    showingEdit = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            DishFormView(dish: dish)
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                hapticFeedback(.warning)
                context.delete(dish)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("确定要删除「\(dish.name)」吗？此操作不可撤销。")
        }
    }

    @ViewBuilder
    private var dishImage: some View {
        if let data = dish.imageData, let img = platformImage(from: data) {
            Image(platformImage: img)
                .resizable()
                .aspectRatio(4/3, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.08),
                        Color.orange.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text("🍽️")
                    .font(.system(size: 72))
                    .opacity(0.4)
            }
            .aspectRatio(16/9, contentMode: .fill)
            .frame(maxWidth: .infinity)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dish.name)
                    .font(.title.weight(.bold))

                if let cat = dish.category {
                    Label("\(cat.icon) \(cat.name)", systemImage: "folder")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("¥\(dish.price, specifier: "%.0f")")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.orange.gradient, in: Capsule())
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("菜品信息")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                infoCard(icon: "yensign.circle", title: "价格", value: String(format: "¥%.1f", dish.price))
                infoCard(icon: "folder", title: "分类", value: dish.category?.name ?? "未分类")
            }
        }
    }

    private var attributeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("菜品属性")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                attributeCard(
                    icon: "flame",
                    title: "辣度",
                    value: spicyLevelText,
                    color: dish.spicyLevel > 0 ? .red : .green
                )
                attributeCard(
                    icon: dish.isHot ? "flame.circle.fill" : "snowflake",
                    title: "冷热",
                    value: dish.isHot ? "热菜" : "凉菜",
                    color: dish.isHot ? .orange : .blue
                )
                attributeCard(
                    icon: "figure.and.child.holdinghands",
                    title: "老人",
                    value: dish.suitableForElderly ? "适合" : "不适合",
                    color: dish.suitableForElderly ? .green : .secondary
                )
                attributeCard(
                    icon: "figure.child",
                    title: "儿童",
                    value: dish.suitableForChildren ? "适合" : "不适合",
                    color: dish.suitableForChildren ? .green : .secondary
                )
            }
        }
    }

    private var spicyLevelText: String {
        switch dish.spicyLevel {
        case 0: return "不辣"
        case 1: return "微辣 🌶️"
        case 2: return "中辣 🌶️🌶️"
        case 3: return "重辣 🌶️🌶️🌶️"
        default: return "不辣"
        }
    }

    private func attributeCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.body.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标签")
                .font(.headline)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(dish.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    private func infoCard(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.body.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间记录")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                timeRow(icon: "calendar.badge.plus", title: "创建时间", date: dish.createdAt)
                timeRow(icon: "pencil.circle", title: "更新时间", date: dish.updatedAt)
            }
        }
    }

    private func timeRow(icon: String, title: String, date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(date, format: .dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh_CN")))
                    .font(.body.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
