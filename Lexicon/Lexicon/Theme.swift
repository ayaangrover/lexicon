import SwiftUI

extension Color {
    static var appText: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var appBackground: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .black : .white
        })
    }
    
    static let appIcon: Color = Color(red: 63/255, green: 183/255, blue: 154/255)
}
