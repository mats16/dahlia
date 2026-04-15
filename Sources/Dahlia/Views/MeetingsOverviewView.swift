import SwiftUI

/// サイドバーの Meetings から開く全 meeting 一覧。
struct MeetingsOverviewView: View {
    private enum Filter: String, CaseIterable, Identifiable {
        case all
        case today
        case inProgress

        var id: Self { self }

        var title: String {
            switch self {
            case .all:
                L10n.all
            case .today:
                L10n.today
            case .inProgress:
                L10n.inProgress
            }
        }
    }

    @ObservedObject var viewModel: CaptionViewModel
    var sidebarViewModel: SidebarViewModel
    var onSelectMeeting: (UUID) -> Void

    @State private var filter: Filter = .all

    private var meetings: [MeetingOverviewItem] {
        let allMeetings = sidebarViewModel.allMeetings
        let calendar = Calendar.current

        switch filter {
        case .all:
            return allMeetings
        case .today:
            return allMeetings.filter { calendar.isDateInToday($0.createdAt) }
        case .inProgress:
            return allMeetings.filter { $0.status == .recording }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.meetings)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 10) {
                        Button(action: resetFilter) {
                            Text(filter.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.primary.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(L10n.newTranscription, systemImage: "plus", action: createNewMeeting)
                            .labelStyle(.iconOnly)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.05))
                            )
                            .buttonStyle(.plain)
                            .help(L10n.newTranscription)
                            .accessibilityLabel(L10n.newTranscription)
                    }

                    Menu {
                        ForEach(Filter.allCases) { option in
                            Button {
                                filter = option
                            } label: {
                                if option == filter {
                                    Label(option.title, systemImage: "checkmark")
                                } else {
                                    Text(option.title)
                                }
                            }
                        }
                    } label: {
                        Label(L10n.filter, systemImage: "line.3.horizontal.decrease")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }

                if meetings.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.noMeetingsYet, systemImage: "calendar")
                    } description: {
                        Text(filter == .all ? L10n.newTranscription : L10n.noMeetingsMatchFilter)
                    } actions: {
                        if filter == .all {
                            Button(L10n.newTranscription, action: createNewMeeting)
                        } else {
                            Button(L10n.all, action: resetFilter)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(meetings) { item in
                            MeetingsOverviewRow(
                                item: item,
                                isSelected: sidebarViewModel.selectedMeetingId == item.meetingId,
                                onSelect: { selectMeeting(item) },
                                onDelete: { sidebarViewModel.deleteMeeting(id: item.meetingId) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.background)
        .onDeleteCommand(perform: deleteSelection)
    }

    private func resetFilter() {
        filter = .all
    }

    private func selectMeeting(_ item: MeetingOverviewItem) {
        sidebarViewModel.singleSelectMeeting(
            item.meetingId,
            projectId: item.projectId,
            projectName: item.projectName
        )
        onSelectMeeting(item.meetingId)
    }

    private func createNewMeeting() {
        guard let dbQueue = sidebarViewModel.dbQueue,
              let vault = sidebarViewModel.currentVault,
              let project = sidebarViewModel.fetchOrCreateProject(name: "Meetings")
        else { return }

        sidebarViewModel.selectProject(id: project.record.id, name: project.record.name)
        viewModel.createEmptyMeeting(
            dbQueue: dbQueue,
            projectURL: project.url,
            projectId: project.record.id,
            projectName: project.record.name,
            vaultURL: vault.url
        )

        if let newId = viewModel.currentMeetingId {
            sidebarViewModel.selectMeeting(newId)
            onSelectMeeting(newId)
        }
    }

    private func deleteSelection() {
        let ids = sidebarViewModel.effectiveSelectedIds
        guard !ids.isEmpty else { return }

        if ids.count == 1, let id = ids.first {
            sidebarViewModel.deleteMeeting(id: id)
        } else {
            sidebarViewModel.deleteMeetings(ids: ids)
        }
    }
}

private struct MeetingsOverviewRow: View {
    private static let defaultProjectName = "Meetings"

    let item: MeetingOverviewItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 14) {
                    avatar

                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayTitle)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(displaySubtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 10) {
                        if let badgeTitle {
                            Text(badgeTitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.primary.opacity(0.04))
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                }
                        }

                        Text(relativeDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundStyle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)

            if isHovering {
                Button(L10n.delete, role: .destructive, action: onDelete)
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .padding(.top, 18)
                    .transition(.opacity)
            }
        }
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(L10n.delete, role: .destructive, action: onDelete)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarGradient)
                .frame(width: 38, height: 38)

            Text(avatarMonogram)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .overlay(alignment: .bottomTrailing) {
            if item.status == .recording {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle()
                            .stroke(.background, lineWidth: 2)
                    }
                    .accessibilityHidden(true)
            } else if differentiateWithoutColor {
                Image(systemName: "waveform")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Circle().fill(Color.black.opacity(0.18)))
                    .offset(x: 4, y: 4)
                    .accessibilityHidden(true)
            }
        }
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.primary.opacity(isHovering ? 0.04 : 0.02))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05), lineWidth: 1)
            }
    }

    private var displayTitle: String {
        let trimmed = item.meetingName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return L10n.newMeeting
    }

    private var displaySubtitle: String {
        if let preview = trimmedPreview, !preview.isEmpty {
            return preview
        }
        if item.status == .recording {
            return L10n.recordingNow
        }
        if item.segmentCount == 0 {
            return L10n.noConversationDetected
        }
        return badgeTitle ?? item.projectName
    }

    private var badgeTitle: String? {
        guard item.projectName != Self.defaultProjectName else { return nil }
        return item.projectName.split(separator: "/").last.map(String.init) ?? item.projectName
    }

    private var relativeDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(item.createdAt) {
            return L10n.today
        }
        if calendar.isDateInYesterday(item.createdAt) {
            return L10n.yesterday
        }
        return item.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var trimmedPreview: String? {
        let preview = item.latestSegmentText?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let preview, !preview.isEmpty else { return nil }
        return preview
    }

    private var avatarMonogram: String {
        let source = displayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let character = source.first else { return "M" }
        return String(character).uppercased()
    }

    private var avatarGradient: LinearGradient {
        let colors: [(Color, Color)] = [
            (.blue, .cyan),
            (.orange, .yellow),
            (.teal, .mint),
            (.indigo, .purple),
            (.pink, .red),
            (.green, .teal),
        ]
        let pair = colors[abs(item.projectId.hashValue) % colors.count]
        return LinearGradient(
            colors: [pair.0, pair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accessibilityLabel: String {
        "\(displayTitle), \(displaySubtitle), \(relativeDate)"
    }
}
