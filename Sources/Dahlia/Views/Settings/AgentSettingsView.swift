import SwiftUI

/// 設定画面「Agent」タブ。Agent 起動コマンドを管理する。
struct AgentSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        SettingsPage {
            SettingsSection(
                title: L10n.agent,
                description: L10n.agentSettingsDescription
            ) {
                SettingsCard {
                    SettingsControlRow(
                        title: L10n.agentLaunchCommand,
                        description: L10n.agentLaunchCommandDescription
                    ) {
                        TextField(AgentService.defaultLaunchCommand, text: $settings.agentLaunchCommand)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}
