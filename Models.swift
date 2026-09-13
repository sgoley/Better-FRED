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
        FREDSeries(id: "MORTGAGE30US", title: "30-Year Fixed Rate Mortgage Average in the United States", units: "Percent", frequency: "Weekly", source: "Freddie Mac via FRED®", description: "The 30-year fixed-rate mortgage average in the United States (weekly ending Thursday, not seasonally adjusted). Freddie Mac surveys lenders on rates and points for their most popular 30-year fixed-rate mortgage products."),
        FREDSeries(id: "CPIAUCSL", title: "Consumer Price Index", units: "Index 1982–84=100", frequency: "Monthly", source: "U.S. Bureau of Labor Statistics", description: "Consumer prices for all urban consumers, seasonally adjusted."),
        FREDSeries(id: "UNRATE", title: "Unemployment Rate", units: "Percent", frequency: "Monthly", source: "U.S. Bureau of Labor Statistics", description: "Civilian unemployment rate, seasonally adjusted."),
        FREDSeries(id: "FEDFUNDS", title: "Federal Funds Effective Rate", units: "Percent", frequency: "Monthly", source: "Board of Governors of the Federal Reserve System", description: "Effective federal funds rate, monthly average."),
        FREDSeries(id: "DFF", title: "Daily Effective Federal Funds Rate", units: "Percent", frequency: "Daily", source: "Board of Governors of the Federal Reserve System", description: "Effective federal funds rate, daily observation. Use this series when you want the un-averaged daily rate."),
        FREDSeries(id: "DGS10", title: "10-Year Treasury Constant Maturity Rate", units: "Percent", frequency: "Daily", source: "Board of Governors of the Federal Reserve System", description: "Market yield on U.S. Treasury securities at 10-year constant maturity."),
        FREDSeries(id: "GDPC1", title: "Real Gross Domestic Product", units: "Billions of dollars", frequency: "Quarterly", source: "U.S. Bureau of Economic Analysis", description: "Real gross domestic product, seasonally adjusted annual rate.")
    ]

    static func observations(for series: FREDSeries) -> [Observation] {
        if series.id == "MORTGAGE30US" {
            return HistoricalDatasets.mortgage30USObservations
        }
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

enum SeriesDisplayMode: String, CaseIterable, Identifiable {
    case chart = "Chart"
    case table = "Table"
    var id: String { rawValue }
}

enum ChartDateRange: String, CaseIterable, Identifiable {
    case oneYear = "1Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"
    case max = "Max"

    var id: String { rawValue }

    func startDate(from latestDate: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: latestDate)
        case .fiveYears:
            return calendar.date(byAdding: .year, value: -5, to: latestDate)
        case .tenYears:
            return calendar.date(byAdding: .year, value: -10, to: latestDate)
        case .max:
            return nil
        }
    }
}

extension Array where Element == Observation {
    func smoothed(window: Int = 5) -> [Observation] {
        guard count > window, window > 1 else { return self }
        let half = window / 2
        var result = [Observation]()
        result.reserveCapacity(count)
        for i in 0..<count {
            let lower = Swift.max(0, i - half)
            let upper = Swift.min(count - 1, i + half)
            var sum = 0.0
            for j in lower...upper {
                sum += self[j].value
            }
            result.append(Observation(date: self[i].date, value: sum / Double(upper - lower + 1)))
        }
        return result
    }
}
