import Foundation

@MainActor
final class WHStatsViewModel: ObservableObject {
    @Published private(set) var stats: WHStatsResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let service = WHStatsService()

    var menuTitle: String {
        guard let percentage = stats?.summary.percentages.booked else {
            return "WH"
        }
        return "\(percentage)%"
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.fetchStats()
            stats = response
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
