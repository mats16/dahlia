import SwiftUI

/// NavigationSplitView でサイドバーと詳細ビューを構成するルートビュー。
struct ContentView: View {
    @ObservedObject var viewModel: CaptionViewModel
    var sidebarViewModel: SidebarViewModel
    var onSelectVault: (VaultRecord) -> Void = { _ in }
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isInspectorPresented = false
    @AppStorage("agentEnabled") private var agentEnabled = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                viewModel: viewModel,
                sidebarViewModel: sidebarViewModel,
                columnVisibility: columnVisibility,
                onSelectVault: onSelectVault
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            ControlPanelView(viewModel: viewModel, sidebarViewModel: sidebarViewModel)
        }
        .inspector(isPresented: $isInspectorPresented) {
            AgentSidebarView(viewModel: viewModel, sidebarViewModel: sidebarViewModel)
                .inspectorColumnWidth(min: 280, ideal: 340, max: 480)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if agentEnabled {
                    Button {
                        isInspectorPresented.toggle()
                    } label: {
                        Label(L10n.agent, systemImage: "sparkles")
                    }
                    .help(L10n.agent)
                }
            }
        }
        .onChange(of: viewModel.currentTranscriptionId) { _, _ in
            if let service = viewModel.agentService, service.mode == .transcript {
                service.resetSegmentTracking(store: viewModel.store)
            }
        }
    }
}
