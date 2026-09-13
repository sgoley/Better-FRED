import Foundation

enum SeriesCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case inflation = "Inflation"
    case labor = "Labor"
    case monetary = "Fed & Rates"
    case treasuries = "Treasuries"
    case gdp = "GDP & Growth"
    case housing = "Housing"
    case money = "Money Supply"
    case markets = "Markets"
    case commodities = "Commodities"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .inflation: return "chart.line.uptrend.xyaxis"
        case .labor: return "person.3.fill"
        case .monetary: return "building.columns.fill"
        case .treasuries: return "percent"
        case .gdp: return "globe.americas.fill"
        case .housing: return "house.fill"
        case .money: return "dollarsign.circle.fill"
        case .markets: return "waveform.path.ecg"
        case .commodities: return "flame.fill"
        }
    }
}

struct CategorizedSeries: Identifiable {
    var id: String { series.id }
    let series: FREDSeries
    let category: SeriesCategory
}

enum PopularSeries {
    static let entries: [CategorizedSeries] = [
        // MARK: - Housing
        CategorizedSeries(
            series: FREDSeries(
                id: "MORTGAGE30US",
                title: "30-Year Fixed Rate Mortgage Average in the United States",
                units: "Percent",
                frequency: "Weekly",
                source: "Freddie Mac via FRED®",
                description: "The 30-year fixed-rate mortgage average in the United States (weekly ending Thursday, not seasonally adjusted). Freddie Mac surveys lenders on rates and points for their most popular 30-year fixed-rate mortgage products."
            ),
            category: .housing
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "MORTGAGE15US",
                title: "15-Year Fixed Rate Mortgage Average in the United States",
                units: "Percent",
                frequency: "Weekly",
                source: "Freddie Mac via FRED®",
                description: "The 15-year fixed-rate mortgage average in the United States (weekly ending Thursday, not seasonally adjusted)."
            ),
            category: .housing
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "CSUSHPINSA",
                title: "S&P/CoreLogic Case-Shiller U.S. National Home Price Index",
                units: "Index Jan 2000=100",
                frequency: "Monthly",
                source: "S&P Dow Jones Indices",
                description: "Measures the change in value of the U.S. residential housing market, tracking single-family home purchases."
            ),
            category: .housing
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "HOUST",
                title: "New Privately-Owned Housing Units Started",
                units: "Thousands of Units",
                frequency: "Monthly",
                source: "U.S. Census Bureau",
                description: "Total housing starts nationwide (seasonally adjusted annual rate)."
            ),
            category: .housing
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "PERMIT",
                title: "New Privately-Owned Housing Units Authorized by Building Permits",
                units: "Thousands of Units",
                frequency: "Monthly",
                source: "U.S. Census Bureau",
                description: "Leading indicator of new housing construction based on permit authorizations."
            ),
            category: .housing
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "EXHOSLUSM495S",
                title: "Existing Home Sales",
                units: "Millions of Units",
                frequency: "Monthly",
                source: "National Association of Realtors",
                description: "Completed transactions that include single-family homes, townhomes, condominiums, and co-ops."
            ),
            category: .housing
        ),

        // MARK: - Inflation
        CategorizedSeries(
            series: FREDSeries(
                id: "CPIAUCSL",
                title: "Consumer Price Index for All Urban Consumers: All Items (CPI)",
                units: "Index 1982–84=100",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Measures monthly change in prices paid by U.S. urban consumers for a representative basket of goods and services."
            ),
            category: .inflation
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "CPILFESL",
                title: "Core CPI: All Items Less Food and Energy",
                units: "Index 1982–84=100",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Consumer Price Index excluding volatile food and energy components to gauge underlying persistent inflation trends."
            ),
            category: .inflation
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "PCEPI",
                title: "Personal Consumption Expenditures: Chain-type Price Index",
                units: "Index 2017=100",
                frequency: "Monthly",
                source: "U.S. Bureau of Economic Analysis",
                description: "Measures price changes for goods and services consumed by all households, including third-party paid healthcare."
            ),
            category: .inflation
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "PCEPILFE",
                title: "Core PCE Price Index: Less Food and Energy",
                units: "Index 2017=100",
                frequency: "Monthly",
                source: "U.S. Bureau of Economic Analysis",
                description: "The Federal Reserve's primary preferred benchmark for assessing underlying domestic inflation toward its 2% target."
            ),
            category: .inflation
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "PPIACO",
                title: "Producer Price Index: All Commodities",
                units: "Index 1982=100",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Measures average change over time in selling prices received by domestic producers for their output."
            ),
            category: .inflation
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "T10YIE",
                title: "10-Year Breakeven Inflation Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Bank of St. Louis",
                description: "The spread between nominal 10-year Treasuries and 10-year TIPS, representing market inflation expectations over a 10-year horizon."
            ),
            category: .inflation
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "MICH",
                title: "University of Michigan: Inflation Expectation",
                units: "Percent",
                frequency: "Monthly",
                source: "University of Michigan",
                description: "Median expected price change over the next 12 months as reported by U.S. consumers in the Michigan Surveys of Consumers."
            ),
            category: .inflation
        ),

        // MARK: - Labor & Employment
        CategorizedSeries(
            series: FREDSeries(
                id: "UNRATE",
                title: "Civilian Unemployment Rate",
                units: "Percent",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Civilian unemployment rate (U-3), the percentage of the labor force that is unemployed and actively seeking work."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "PAYEMS",
                title: "All Employees, Total Nonfarm Payrolls",
                units: "Thousands of Persons",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Total number of U.S. nonfarm wage and salary workers on payrolls, key monthly measure of labor market growth."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "CIVPART",
                title: "Labor Force Participation Rate",
                units: "Percent",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "The proportion of the civilian noninstitutional population aged 16 and older that is employed or actively looking for work."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "JTSJOL",
                title: "Job Openings: Total Nonfarm (JOLTS)",
                units: "Thousands",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Total unfilled job openings across the U.S. nonfarm economy, demonstrating labor demand."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "ICSA",
                title: "Initial Claims for Unemployment Insurance",
                units: "Number",
                frequency: "Weekly",
                source: "U.S. Employment and Training Administration",
                description: "Weekly count of emerging filings by individuals seeking state unemployment benefits, a premier high-frequency leading economic indicator."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "CCSA",
                title: "Continued Claims (Insured Unemployment)",
                units: "Number",
                frequency: "Weekly",
                source: "U.S. Employment and Training Administration",
                description: "Weekly count of workers continuing to receive unemployment insurance benefits."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "CES0500000003",
                title: "Average Hourly Earnings of All Employees, Total Private",
                units: "Dollars per Hour",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Average hourly earnings of all private-sector employees, closely watched for wage pressure and wage-push inflation."
            ),
            category: .labor
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "U6RATE",
                title: "Total Unemployed Plus Marginally Attached & Underemployed (U-6)",
                units: "Percent",
                frequency: "Monthly",
                source: "U.S. Bureau of Labor Statistics",
                description: "Broadest measure of labor underutilization, including discouraged workers and involuntary part-time employees."
            ),
            category: .labor
        ),

        // MARK: - Fed & Monetary Policy
        CategorizedSeries(
            series: FREDSeries(
                id: "FEDFUNDS",
                title: "Federal Funds Effective Rate (Monthly Average)",
                units: "Percent",
                frequency: "Monthly",
                source: "Federal Reserve Board",
                description: "Monthly average of the interest rate at which depository institutions trade federal funds with each other overnight."
            ),
            category: .monetary
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DFF",
                title: "Daily Effective Federal Funds Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Daily volume-weighted median rate of overnight federal funds transactions arranged by major brokers."
            ),
            category: .monetary
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "SOFR",
                title: "Secured Overnight Financing Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Bank of New York",
                description: "Broad measure of the cost of borrowing cash overnight collateralized by Treasury securities (primary USD reference rate replacing LIBOR)."
            ),
            category: .monetary
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "WALCL",
                title: "Federal Reserve Total Assets (Balance Sheet)",
                units: "Millions of Dollars",
                frequency: "Weekly",
                source: "Federal Reserve Board",
                description: "Total assets held on the Federal Reserve balance sheet, reflecting Quantitative Easing (QE) and Quantitative Tightening (QT)."
            ),
            category: .monetary
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "IORB",
                title: "Interest Rate on Reserve Balances",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "The rate of interest paid by Federal Reserve Banks on balances maintained by or on behalf of eligible institutions."
            ),
            category: .monetary
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "RPONTSYD",
                title: "Overnight Reverse Repurchase Agreements: Total Sold",
                units: "Billions of Dollars",
                frequency: "Daily",
                source: "Federal Reserve Bank of New York",
                description: "Daily volume of the Fed's Overnight Reverse Repo (ON RRP) facility, absorbing excess liquidity from financial institutions."
            ),
            category: .monetary
        ),

        // MARK: - Treasuries & Yield Curve
        CategorizedSeries(
            series: FREDSeries(
                id: "DGS3MO",
                title: "3-Month Treasury Constant Maturity Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Yield on U.S. Treasury bills at 3-month constant maturity, standard benchmark for front-end short-term cash yields."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DGS2",
                title: "2-Year Treasury Constant Maturity Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Yield on U.S. Treasury securities at 2-year constant maturity, highly sensitive to market monetary policy path expectations."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DGS5",
                title: "5-Year Treasury Constant Maturity Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Market yield on U.S. Treasury securities at 5-year constant maturity."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DGS10",
                title: "10-Year Treasury Constant Maturity Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Yield on U.S. Treasury securities at 10-year constant maturity, global benchmark for sovereign debt and long-term capital costs."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DGS30",
                title: "30-Year Treasury Constant Maturity Rate",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Yield on the long bond (30-year U.S. Treasury bond), benchmark for long-duration institutional liability management."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "T10Y2Y",
                title: "10-Year Treasury Minus 2-Year Treasury (2s10s Spread)",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Bank of St. Louis",
                description: "Difference between 10-Year and 2-Year Treasury rates. Inversions (negative spread) have historically preceded U.S. recessions."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "T10Y3M",
                title: "10-Year Treasury Minus 3-Month Treasury Spread",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Bank of St. Louis",
                description: "Yield spread between 10-Year and 3-Month Treasuries, favored by the Federal Reserve as a recession probability indicator."
            ),
            category: .treasuries
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DFII10",
                title: "10-Year Treasury Inflation-Indexed Security (Real Yield)",
                units: "Percent",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Market yield on 10-year TIPS, representing the real return demanded by investors above headline inflation."
            ),
            category: .treasuries
        ),

        // MARK: - GDP & Economic Growth
        CategorizedSeries(
            series: FREDSeries(
                id: "GDPC1",
                title: "Real Gross Domestic Product",
                units: "Billions of Chained 2017 Dollars",
                frequency: "Quarterly",
                source: "U.S. Bureau of Economic Analysis",
                description: "Inflation-adjusted value of goods and services produced by labor and property located in the United States."
            ),
            category: .gdp
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "GDP",
                title: "Gross Domestic Product (Nominal)",
                units: "Billions of Dollars",
                frequency: "Quarterly",
                source: "U.S. Bureau of Economic Analysis",
                description: "Gross domestic product at current market prices (seasonally adjusted annual rate)."
            ),
            category: .gdp
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "INDPRO",
                title: "Industrial Production Index",
                units: "Index 2017=100",
                frequency: "Monthly",
                source: "Federal Reserve Board",
                description: "Measures real output of all relevant facilities located in the U.S. including manufacturing, mining, and electric/gas utilities."
            ),
            category: .gdp
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "TCU",
                title: "Capacity Utilization: Total Industry",
                units: "Percent of Capacity",
                frequency: "Monthly",
                source: "Federal Reserve Board",
                description: "Percentage of resources used by manufacturing, mining, and electric and gas utilities in the U.S. economy."
            ),
            category: .gdp
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "RSAFS",
                title: "Advance Retail Sales: Retail and Food Services",
                units: "Millions of Dollars",
                frequency: "Monthly",
                source: "U.S. Census Bureau",
                description: "Monthly estimate of consumer spending across retail stores and restaurants nationwide."
            ),
            category: .gdp
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "PCEC",
                title: "Personal Consumption Expenditures (Nominal)",
                units: "Billions of Dollars",
                frequency: "Monthly",
                source: "U.S. Bureau of Economic Analysis",
                description: "Measures all consumer spending by U.S. residents, accounting for approximately 68-70% of total U.S. GDP."
            ),
            category: .gdp
        ),

        // MARK: - Money Supply & Banking
        CategorizedSeries(
            series: FREDSeries(
                id: "M2SL",
                title: "M2 Money Supply (Seasonally Adjusted)",
                units: "Billions of Dollars",
                frequency: "Monthly",
                source: "Federal Reserve Board",
                description: "Total currency, checkable deposits, savings deposits, and small-denomination time deposits held by households and businesses."
            ),
            category: .money
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "WM2NS",
                title: "M2 Money Supply (Weekly Not Seasonally Adjusted)",
                units: "Billions of Dollars",
                frequency: "Weekly",
                source: "Federal Reserve Board",
                description: "Weekly observation of the broad money supply aggregate."
            ),
            category: .money
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "TOTBKCR",
                title: "Bank Credit, All Commercial Banks",
                units: "Billions of Dollars",
                frequency: "Weekly",
                source: "Federal Reserve Board",
                description: "Total loans, leases, and securities held by commercial banks operating in the United States."
            ),
            category: .money
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "BUSLOANS",
                title: "Commercial and Industrial Loans, All Commercial Banks",
                units: "Billions of Dollars",
                frequency: "Weekly",
                source: "Federal Reserve Board",
                description: "Commercial and industrial lending volumes, reflecting corporate and small business debt borrowing trends."
            ),
            category: .money
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DPSACBW027SBOG",
                title: "Deposits, All Commercial Banks",
                units: "Billions of Dollars",
                frequency: "Weekly",
                source: "Federal Reserve Board",
                description: "Total deposits held across all commercial banks in the U.S."
            ),
            category: .money
        ),

        // MARK: - Financial Markets & Stress
        CategorizedSeries(
            series: FREDSeries(
                id: "VIXCLS",
                title: "CBOE Volatility Index (VIX)",
                units: "Index",
                frequency: "Daily",
                source: "Chicago Board Options Exchange",
                description: "Premier benchmark of 30-day expected stock market volatility implied by S&P 500 index option prices."
            ),
            category: .markets
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "NFCI",
                title: "Chicago Fed National Financial Conditions Index",
                units: "Index",
                frequency: "Weekly",
                source: "Federal Reserve Bank of Chicago",
                description: "Comprehensive measure of U.S. financial conditions in money, debt, and equity markets (positive = tighter than average)."
            ),
            category: .markets
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "BAMLH0A0HYM2",
                title: "ICE BofA US High Yield Option-Adjusted Spread",
                units: "Percent",
                frequency: "Daily",
                source: "ICE Data Indices",
                description: "Spread between corporate junk bond yields and spot Treasury curve, reflecting credit risk appetite and default expectations."
            ),
            category: .markets
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "SP500",
                title: "S&P 500 Stock Price Index",
                units: "Index",
                frequency: "Daily",
                source: "S&P Dow Jones Indices",
                description: "Market-capitalization-weighted index of 500 leading publicly traded companies in the United States."
            ),
            category: .markets
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "STLFSI4",
                title: "St. Louis Fed Financial Stress Index",
                units: "Index",
                frequency: "Weekly",
                source: "Federal Reserve Bank of St. Louis",
                description: "Measures the degree of financial stress in the markets; zero indicates normal financial market conditions."
            ),
            category: .markets
        ),

        // MARK: - Commodities & FX
        CategorizedSeries(
            series: FREDSeries(
                id: "DCOILWTICO",
                title: "Crude Oil Prices: West Texas Intermediate (WTI)",
                units: "Dollars per Barrel",
                frequency: "Daily",
                source: "U.S. Energy Information Administration",
                description: "Spot benchmark price of West Texas Intermediate light sweet crude oil at Cushing, Oklahoma."
            ),
            category: .commodities
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DCOILBRENTEU",
                title: "Crude Oil Prices: Brent - Europe",
                units: "Dollars per Barrel",
                frequency: "Daily",
                source: "U.S. Energy Information Administration",
                description: "Global spot price benchmark for North Sea Brent crude oil."
            ),
            category: .commodities
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "GASREGW",
                title: "U.S. Regular All Formulations Retail Gasoline Prices",
                units: "Dollars per Gallon",
                frequency: "Weekly",
                source: "U.S. Energy Information Administration",
                description: "Average price paid by consumers at retail pumps nationwide for regular gasoline."
            ),
            category: .commodities
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "GOLDAMGBD228NLBM",
                title: "Gold Fixing Price in London Bullion Market",
                units: "U.S. Dollars per Troy Ounce",
                frequency: "Daily",
                source: "ICE Benchmark Administration",
                description: "Morning gold price fix at 10:30 A.M. London time in the London Bullion Market."
            ),
            category: .commodities
        ),
        CategorizedSeries(
            series: FREDSeries(
                id: "DTWEXBGS",
                title: "Nominal Broad U.S. Dollar Index",
                units: "Index Jan 2006=100",
                frequency: "Daily",
                source: "Federal Reserve Board",
                description: "Weighted average foreign exchange value of the U.S. dollar against currencies of a broad group of major trading partners."
            ),
            category: .commodities
        )
    ]

    static let all: [FREDSeries] = entries.map(\.series)

    static func series(in category: SeriesCategory) -> [FREDSeries] {
        if category == .all { return all }
        return entries.filter { $0.category == category }.map(\.series)
    }

    static func category(for seriesId: String) -> SeriesCategory? {
        entries.first { $0.series.id == seriesId }?.category
    }

    /// Fast local search with tiered relevance ranking:
    /// 1. Exact series ID match (e.g. "CPIAUCSL", "DGS10")
    /// 2. Prefix ID match (e.g. "MORTG" -> "MORTGAGE30US")
    /// 3. Substring ID match
    /// 4. Word-boundary or prefix match in title
    /// 5. General substring match in title or description
    static func search(query: String, in list: [FREDSeries] = all) -> [FREDSeries] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return list }

        var exactIdMatches: [FREDSeries] = []
        var prefixIdMatches: [FREDSeries] = []
        var containsIdMatches: [FREDSeries] = []
        var titlePrefixMatches: [FREDSeries] = []
        var titleContainsMatches: [FREDSeries] = []
        var descMatches: [FREDSeries] = []

        var seen = Set<String>()

        for item in list {
            let idLower = item.id.lowercased()
            let titleLower = item.title.lowercased()
            let descLower = item.description.lowercased()

            if idLower == clean {
                exactIdMatches.append(item)
                seen.insert(item.id)
            } else if idLower.hasPrefix(clean) {
                prefixIdMatches.append(item)
                seen.insert(item.id)
            } else if idLower.contains(clean) {
                containsIdMatches.append(item)
                seen.insert(item.id)
            } else if titleLower.hasPrefix(clean) || titleLower.contains(" " + clean) {
                titlePrefixMatches.append(item)
                seen.insert(item.id)
            } else if titleLower.contains(clean) {
                titleContainsMatches.append(item)
                seen.insert(item.id)
            } else if descLower.contains(clean) {
                descMatches.append(item)
                seen.insert(item.id)
            }
        }

        return exactIdMatches + prefixIdMatches + containsIdMatches + titlePrefixMatches + titleContainsMatches + descMatches
    }
}
