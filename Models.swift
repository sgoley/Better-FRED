import Foundation

struct FREDSeries: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let units: String
    let frequency: String
    let source: String
    let description: String
}

struct Observation: Identifiable, Codable, Hashable {
    var id: Date { date }
    let date: Date
    let value: Double
}

struct SeriesSnapshot: Identifiable, Hashable {
    let series: FREDSeries
    let observations: [Observation]
    var id: String { series.id }
    var latest: Observation? { observations.last }
    var previous: Observation? { observations.dropLast().last }
    var change: Double? {
        guard let latest, let previous else { return nil }
        return latest.value - previous.value
    }
}

enum SampleData {
    static let series = [
        FREDSeries(id: "CPIAUCSL", title: "Consumer Price Index", units: "Index 1982–84=100", frequency: "Monthly", source: "U.S. Bureau of Labor Statistics", description: "Consumer prices for all urban consumers, seasonally adjusted."),
        FREDSeries(id: "UNRATE", title: "Unemployment Rate", units: "Percent", frequency: "Monthly", source: "U.S. Bureau of Labor Statistics", description: "Civilian unemployment rate, seasonally adjusted."),
        FREDSeries(id: "FEDFUNDS", title: "Federal Funds Effective Rate", units: "Percent", frequency: "Monthly", source: "Board of Governors of the Federal Reserve System", description: "Effective federal funds rate, monthly average."),
        FREDSeries(id: "DFF", title: "Daily Effective Federal Funds Rate", units: "Percent", frequency: "Daily", source: "Board of Governors of the Federal Reserve System", description: "Effective federal funds rate, daily observation. Use this series when you want the un-averaged daily rate."),
        FREDSeries(id: "DGS10", title: "10-Year Treasury Constant Maturity Rate", units: "Percent", frequency: "Daily", source: "Board of Governors of the Federal Reserve System", description: "Market yield on U.S. Treasury securities at 10-year constant maturity."),
        FREDSeries(id: "GDPC1", title: "Real Gross Domestic Product", units: "Billions of dollars", frequency: "Quarterly", source: "U.S. Bureau of Economic Analysis", description: "Real gross domestic product, seasonally adjusted annual rate.")
    ]

    static func observations(for series: FREDSeries) -> [Observation] {
        let calendar = Calendar.current
        let base: Double = switch series.id {
        case "UNRATE": 4.1
        case "FEDFUNDS", "DFF": 4.33
        case "DGS10": 4.25
        case "GDPC1": 22_000
        default: 313.2
        }
        let isDaily = series.id == "DFF"
        let pointCount = series.id == "GDPC1" ? 80 : (isDaily ? 1825 : 180)
        return (0..<pointCount).map { index in
            let date = isDaily ? calendar.date(byAdding: .day, value: index - pointCount + 1, to: .now)! : calendar.date(byAdding: .month, value: index - pointCount + 1, to: .now)!
            let wave = sin(Double(index) / (isDaily ? 45 : 3.5)) * (series.id == "GDPC1" ? 250 : (isDaily ? 0.10 : 0.18))
            let trend = Double(index) * (series.id == "GDPC1" ? 60 : (isDaily ? 0.0005 : 0.12))
            return Observation(date: date, value: base + trend + wave)
        }
    }
}
