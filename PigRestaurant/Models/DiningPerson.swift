import Foundation
import SwiftData

@Model
final class DiningPerson {
    var name: String = ""
    var emoji: String = "😀"
    var likesSpicy: Bool = false
    var likesSour: Bool = false
    var likesSweet: Bool = false
    var likesLight: Bool = false
    var dislikesSpicy: Bool = false
    var dislikesSour: Bool = false
    var dislikesSweet: Bool = false
    var dislikesOily: Bool = false
    var isChild: Bool = false
    var isElderly: Bool = false
    var notes: String = ""
    var createdAt: Date = Date()

    init(
        name: String,
        emoji: String = "😀",
        likesSpicy: Bool = false,
        likesSour: Bool = false,
        likesSweet: Bool = false,
        likesLight: Bool = false,
        dislikesSpicy: Bool = false,
        dislikesSour: Bool = false,
        dislikesSweet: Bool = false,
        dislikesOily: Bool = false,
        isChild: Bool = false,
        isElderly: Bool = false,
        notes: String = ""
    ) {
        self.name = name
        self.emoji = emoji
        self.likesSpicy = likesSpicy
        self.likesSour = likesSour
        self.likesSweet = likesSweet
        self.likesLight = likesLight
        self.dislikesSpicy = dislikesSpicy
        self.dislikesSour = dislikesSour
        self.dislikesSweet = dislikesSweet
        self.dislikesOily = dislikesOily
        self.isChild = isChild
        self.isElderly = isElderly
        self.notes = notes
        self.createdAt = Date()
    }

    var tasteDescription: String {
        var parts: [String] = []
        if likesSpicy { parts.append("爱辣") }
        if likesSour { parts.append("爱酸") }
        if likesSweet { parts.append("爱甜") }
        if likesLight { parts.append("爱清淡") }
        if dislikesSpicy { parts.append("忌辣") }
        if dislikesSour { parts.append("忌酸") }
        if dislikesSweet { parts.append("忌甜") }
        if dislikesOily { parts.append("忌油腻") }
        if isChild { parts.append("儿童") }
        if isElderly { parts.append("老人") }
        return parts.isEmpty ? "无特殊偏好" : parts.joined(separator: "、")
    }
}
