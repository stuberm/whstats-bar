import Foundation

struct WHStatsResponse: Decodable {
    let meta: Meta
    let days: [Day]
    let summary: Summary

    struct Meta: Decodable {
        let version: String
        let generatedAt: String
        let dateRange: DateRange

        struct DateRange: Decodable {
            let from: String
            let to: String
        }
    }

    struct Day: Decodable, Identifiable {
        let date: String
        let dayName: String
        let grossBooked: Double
        let netBooked: Double
        let clocked: Double
        let excludedFromNet: Bool
        let entries: [Entry]

        var id: String { date }

        struct Entry: Decodable, Identifiable {
            let id: Int
            let project: Project
            let issue: Issue
            let hours: Double
            let comments: String

            struct Project: Decodable {
                let id: Int
                let name: String
            }

            struct Issue: Decodable {
                let id: Int
            }
        }
    }

    struct Summary: Decodable {
        let workdays: Int
        let targetHoursPerDay: Double
        let targetTotal: Double
        let hasPartialCurrentDayTarget: Bool
        let partialCurrentDayTarget: Double?
        let booked: Booked
        let clocked: Clocked
        let discrepancies: Discrepancies
        let percentages: Percentages
        let currentDate: String
        let isClockRunningToday: Bool

        struct Booked: Decodable {
            let total: Double
            let past: Double
            let today: Double
        }

        struct Clocked: Decodable {
            let total: Double
            let past: Double
            let today: Double
        }

        struct Discrepancies: Decodable {
            let booked: Double
            let clocked: Double
        }

        struct Percentages: Decodable {
            let booked: Int
            let clocked: Int
            let efficiency: Int
        }
    }
}
