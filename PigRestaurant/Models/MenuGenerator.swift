import Foundation

struct DailyMenu {
    var date: Date
    var mainDishes: [Dish]
    var sideDishes: [Dish]
    var soups: [Dish]
    var staples: [Dish]
    var solarTerm: SolarTerm
    var solarTermDescription: String
    var weatherDescription: String
    var totalPrice: Double

    var allDishes: [Dish] {
        mainDishes + sideDishes + soups + staples
    }
}

struct MenuGenerator {

    static func generate(
        config: MealConfig,
        dishes: [Dish],
        solarTerm: SolarTerm,
        weather: WeatherCondition?
    ) -> DailyMenu {
        let weather = weather ?? WeatherCondition.fromSolarTerm(solarTerm)
        let solarSuggestion = solarTerm.dietarySuggestion
        let weatherSuggestion = weather.dietaryPreference

        let preferCold = solarSuggestion.preferCold || weatherSuggestion.preferCold
        let preferLight = solarSuggestion.preferLight || weatherSuggestion.preferLight
        let preferSoup = solarSuggestion.preferSoup || weatherSuggestion.preferSoup
        let maxSpicy = config.maxSpicyLevel

        // Partition dishes by role
        let allSoups = dishes.filter { $0.tags.contains("汤") || $0.tags.contains("粥") }
        let allStaples = dishes.filter { $0.tags.contains("主食") }
        let allColdDishes = dishes.filter {
            $0.tags.contains("凉菜") && !$0.tags.contains("汤") && !$0.tags.contains("主食")
        }
        let allHotDishes = dishes.filter {
            ($0.tags.contains("热菜") || $0.tags.contains("海鲜"))
                && !$0.tags.contains("汤") && !$0.tags.contains("主食")
                && !$0.tags.contains("凉菜")
        }
        let allDesserts = dishes.filter {
            $0.tags.contains("甜品") || $0.tags.contains("饮品")
        }

        // Filter by dietary constraints (children/elderly)
        func passesConstraints(_ dish: Dish) -> Bool {
            if dish.spicyLevel > maxSpicy { return false }
            if config.hasChildren && !dish.suitableForChildren { return false }
            if config.hasElderly && !dish.suitableForElderly { return false }
            return true
        }

        let eligibleSoups = allSoups.filter(passesConstraints)
        let eligibleStaples = allStaples.filter(passesConstraints)
        let eligibleCold = allColdDishes.filter(passesConstraints)
        let eligibleHot = allHotDishes.filter(passesConstraints)
        let eligibleDesserts = allDesserts.filter(passesConstraints)

        // Score dishes based on weather + solar term preferences
        func score(_ dish: Dish) -> Double {
            var s = Double.random(in: 0...10) // base randomness for variety

            if preferCold && !dish.isHot { s += 5 }
            if !preferCold && dish.isHot { s += 3 }
            if preferLight && dish.tags.contains("清淡") { s += 4 }
            if preferSoup && (dish.tags.contains("汤") || dish.tags.contains("滋补")) { s += 3 }

            // Bonus for warming dishes in cold weather
            if weather.isCold && dish.isHot { s += 4 }
            if weather.isHot && !dish.isHot { s += 4 }

            // Bonus for 滋补 in autumn/winter
            if !solarSuggestion.preferLight && dish.tags.contains("滋补") { s += 3 }

            // Slight penalty for very spicy when elderly present
            if config.hasElderly && dish.spicyLevel >= 2 { s -= 3 }

            return s
        }

        func pickTop(_ pool: [Dish], count: Int) -> [Dish] {
            guard !pool.isEmpty else { return [] }
            let scored = pool.map { (dish: $0, score: score($0)) }
                .sorted { $0.score > $1.score }
            let n = min(count, scored.count)
            return Array(scored.prefix(n).map(\.dish))
        }

        // Determine counts
        let targetDishCount = config.dishCount
        let targetSoupCount = config.soupCount
        let targetStapleCount = 1

        // Always pick at least 1 meat main dish
        let meatDishes = eligibleHot.filter { $0.tags.contains("肉类") || $0.tags.contains("海鲜") }
        let vegDishes = eligibleHot.filter { $0.tags.contains("素菜") }

        // Pick mains: at least 1 meat, at least 1 veg, rest balanced
        let meatCount = max(1, targetDishCount / 2)
        let vegCount = max(1, targetDishCount - meatCount)

        var selectedMains = pickTop(meatDishes, count: meatCount)
        var selectedSides = pickTop(vegDishes, count: vegCount)

        // If hot weather, swap some hot dishes for cold dishes
        if preferCold && !eligibleCold.isEmpty {
            let coldCount = min(2, eligibleCold.count)
            let coldPicks = pickTop(eligibleCold, count: coldCount)
            // Replace some side dishes with cold dishes
            if selectedSides.count > coldCount {
                selectedSides = Array(selectedSides.dropLast(coldCount)) + coldPicks
            } else {
                selectedSides = coldPicks
            }
        }

        // If we have desserts and it's hot, maybe add one
        var bonusDessert: [Dish] = []
        if preferCold && !eligibleDesserts.isEmpty {
            let dessertPick = pickTop(eligibleDesserts.filter { $0.tags.contains("消暑") }, count: 1)
            if !dessertPick.isEmpty {
                bonusDessert = dessertPick
            }
        }

        let selectedSoups = pickTop(eligibleSoups, count: targetSoupCount)
        let selectedStaples = pickTop(eligibleStaples, count: targetStapleCount)

        // Ensure no duplicates across all selections
        var usedNames = Set<String>()
        func deduplicate(_ list: [Dish]) -> [Dish] {
            var result: [Dish] = []
            for dish in list {
                if !usedNames.contains(dish.name) {
                    usedNames.insert(dish.name)
                    result.append(dish)
                }
            }
            return result
        }

        let finalMains = deduplicate(selectedMains)
        let finalSides = deduplicate(selectedSides + bonusDessert)
        let finalSoups = deduplicate(selectedSoups)
        let finalStaples = deduplicate(selectedStaples)

        let allSelected = finalMains + finalSides + finalSoups + finalStaples
        let totalPrice = allSelected.reduce(0) { $0 + $1.price }

        return DailyMenu(
            date: Date(),
            mainDishes: finalMains,
            sideDishes: finalSides,
            soups: finalSoups,
            staples: finalStaples,
            solarTerm: solarTerm,
            solarTermDescription: solarSuggestion.description,
            weatherDescription: weatherSuggestion.description,
            totalPrice: totalPrice
        )
    }
}
