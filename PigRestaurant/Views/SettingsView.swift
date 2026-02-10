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

    @State private var isGeneratingLogo = false
    @State private var logoImageData: Data?
    @State private var logoError: String?

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
                    Button {
                        generateLogo()
                    } label: {
                        HStack {
                            Label("AI 生成猪咪餐厅 Logo", systemImage: "sparkles")
                            Spacer()
                            if isGeneratingLogo {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isGeneratingLogo || apiKey.isEmpty)

                    if let logoImageData,
                       let image = platformImage(from: logoImageData) {
                        VStack(spacing: 12) {
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(radius: 4)

                            HStack(spacing: 16) {
                                #if os(iOS)
                                Button {
                                    saveToPhotoLibrary(data: logoImageData)
                                } label: {
                                    Label("保存到相册", systemImage: "square.and.arrow.down")
                                }
                                #endif

                                ShareLink(
                                    item: Image(platformImage: image),
                                    preview: SharePreview("猪咪餐厅 Logo", image: Image(platformImage: image))
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Logo 生成")
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
        .alert("生成失败", isPresented: Binding<Bool>(
            get: { logoError != nil },
            set: { if !$0 { logoError = nil } }
        )) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(logoError ?? "")
        }
    }

    private func generateLogo() {
        isGeneratingLogo = true
        logoError = nil
        Task {
            do {
                let prompt = "设计一个餐厅App图标Logo，主体是一只可爱的粉色小猪戴着白色厨师帽，小猪表情俏皮自信，手持一把锅铲，背景是温暖的橙色渐变圆形，风格是现代扁平化卡通，专业又可爱，适合作为App图标使用，高清，无文字"
                let data = try await AIService.generateImage(prompt: prompt, apiKey: apiKey)
                await MainActor.run {
                    logoImageData = data
                    isGeneratingLogo = false
                }
            } catch {
                await MainActor.run {
                    logoError = error.localizedDescription
                    isGeneratingLogo = false
                }
            }
        }
    }

    #if os(iOS)
    private func saveToPhotoLibrary(data: Data) {
        guard let uiImage = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
    }
    #endif
}
