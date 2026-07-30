import SwiftUI

extension Color {
    static let brand = Color(red: 41/255, green: 111/255, blue: 180/255)
    static let brandLight = Color.brand.opacity(0.3)
    static let brandDark = Color(red: 30/255, green: 85/255, blue: 140/255)

    /// Create a Color from a string name. Falls back to `.brand` for unknown names.
    init(_ name: String) {
        switch name {
        case "brand": self = .brand
        case "orange": self = .orange
        case "red": self = .red
        case "pink": self = .pink
        case "purple": self = .purple
        case "blue": self = .blue
        case "green": self = .green
        case "teal": self = .teal
        case "yellow": self = .yellow
        case "brown": self = .brown
        case "mint": self = .mint
        case "indigo": self = .indigo
        default: self = .brand
        }
    }
}

extension ShapeStyle where Self == Color {
    static var brand: Color {
        Color(red: 41/255, green: 111/255, blue: 180/255)
    }
}