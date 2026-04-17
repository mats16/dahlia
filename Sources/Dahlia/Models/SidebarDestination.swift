import Foundation

enum SidebarDestination: String, CaseIterable, Identifiable {
    case home
    case meetings
    case projects
    case actionItems
    case ask

    var id: Self { self }

    var title: String {
        switch self {
        case .home:
            L10n.home
        case .meetings:
            L10n.meetings
        case .projects:
            L10n.projects
        case .actionItems:
            L10n.actionItems
        case .ask:
            L10n.ask
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .meetings:
            "calendar"
        case .projects:
            "folder"
        case .actionItems:
            "checkmark.circle"
        case .ask:
            "sparkles"
        }
    }
}
