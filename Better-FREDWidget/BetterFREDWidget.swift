import WidgetKit
import SwiftUI

struct BetterFREDEntry: TimelineEntry {
    let date: Date
    let symbol: String
    let value: String
}

struct BetterFREDProvider: TimelineProvider {
    func placeholder(in context: Context) -> BetterFREDEntry { BetterFREDEntry(date: .now, symbol: "UNRATE", value: "4.1%") }
    func getSnapshot(in context: Context, completion: @escaping (BetterFREDEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BetterFREDEntry>) -> Void) {
        let entry = placeholder(in: context)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct BetterFREDWidgetView: View {
    let entry: BetterFREDProvider.Entry
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.symbol).font(.caption.bold())
            Text(entry.value).font(.title.bold())
            Text("BetterEcon").font(.caption2).foregroundStyle(.secondary)
        }.containerBackground(.mint.gradient, for: .widget)
    }
}

struct BetterFREDWidget: Widget {
    let kind = "BetterFREDWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BetterFREDProvider()) { entry in
            BetterFREDWidgetView(entry: entry)
        }
        .configurationDisplayName("Economic indicator")
        .description("See a saved FRED series at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct BetterFREDWidgetBundle: WidgetBundle {
    var body: some Widget { BetterFREDWidget() }
}
