import Foundation
import SwiftData

@Model
final class DishCategory {
    var name: String = ""
    var icon: String = "🍽️"
    var sortOrder: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \Dish.category)
    var dishes: [Dish] = []

    init(name: String, icon: String, sortOrder: Int) {
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
    }
}

@Model
final class Dish {
    var name: String = ""
    var price: Double = 0
    var imageData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var category: DishCategory?
    var tags: [String] = []
    var suitableForElderly: Bool = true
    var suitableForChildren: Bool = true
    var isHot: Bool = true
    var spicyLevel: Int = 0
    var cookingTime: Int = 0

    init(
        name: String,
        price: Double,
        imageData: Data? = nil,
        category: DishCategory? = nil,
        tags: [String] = [],
        suitableForElderly: Bool = true,
        suitableForChildren: Bool = true,
        isHot: Bool = true,
        spicyLevel: Int = 0,
        cookingTime: Int = 0
    ) {
        self.name = name
        self.price = price
        self.imageData = imageData
        self.category = category
        self.tags = tags
        self.suitableForElderly = suitableForElderly
        self.suitableForChildren = suitableForChildren
        self.isHot = isHot
        self.spicyLevel = spicyLevel
        self.cookingTime = cookingTime
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
