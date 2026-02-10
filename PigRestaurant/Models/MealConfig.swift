import Foundation

struct MealConfig {
    var totalPeople: Int = 2
    var adultMen: Int = 1
    var adultWomen: Int = 1
    var children: Int = 0
    var elderly: Int = 0

    var isValid: Bool {
        totalPeople == adultMen + adultWomen + children + elderly
            && totalPeople > 0
    }

    var hasChildren: Bool { children > 0 }
    var hasElderly: Bool { elderly > 0 }

    var maxSpicyLevel: Int {
        if hasChildren { return 1 }
        if hasElderly { return 2 }
        return 3
    }

    var dishCount: Int {
        switch totalPeople {
        case 1: return 2
        case 2: return 3
        case 3: return 4
        case 4...5: return 5
        case 6...7: return 7
        default: return 8
        }
    }

    var soupCount: Int {
        totalPeople >= 6 ? 2 : 1
    }
}
