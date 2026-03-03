import Foundation

enum Formatting {
    static let hoursFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func hours(_ value: Double) -> String {
        let number = NSNumber(value: value)
        return hoursFormatter.string(from: number) ?? String(format: "%.2f", value)
    }

    private static let inputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let outputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    static func date(_ rawValue: String) -> String {
        guard let date = inputDateFormatter.date(from: rawValue) else {
            return rawValue
        }
        return outputDateFormatter.string(from: date)
    }
}
