import SwiftUI

/// 設定画面「AI 要約」タブ。LLM エンドポイントを管理する。
struct AISummarySettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiToken = ""
    @State private var isTestingConnection = false
    @State private var connectionTestResult: ConnectionTestResult?
    private enum ConnectionTestResult {
        case success
        case failure(String)
    }

    var body: some View {
        SettingsPage {
            SettingsSection(title: L10n.autoSummary) {
                SettingsCard {
                    SettingsToggleRow(
                        title: L10n.autoSummary,
                        description: L10n.autoSummaryDescription,
                        isOn: $settings.llmAutoSummaryEnabled
                    )
                    .disabled(!isLLMConfigComplete)
                }
            }

            SettingsSection(
                title: L10n.llmSettings,
                description: L10n.llmSettingsDescription
            ) {
                SettingsCard {
                    SettingsControlRow(title: L10n.endpointURL) {
                        TextField(
                            "",
                            text: $settings.llmEndpointURL,
                            prompt: Text("https://…/mlflow/v1/chat/completions")
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    SettingsControlRow(title: L10n.modelName) {
                        TextField(
                            "",
                            text: $settings.llmModelName,
                            prompt: Text("databricks-gpt-5-4")
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    SettingsControlRow(
                        title: L10n.apiToken,
                        description: L10n.apiTokenStoredInKeychain
                    ) {
                        SecureField("", text: $apiToken)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { settings.llmAPIToken = apiToken }
                    }
                }
            }

            SettingsSection(
                title: L10n.testConnection,
                description: L10n.connectionDiagnosticsDescription
            ) {
                SettingsCard {
                    VStack(alignment: .leading, spacing: 16) {
                        if isTestingConnection {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .controlSize(.small)
                                Text(L10n.testing)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Button(L10n.testConnection) {
                                testConnection()
                            }
                            .disabled(!isLLMConfigComplete)
                        }

                        if let result = connectionTestResult {
                            switch result {
                            case .success:
                                SettingsStatusMessage(
                                    text: L10n.connectionSuccess,
                                    systemImage: "checkmark.circle.fill",
                                    tint: .green
                                )
                            case let .failure(message):
                                SettingsStatusMessage(
                                    text: message,
                                    systemImage: "xmark.circle.fill",
                                    tint: .red
                                )
                            }
                        } else if !isLLMConfigComplete {
                            Text(L10n.llmConfigIncomplete)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .task {
            apiToken = settings.llmAPIToken
        }
        .onDisappear {
            settings.llmAPIToken = apiToken
        }
    }

    // MARK: - Private

    private var isLLMConfigComplete: Bool {
        !settings.llmEndpointURL.isEmpty && !settings.llmModelName.isEmpty && !apiToken.isEmpty
    }

    private func testConnection() {
        settings.llmAPIToken = apiToken
        connectionTestResult = nil
        isTestingConnection = true
        Task {
            do {
                try await LLMService.testConnection(
                    endpoint: settings.llmEndpointURL,
                    model: settings.llmModelName,
                    token: apiToken
                )
                connectionTestResult = .success
            } catch {
                connectionTestResult = .failure(error.localizedDescription)
            }
            isTestingConnection = false
        }
    }
}
