import Foundation
import SwiftData

struct SeedData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<DishCategory>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let categories: [(String, String, Int)] = [
            ("家常热菜", "🥘", 1),
            ("凉菜小食", "🥗", 2),
            ("汤羹粥品", "🍲", 3),
            ("主食面点", "🍚", 4),
            ("海鲜水产", "🦐", 5),
            ("甜品饮品", "🍰", 6),
        ]

        var categoryMap: [String: DishCategory] = [:]
        for (name, icon, order) in categories {
            let cat = DishCategory(name: name, icon: icon, sortOrder: order)
            context.insert(cat)
            categoryMap[name] = cat
        }

        struct DishSeed {
            let name: String
            let price: Double
            let tags: [String]
            let suitableForElderly: Bool
            let suitableForChildren: Bool
            let isHot: Bool
            let spicyLevel: Int
            let cookingTime: Int
        }

        let dishes: [(String, [DishSeed])] = [
            ("家常热菜", [
                DishSeed(name: "番茄炒蛋", price: 12, tags: ["热菜", "素菜", "经典", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "红烧肉", price: 35, tags: ["热菜", "肉类", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 60),
                DishSeed(name: "宫保鸡丁", price: 28, tags: ["热菜", "肉类", "辣"], suitableForElderly: true, suitableForChildren: false, isHot: true, spicyLevel: 2, cookingTime: 20),
                DishSeed(name: "鱼香肉丝", price: 25, tags: ["热菜", "肉类"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 1, cookingTime: 15),
                DishSeed(name: "麻婆豆腐", price: 18, tags: ["热菜", "素菜", "辣"], suitableForElderly: true, suitableForChildren: false, isHot: true, spicyLevel: 2, cookingTime: 15),
                DishSeed(name: "回锅肉", price: 30, tags: ["热菜", "肉类", "辣"], suitableForElderly: true, suitableForChildren: false, isHot: true, spicyLevel: 2, cookingTime: 20),
                DishSeed(name: "青椒肉丝", price: 22, tags: ["热菜", "肉类"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 1, cookingTime: 15),
                DishSeed(name: "干煸四季豆", price: 18, tags: ["热菜", "素菜"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 1, cookingTime: 15),
                DishSeed(name: "蒜蓉西兰花", price: 15, tags: ["热菜", "素菜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "可乐鸡翅", price: 28, tags: ["热菜", "肉类", "甜"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 30),
                DishSeed(name: "糖醋排骨", price: 38, tags: ["热菜", "肉类", "甜", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 40),
                DishSeed(name: "土豆烧牛肉", price: 42, tags: ["热菜", "肉类", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 50),
                DishSeed(name: "辣子鸡", price: 32, tags: ["热菜", "肉类", "辣"], suitableForElderly: false, suitableForChildren: false, isHot: true, spicyLevel: 3, cookingTime: 25),
                DishSeed(name: "蚂蚁上树", price: 18, tags: ["热菜", "肉类"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 1, cookingTime: 15),
                DishSeed(name: "地三鲜", price: 20, tags: ["热菜", "素菜", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 15),
            ]),
            ("凉菜小食", [
                DishSeed(name: "拍黄瓜", price: 10, tags: ["凉菜", "素菜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 5),
                DishSeed(name: "凉拌木耳", price: 12, tags: ["凉菜", "素菜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "皮蛋豆腐", price: 15, tags: ["凉菜", "素菜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 5),
                DishSeed(name: "口水鸡", price: 28, tags: ["凉菜", "肉类", "辣"], suitableForElderly: false, suitableForChildren: false, isHot: false, spicyLevel: 3, cookingTime: 30),
                DishSeed(name: "凉拌腐竹", price: 12, tags: ["凉菜", "素菜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "蒜泥白肉", price: 25, tags: ["凉菜", "肉类"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 1, cookingTime: 25),
                DishSeed(name: "老醋花生", price: 10, tags: ["凉菜", "素菜"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 10),
            ]),
            ("汤羹粥品", [
                DishSeed(name: "番茄蛋花汤", price: 12, tags: ["汤", "清淡", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 15),
                DishSeed(name: "紫菜蛋汤", price: 10, tags: ["汤", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "排骨莲藕汤", price: 35, tags: ["汤", "肉类", "滋补"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 90),
                DishSeed(name: "酸辣汤", price: 15, tags: ["汤", "辣"], suitableForElderly: true, suitableForChildren: false, isHot: true, spicyLevel: 2, cookingTime: 15),
                DishSeed(name: "玉米排骨汤", price: 30, tags: ["汤", "肉类", "清淡", "滋补"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 80),
                DishSeed(name: "冬瓜丸子汤", price: 20, tags: ["汤", "肉类", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 30),
                DishSeed(name: "皮蛋瘦肉粥", price: 15, tags: ["粥", "肉类", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 45),
                DishSeed(name: "南瓜小米粥", price: 12, tags: ["粥", "素菜", "清淡", "滋补"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 40),
            ]),
            ("主食面点", [
                DishSeed(name: "蛋炒饭", price: 12, tags: ["主食", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "葱油拌面", price: 10, tags: ["主食", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 10),
                DishSeed(name: "炸酱面", price: 15, tags: ["主食", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 20),
                DishSeed(name: "猪肉水饺", price: 20, tags: ["主食", "肉类", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 40),
                DishSeed(name: "韭菜盒子", price: 15, tags: ["主食", "素菜"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 25),
                DishSeed(name: "葱花饼", price: 10, tags: ["主食", "素菜"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 20),
                DishSeed(name: "红糖馒头", price: 8, tags: ["主食", "甜"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 30),
                DishSeed(name: "肉包子", price: 12, tags: ["主食", "肉类"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 35),
            ]),
            ("海鲜水产", [
                DishSeed(name: "清蒸鲈鱼", price: 48, tags: ["热菜", "海鲜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 20),
                DishSeed(name: "红烧带鱼", price: 35, tags: ["热菜", "海鲜", "经典"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 25),
                DishSeed(name: "蒜蓉粉丝蒸虾", price: 55, tags: ["热菜", "海鲜", "清淡"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 15),
                DishSeed(name: "油焖大虾", price: 58, tags: ["热菜", "海鲜"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 20),
                DishSeed(name: "酸菜鱼", price: 42, tags: ["热菜", "海鲜", "辣"], suitableForElderly: true, suitableForChildren: false, isHot: true, spicyLevel: 2, cookingTime: 30),
                DishSeed(name: "水煮鱼", price: 45, tags: ["热菜", "海鲜", "辣"], suitableForElderly: false, suitableForChildren: false, isHot: true, spicyLevel: 3, cookingTime: 25),
            ]),
            ("甜品饮品", [
                DishSeed(name: "红豆沙", price: 10, tags: ["甜品", "素菜", "甜", "滋补"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 60),
                DishSeed(name: "银耳莲子羹", price: 12, tags: ["甜品", "素菜", "甜", "滋补"], suitableForElderly: true, suitableForChildren: true, isHot: true, spicyLevel: 0, cookingTime: 45),
                DishSeed(name: "绿豆汤", price: 8, tags: ["饮品", "素菜", "清淡", "消暑"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 40),
                DishSeed(name: "酸梅汤", price: 8, tags: ["饮品", "素菜", "消暑"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 30),
                DishSeed(name: "桂花糕", price: 15, tags: ["甜品", "素菜", "甜"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 45),
                DishSeed(name: "芒果西米露", price: 15, tags: ["甜品", "素菜", "甜", "消暑"], suitableForElderly: true, suitableForChildren: true, isHot: false, spicyLevel: 0, cookingTime: 25),
            ]),
        ]

        for (catName, items) in dishes {
            guard let cat = categoryMap[catName] else { continue }
            for seed in items {
                let dish = Dish(
                    name: seed.name,
                    price: seed.price,
                    category: cat,
                    tags: seed.tags,
                    suitableForElderly: seed.suitableForElderly,
                    suitableForChildren: seed.suitableForChildren,
                    isHot: seed.isHot,
                    spicyLevel: seed.spicyLevel,
                    cookingTime: seed.cookingTime
                )
                context.insert(dish)
            }
        }

        try? context.save()
    }
}
