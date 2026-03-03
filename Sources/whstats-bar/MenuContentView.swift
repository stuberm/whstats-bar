import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var viewModel: WHStatsViewModel
    @State private var expandedDayIDs: Set<String> = []
    private let fallbackTargetHours = 8.0
    private let dailyVisualMaxHours = 12.0
    private let baseFont: Font = .system(size: 12)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .font(baseFont)
        .padding(12)
        .frame(width: 420, height: 520)
        .onAppear {
            Task {
                await viewModel.refresh()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("WH Stats")
                    .fontWeight(.semibold)
                if let range = viewModel.stats?.meta.dateRange {
                    Text("\(Formatting.date(range.from)) - \(Formatting.date(range.to))")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: 8) {
                Label("Unable to load stats", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        } else if let stats = viewModel.stats {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    summarySection(stats.summary)
                    daysSection(stats.days, targetPerDay: stats.summary.targetHoursPerDay)
                }
            }
        } else {
            Text("No data loaded yet.")
                .foregroundStyle(.secondary)
        }
    }

    private func summarySection(_ summary: WHStatsResponse.Summary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                statChip(
                    title: "Booked",
                    percentage: "\(summary.percentages.booked)%",
                    absolute: "\(Formatting.hours(summary.booked.total))h"
                )
                statChip(
                    title: "Clocked",
                    percentage: "\(summary.percentages.clocked)%",
                    absolute: "\(Formatting.hours(summary.clocked.total))h"
                )
            }
        }
    }

    private func daysSection(_ days: [WHStatsResponse.Day], targetPerDay: Double) -> some View {
        let orderedDays = days.sorted { $0.date > $1.date }
        let targetHours = targetPerDay > 0 ? targetPerDay : fallbackTargetHours

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                legendChip(color: .blue, text: "Booked")
                legendChip(color: .mint, text: "Clocked")
                legendChip(color: .white, text: "Target \(Formatting.hours(targetHours))h")
            }

            ForEach(orderedDays) { day in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(Formatting.date(day.date)) [\(day.dayName)]")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(Formatting.hours(day.grossBooked))h / \(Formatting.hours(day.clocked))h")
                            .foregroundStyle(.secondary)
                    }

                    DailyHoursBar(
                        booked: day.grossBooked,
                        clocked: day.clocked,
                        target: targetHours,
                        maxHours: dailyVisualMaxHours
                    )

                    Button {
                        toggleEntries(for: day.id)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: expandedDayIDs.contains(day.id) ? "chevron.down" : "chevron.right")
                                .frame(width: 10)
                            Text("\(day.entries.count) entries - \(Formatting.hours(day.grossBooked))h booked / \(Formatting.hours(day.clocked))h clocked")
                            Spacer()
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    if expandedDayIDs.contains(day.id) {
                        entriesDetail(for: day.entries)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func statChip(title: String, percentage: String, absolute: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(percentage)
                .fontWeight(.semibold)
            Text(absolute)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func legendChip(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: 6, height: 6)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }

    private func entriesDetail(for entries: [WHStatsResponse.Day.Entry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entries.indices, id: \.self) { index in
                let entry = entries[index]

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(Formatting.hours(entry.hours))h")
                            .fontWeight(.semibold)
                            .frame(width: 38, alignment: .leading)
                        Text(entry.project.name)
                            .lineLimit(1)
                        Text("#\(entry.issue.id)")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    if !entry.comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(entry.comments)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if index < entries.count - 1 {
                    Divider()
                        .opacity(0.35)
                }
            }
        }
        .padding(.top, 2)
    }

    private func toggleEntries(for dayID: String) {
        if expandedDayIDs.contains(dayID) {
            expandedDayIDs.remove(dayID)
        } else {
            expandedDayIDs.insert(dayID)
        }
    }

    private var footer: some View {
        HStack {
            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
            } else {
                Text("Not updated yet")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Refresh") {
                Task {
                    await viewModel.refresh()
                }
            }
            .keyboardShortcut("r")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

}

private struct DailyHoursBar: View {
    let booked: Double
    let clocked: Double
    let target: Double
    let maxHours: Double

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let targetX = clampedWidth(for: target, totalWidth: width)
            let segmentWidths = stackedWidths(totalWidth: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 8)

                HStack(spacing: 0) {
                    Capsule()
                        .fill(Color.blue.opacity(0.9))
                        .frame(width: segmentWidths.bookedWidth, height: 8)
                    Capsule()
                        .fill(Color.mint.opacity(0.9))
                        .frame(width: segmentWidths.clockedWidth, height: 8)
                    Spacer(minLength: 0)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 1, height: 12)
                    .offset(x: max(0, min(width - 1, targetX)))
            }
        }
        .frame(height: 12)
    }

    private func clampedWidth(for hours: Double, totalWidth: Double) -> Double {
        let normalized = max(0, min(hours, maxHours)) / maxHours
        return totalWidth * normalized
    }

    private func stackedWidths(totalWidth: Double) -> (bookedWidth: Double, clockedWidth: Double) {
        let clampedBooked = min(max(0, booked), maxHours)
        let clampedClocked = min(max(0, clocked), maxHours)

        // Show booked first; then only the positive clocked-booked difference.
        let deltaClocked = max(0, clampedClocked - clampedBooked)
        let stackedClockedEnd = min(clampedBooked + deltaClocked, maxHours)

        let bookedWidth = clampedWidth(for: clampedBooked, totalWidth: totalWidth)
        let stackedClockedEndWidth = clampedWidth(for: stackedClockedEnd, totalWidth: totalWidth)

        return (
            bookedWidth: bookedWidth,
            clockedWidth: max(0, stackedClockedEndWidth - bookedWidth)
        )
    }
}
