import SwiftUI

/// 設定画面（Cmd+, で表示）。Safari 風の上部タブバーでセクションを切り替える。
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(L10n.general, systemImage: "gearshape")
                }

            TranscriptionSettingsView()
                .tabItem {
                    Label(L10n.transcription, systemImage: "waveform")
                }

            AISummarySettingsView()
                .tabItem {
                    Label(L10n.aiSummary, systemImage: "sparkles")
                }
        }
        .frame(width: 600, height: 480)
    }
}
