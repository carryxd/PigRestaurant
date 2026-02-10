import SwiftUI

enum AppearanceMode: Int {
    case system = 0
    case light = 1
    case dark = 2
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppearanceMode.system.rawValue
    @AppStorage("zhipuAPIKey") private var apiKey = "f007567810874f33aabb61cb51cbe4e5.nyOcOnCAa47cbIYC"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $appearanceMode) {
                        Label("跟随系统", systemImage: "iphone")
                            .tag(AppearanceMode.system.rawValue)
                        Label("浅色模式", systemImage: "sun.max")
                            .tag(AppearanceMode.light.rawValue)
                        Label("深色模式", systemImage: "moon.fill")
                            .tag(AppearanceMode.dark.rawValue)
                    } label: {
                        Label("外观", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("外观设置")
                }

                Section {
                    SecureField("API Key", text: $apiKey)
                } header: {
                    Text("AI 设置")
                } footer: {
                    Text("用于 AI 识别菜品功能，使用智谱 GLM-4V 模型")
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 300)
        #endif
    }
}
