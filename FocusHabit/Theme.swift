import SwiftUI

extension Color {
    static let brand = Color(red: 41/255, green: 111/255, blue: 180/255)     // #296FB4 图标钢蓝色
    static let brandLight = Color.brand.opacity(0.3)
    static let brandDark = Color(red: 30/255, green: 85/255, blue: 140/255)   // 深一点的蓝
}

extension ShapeStyle where Self == Color {
    static var brand: Color {
        Color(red: 41/255, green: 111/255, blue: 180/255)
    }
}
