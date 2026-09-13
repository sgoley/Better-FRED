import WidgetKit
import SwiftUI

struct BetterEconEntry: TimelineEntry {
    let date: Date
    let symbol: String
    let value: String
}

struct BetterEconProvider: TimelineProvider {
    func placeholder(in context: Context) -> BetterEconEntry { BetterEconEntry(date: .now, symbol: "UNRATE", value: "4.1%") }
    func getSnapshot(in context: Context, completion: @escaping (BetterEconEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BetterEconEntry>) -> Void) {
        let entry = placeholder(in: context)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct BetterEconWidgetView: View {
    let entry: BetterEconProvider.Entry
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.symbol).font(.caption.bold())
            Text(entry.value).font(.title.bold())
            Text("BetterEcon").font(.caption2).foregroundStyle(.secondary)
        }.containerBackground(.mint.gradient, for: .widget)
    }
}

struct BetterEconWidget: Widget {
    let kind = "BetterEconWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BetterEconProvider()) { entry in
            BetterEconWidgetView(entry: entry)
        }
        .configurationDisplayName("Economic indicator")
        .description("See a saved economic series at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct BetterEconWidgetBundle: WidgetBundle {
    var body: some Widget { BetterEconWidget() }
}
