import Foundation

/// ContentView の詳細表示状態を表すスナップショット。
struct ContentNavigationState: Equatable {
    var destination: SidebarDestination
    var selectedProjectId: UUID?
    var selectedProjectName: String?
    var selectedMeetingId: UUID?
    var selectedInstructionId: UUID?
}
