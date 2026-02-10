import Foundation

struct DietarySuggestion {
    var preferHot: Bool
    var preferSoup: Bool
    var preferLight: Bool
    var preferCold: Bool
    var description: String
}

enum SolarTerm: String, CaseIterable {
    case lichun = "立春"
    case yushui = "雨水"
    case jingzhe = "惊蛰"
    case chunfen = "春分"
    case qingming = "清明"
    case guyu = "谷雨"
    case lixia = "立夏"
    case xiaoman = "小满"
    case mangzhong = "芒种"
    case xiazhi = "夏至"
    case xiaoshu = "小暑"
    case dashu = "大暑"
    case liqiu = "立秋"
    case chushu = "处暑"
    case bailu = "白露"
    case qiufen = "秋分"
    case hanlu = "寒露"
    case shuangjing = "霜降"
    case lidong = "立冬"
    case xiaoxue = "小雪"
    case daxue = "大雪"
    case dongzhi = "冬至"
    case xiaohan = "小寒"
    case dahan = "大寒"

    // Approximate (month, day) for each solar term in a typical year
    private static let approximateDates: [(month: Int, day: Int)] = [
        (2, 4),   // 立春
        (2, 19),  // 雨水
        (3, 6),   // 惊蛰
        (3, 21),  // 春分
        (4, 5),   // 清明
        (4, 20),  // 谷雨
        (5, 6),   // 立夏
        (5, 21),  // 小满
        (6, 6),   // 芒种
        (6, 21),  // 夏至
        (7, 7),   // 小暑
        (7, 23),  // 大暑
        (8, 7),   // 立秋
        (8, 23),  // 处暑
        (9, 8),   // 白露
        (9, 23),  // 秋分
        (10, 8),  // 寒露
        (10, 23), // 霜降
        (11, 7),  // 立冬
        (11, 22), // 小雪
        (12, 7),  // 大雪
        (12, 22), // 冬至
        (1, 6),   // 小寒
        (1, 20),  // 大寒
    ]

    static func current(for date: Date = Date()) -> SolarTerm {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let dayOfYear = month * 100 + day

        // Build sorted list with normalized day-of-year values
        let terms = Self.allCases
        let dates = approximateDates

        // Find the last solar term whose date has passed
        // Handle wrap-around: 小寒(1/6) and 大寒(1/20) come after 冬至(12/22)
        var matched: SolarTerm = .xiaohan // default fallback

        for i in stride(from: terms.count - 1, through: 0, by: -1) {
            let d = dates[i]
            let termDay = d.month * 100 + d.day
            if dayOfYear >= termDay {
                matched = terms[i]
                break
            }
        }

        // Special handling: if we're in Jan before 小寒(1/6), we're still in 冬至
        if month == 1 && day < 6 {
            matched = .dongzhi
        }

        return matched
    }

    var estimatedTemperature: Double {
        switch self {
        case .xiaohan, .dahan: return -2
        case .lichun: return 3
        case .yushui: return 6
        case .jingzhe: return 10
        case .chunfen: return 13
        case .qingming: return 16
        case .guyu: return 19
        case .lixia: return 23
        case .xiaoman: return 26
        case .mangzhong: return 28
        case .xiazhi: return 30
        case .xiaoshu: return 32
        case .dashu: return 34
        case .liqiu: return 32
        case .chushu: return 29
        case .bailu: return 25
        case .qiufen: return 21
        case .hanlu: return 16
        case .shuangjing: return 11
        case .lidong: return 7
        case .xiaoxue: return 3
        case .daxue: return 0
        case .dongzhi: return -1
        }
    }

    var dietarySuggestion: DietarySuggestion {
        switch self {
        case .lichun, .yushui, .jingzhe:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: true, preferCold: false,
                description: "春季养肝，宜清淡温补，多食新鲜蔬菜"
            )
        case .chunfen, .qingming, .guyu:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: true, preferCold: false,
                description: "仲春时节，宜平补养肝，饮食清淡"
            )
        case .lixia, .xiaoman, .mangzhong:
            return DietarySuggestion(
                preferHot: false, preferSoup: true, preferLight: true, preferCold: true,
                description: "初夏养心，宜清淡消暑，多食瓜果"
            )
        case .xiazhi, .xiaoshu, .dashu:
            return DietarySuggestion(
                preferHot: false, preferSoup: true, preferLight: true, preferCold: true,
                description: "盛夏消暑，宜清凉解热，多饮汤水"
            )
        case .liqiu, .chushu:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: true, preferCold: false,
                description: "秋季润燥，宜滋阴润肺，多食汤羹"
            )
        case .bailu, .qiufen:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: false, preferCold: false,
                description: "仲秋养肺，宜温润滋补，适当进补"
            )
        case .hanlu, .shuangjing:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: false, preferCold: false,
                description: "深秋进补，宜温热滋养，增强体质"
            )
        case .lidong, .xiaoxue, .daxue:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: false, preferCold: false,
                description: "冬季进补，宜温热滋补，多食炖煮"
            )
        case .dongzhi, .xiaohan, .dahan:
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: false, preferCold: false,
                description: "严冬御寒，宜大补温阳，多食肉类炖汤"
            )
        }
    }
}
