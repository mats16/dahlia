import SwiftUI

/// 設定画面「一般」タブ。会議検出とエディタを管理する。
struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        SettingsPage {
            SettingsSection(title: L10n.display) {
                SettingsCard {
                    SettingsControlRow(
                        title: L10n.appLanguage,
                        description: L10n.appLanguageDescription
                    ) {
                        Picker(L10n.appLanguage, selection: $settings.appLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 220)
                    }
                }
            }

            SettingsSection(title: L10n.workflow) {
                SettingsCard {
                    SettingsToggleRow(
                        title: L10n.meetingDetection,
                        description: L10n.meetingDetectionDescription,
                        isOn: $settings.meetingDetectionEnabled
                    )

                    Divider()

                    SettingsControlRow(
                        title: L10n.markdownEditor,
                        description: L10n.markdownEditorDescription
                    ) {
                        Picker(L10n.markdownEditor, selection: $settings.markdownEditor) {
                            ForEach(MarkdownEditor.availableEditors) { editor in
                                Text(editor.displayName).tag(editor)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 240)
                    }
                }
            }
        }
    }
}
