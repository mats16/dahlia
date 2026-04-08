import SwiftUI

/// 設定画面「一般」タブ。エディタを管理する。
struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section(L10n.meetingDetection) {
                Toggle(L10n.meetingDetection, isOn: Binding(
                    get: { settings.meetingDetectionEnabled },
                    set: { settings.meetingDetectionEnabled = $0 }
                ))

                Text(L10n.meetingDetectionDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(L10n.editor) {
                Picker(L10n.markdownEditor, selection: Binding(
                    get: { settings.markdownEditor },
                    set: { settings.markdownEditor = $0 }
                )) {
                    ForEach(MarkdownEditor.availableEditors) { editor in
                        Text(editor.displayName).tag(editor)
                    }
                }

                Text(L10n.markdownEditorDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
