import SwiftUI

enum BetterTheme {
    static let ink = Color(red: 0.06, green: 0.12, blue: 0.22)
    static let navy = Color(red: 0.07, green: 0.20, blue: 0.43)
    static let background = Color(red: 0.06, green: 0.19, blue: 0.40)
    static let surface = Color(red: 0.98, green: 0.99, blue: 0.98)
    static let secondary = Color(red: 0.43, green: 0.51, blue: 0.61)
    static let mutedOnNavy = Color(red: 0.60, green: 0.70, blue: 0.81)
    static let hairline = Color.white.opacity(0.15)
    static let cyan = Color(red: 0.07, green: 0.78, blue: 0.70)
    static let mint = cyan
    static let lime = Color(red: 0.78, green: 0.88, blue: 0.12)
    static let coral = Color(red: 1.0, green: 0.40, blue: 0.38)
    static let gold = Color(red: 1.0, green: 0.73, blue: 0.29)
}

struct MetricCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(18).background(BetterTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(BetterTheme.hairline, lineWidth: 1) }
    }
}
