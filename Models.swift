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
    /// The exact decimal representation reported by FRED. Charts use `value`, while
    /// alert evaluation uses this value so threshold comparisons are never affected
    /// by binary floating-point rounding.
    let decimalValue: Decimal

    init(date: Date, value: Double, decimalValue: Decimal? = nil) {
        self.date = date
        self.value = value
        self.decimalValue = decimalValue
            ?? Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX"))
            ?? .zero
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case value
        case decimalValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let date = try container.decode(Date.self, forKey: .date)
        let value = try container.decode(Double.self, forKey: .value)
        let decimalValue = try container.decodeIfPresent(Decimal.self, forKey: .decimalValue)
        self.init(date: date, value: value, decimalValue: decimalValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(value, forKey: .value)
        try container.encode(decimalValue, forKey: .decimalValue)
    }
}

enum AlertTrigger: Codable, Hashable {
    case newObservation
    case comparison(ComparisonOperator, threshold: Decimal)
    case change(ComparisonOperator, delta: Decimal)

    enum ComparisonOperator: String, Codable, CaseIterable, Hashable {
        case greaterThan = ">"
        case greaterThanOrEqual = ">="
        case lessThan = "<"
        case lessThanOrEqual = "<="
        case equals = "=="
        case notEquals = "!="

        func matches(_ lhs: Decimal, _ rhs: Decimal) -> Bool {
            switch self {
            case .greaterThan: return lhs > rhs
            case .greaterThanOrEqual: return lhs >= rhs
            case .lessThan: return lhs < rhs
            case .lessThanOrEqual: return lhs <= rhs
            case .equals: return lhs == rhs
            case .notEquals: return lhs != rhs
            }
        }
    }
}

struct AlertRule: Identifiable, Codable, Hashable {
    let id: UUID
    let seriesID: String
    var trigger: AlertTrigger
    var isEnabled: Bool
    var isOneShot: Bool
    var createdAt: Date
    var lastTriggeredDate: Date?

    init(
        id: UUID = UUID(),
        seriesID: String,
        trigger: AlertTrigger,
        isEnabled: Bool = true,
        isOneShot: Bool,
        createdAt: Date = .now,
        lastTriggeredDate: Date? = nil
    ) {
        self.id = id
        self.seriesID = seriesID
        self.trigger = trigger
        self.isEnabled = isEnabled
        self.isOneShot = isOneShot
        self.createdAt = createdAt
        self.lastTriggeredDate = lastTriggeredDate
    }
}

struct AlertCursor: Codable, Hashable {
    let seriesID: String
    var lastSeenObservationDate: Date
    var lastSeenValue: Decimal
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
    static var series: [FREDSeries] {
        PopularSeries.all
    }

    static func observations(for series: FREDSeries) -> [Observation] {
        if series.id == "MORTGAGE30US" {
            return HistoricalDatasets.mortgage30USObservations
        }
        let calendar = Calendar.current
        let isDaily = series.frequency.localizedCaseInsensitiveContains("Daily")
        let isWeekly = series.frequency.localizedCaseInsensitiveContains("Weekly")
        let isQuarterly = series.frequency.localizedCaseInsensitiveContains("Quarterly")

        let base: Double = switch series.id {
        case "UNRATE": 4.1
        case "U6RATE": 7.9
        case "CIVPART": 62.7
        case "FEDFUNDS", "DFF", "IORB": 4.83
        case "SOFR": 4.85
        case "DGS3MO": 4.80
        case "DGS2": 4.15
        case "DGS5": 4.10
        case "DGS10": 4.35
        case "DGS30": 4.60
        case "DFII10": 2.05
        case "T10Y2Y": 0.20
        case "T10Y3M": -0.45
        case "MORTGAGE15US": 5.95
        case "CPIAUCSL": 314.5
        case "CPILFESL": 319.2
        case "PCEPI": 123.1
        case "PCEPILFE": 122.8
        case "PPIACO": 252.0
        case "T10YIE": 2.30
        case "MICH": 3.0
        case "GDPC1": 22_900.0
        case "GDP": 28_700.0
        case "INDPRO": 103.2
        case "TCU": 77.8
        case "RSAFS": 710_000.0
        case "PCEC": 19_600.0
        case "M2SL", "WM2NS": 21_200.0
        case "WALCL": 7_100_000.0
        case "TOTBKCR": 17_800.0
        case "BUSLOANS": 2_800.0
        case "DPSACBW027SBOG": 17_600.0
        case "RPONTSYD": 350.0
        case "PAYEMS": 158_700.0
        case "JTSJOL": 7_700.0
        case "ICSA": 225_000.0
        case "CCSA": 1_850_000.0
        case "CES0500000003": 35.20
        case "CSUSHPINSA": 325.0
        case "HOUST": 1_350.0
        case "PERMIT": 1_420.0
        case "EXHOSLUSM495S": 4.0
        case "VIXCLS": 15.5
        case "NFCI": -0.55
        case "STLFSI4": -0.70
        case "BAMLH0A0HYM2": 3.20
        case "SP500": 5_600.0
        case "DCOILWTICO": 72.5
        case "DCOILBRENTEU": 76.2
        case "GASREGW": 3.35
        case "GOLDAMGBD228NLBM": 2_550.0
        case "DTWEXBGS": 122.0
        default: 100.0
        }

        let pointCount: Int = if isQuarterly {
            40
        } else if isDaily {
            365
        } else if isWeekly {
            156
        } else {
            120
        }

        let scaleFactor = Swift.max(0.01, base * 0.03)

        return (0..<pointCount).map { index in
            let date: Date = if isDaily {
                calendar.date(byAdding: .day, value: index - pointCount + 1, to: .now)!
            } else if isWeekly {
                calendar.date(byAdding: .day, value: (index - pointCount + 1) * 7, to: .now)!
            } else if isQuarterly {
                calendar.date(byAdding: .month, value: (index - pointCount + 1) * 3, to: .now)!
            } else {
                calendar.date(byAdding: .month, value: index - pointCount + 1, to: .now)!
            }

            let offsetFromEnd = Double(index - (pointCount - 1))
            let cycleFreq = isDaily ? 28.0 : (isWeekly ? 12.0 : 6.0)
            let cycle = sin(Double(index) / cycleFreq) * scaleFactor
            let drift = offsetFromEnd * (scaleFactor * 0.015)
            let noise = cos(Double(index) * 0.8) * (scaleFactor * 0.15)
            let finalValue = base + cycle + drift + noise
            return Observation(date: date, value: (series.id == "T10Y2Y" || series.id == "T10Y3M" || series.id == "NFCI" || series.id == "STLFSI4") ? finalValue : Swift.max(0.01, finalValue))
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
