import Foundation
import SwiftData

@Model
final class DishCategory {
    var name: String
    var icon: String
    var sortOrder: Int
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
    var name: String
    var price: Double
    var imageData: Data?
    var createdAt: Date
    var updatedAt: Date
    var category: DishCategory?

    init(name: String, price: Double, imageData: Data? = nil, category: DishCategory? = nil) {
        self.name = name
        self.price = price
        self.imageData = imageData
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
