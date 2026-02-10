import Foundation

struct DishRecognitionResult: Codable {
    let name: String
    let estimatedPrice: Double
    let spicyLevel: Int
    let isHot: Bool
    let suitableForElderly: Bool
    let suitableForChildren: Bool
    let tags: [String]
}

struct MenuRecommendationResult: Codable {
    let mainDishes: [String]
    let sideDishes: [String]
    let soups: [String]
    let staples: [String]
    let reason: String
}

// MARK: - API Response Models

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

// MARK: - AIService

struct AIService {
    enum AIError: LocalizedError {
        case emptyImageData
        case invalidResponse
        case networkError(String)
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .emptyImageData:
                return "图片数据为空"
            case .invalidResponse:
                return "AI 返回了无效的响应"
            case .networkError(let msg):
                return "网络错误：\(msg)"
            case .parseError(let msg):
                return "解析错误：\(msg)"
            }
        }
    }

    private static let baseURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

    private static let dishRecognitionPrompt = """
        请识别这张图片中的菜品，并以纯JSON格式返回以下信息，不要包含任何markdown标记或额外说明：
        {
          "name": "菜品名称",
          "estimatedPrice": 预估价格（数字，单位元）,
          "spicyLevel": 辣度（0=不辣，1=微辣，2=中辣，3=重辣）,
          "isHot": 是否热菜（true/false）,
          "suitableForElderly": 是否适合老人（true/false）,
          "suitableForChildren": 是否适合儿童（true/false）,
          "tags": ["标签1", "标签2"]
        }
        只返回JSON，不要有其他内容。
        """

    // MARK: - 菜品识别

    static func recognizeDish(imageData: Data, apiKey: String) async throws -> DishRecognitionResult {
        guard !imageData.isEmpty else {
            throw AIError.emptyImageData
        }

        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"

        let requestBody: [String: Any] = [
            "model": "glm-4v-flash",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": ["url": dataURL]
                        ],
                        [
                            "type": "text",
                            "text": dishRecognitionPrompt
                        ]
                    ]
                ]
            ]
        ]

        let content = try await sendRequest(body: requestBody, apiKey: apiKey)
        let cleaned = stripMarkdown(content)

        guard let resultData = cleaned.data(using: .utf8) else {
            throw AIError.parseError("无法转换响应文本")
        }

        do {
            return try JSONDecoder().decode(DishRecognitionResult.self, from: resultData)
        } catch {
            throw AIError.parseError("JSON 解析失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 菜谱推荐

    static func recommendMenu(
        dishListText: String,
        config: MealConfig,
        weather: WeatherCondition,
        solarTerm: SolarTerm,
        apiKey: String
    ) async throws -> MenuRecommendationResult {
        let menuPrompt = """
            你是一位专业的中餐营养师。请根据以下信息，从可用菜品中推荐今日菜谱。

            【就餐人数】成年男性\(config.adultMen)人，成年女性\(config.adultWomen)人，儿童\(config.children)人，老人\(config.elderly)人
            【天气】\(weather.condition.rawValue) \(Int(weather.temperature))°C
            【节气】\(solarTerm.rawValue)
            【饮食建议】\(solarTerm.dietarySuggestion.description)

            【可用菜品列表】
            \(dishListText)

            请推荐合理搭配的菜谱，注意：
            1. 有儿童时避免重辣菜品
            2. 有老人时注意清淡易消化
            3. 根据天气和节气调整冷热搭配
            4. 荤素搭配均衡

            以纯JSON格式返回，不要包含markdown标记或额外说明：
            {
              "mainDishes": ["主菜名1", "主菜名2"],
              "sideDishes": ["副菜名1"],
              "soups": ["汤品名"],
              "staples": ["主食名"],
              "reason": "推荐理由（一句话）"
            }
            菜名必须从上面的可用菜品列表中选择，只返回JSON。
            """

        let requestBody: [String: Any] = [
            "model": "glm-4-flash",
            "messages": [
                [
                    "role": "user",
                    "content": menuPrompt
                ]
            ]
        ]

        let content = try await sendRequest(body: requestBody, apiKey: apiKey)
        let cleaned = stripMarkdown(content)

        guard let resultData = cleaned.data(using: .utf8) else {
            throw AIError.parseError("无法转换响应文本")
        }

        do {
            return try JSONDecoder().decode(MenuRecommendationResult.self, from: resultData)
        } catch {
            throw AIError.parseError("JSON 解析失败：\(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private static func sendRequest(body: [String: Any], apiKey: String) async throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        guard let url = URL(string: baseURL) else {
            throw AIError.networkError("无效的 URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw AIError.networkError("HTTP \(statusCode): \(responseBody)")
        }

        let completionResponse: ChatCompletionResponse
        do {
            completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw AIError.invalidResponse
        }

        guard let content = completionResponse.choices.first?.message.content else {
            throw AIError.invalidResponse
        }

        return content
    }

    private static func stripMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
