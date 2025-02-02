import Foundation

extension DateFormatter {
    static let mangaDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
