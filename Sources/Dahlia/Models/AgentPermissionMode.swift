import Foundation

/// Agent CLI の permission mode。
enum AgentPermissionMode: String, CaseIterable, Identifiable {
    case `default`
    case acceptEdits
    case plan
    case bypassPermissions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default:
            L10n.agentPermissionModeDefault
        case .acceptEdits:
            L10n.agentPermissionModeAcceptEdits
        case .plan:
            L10n.agentPermissionModePlan
        case .bypassPermissions:
            L10n.agentPermissionModeBypassPermissions
        }
    }
}
