import SwiftUI

/// 設定画面「Agent」タブ。Agent 機能のオン/オフを管理する。
struct AgentSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        SettingsPage {
            SettingsSection(title: L10n.agent) {
                SettingsCard {
                    SettingsToggleRow(
                        title: L10n.agentEnabled,
                        description: L10n.agentEnabledDescription,
                        isOn: $settings.agentEnabled
                    )
                }
            }
        }
    }
}
