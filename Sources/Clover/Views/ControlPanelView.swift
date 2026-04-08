import SwiftUI
import UniformTypeIdentifiers

/// ホバー時に背景がハイライトされるアイコンボタンスタイル。
struct ToolbarIconButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(configuration.isPressed
                        ? Color.primary.opacity(0.15)
                        : isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

/// メイン領域のタブ種別。
enum DetailTab: String, CaseIterable, Identifiable {
    case summary
    case notes
    case screenshots
    case transcript

    var id: String { rawValue }

    var label: String {
        switch self {
        case .summary: L10n.summary
        case .notes: L10n.notes
        case .screenshots: L10n.screenshots
        case .transcript: L10n.transcript
        }
    }

    var icon: String {
        switch self {
        case .summary: "text.badge.checkmark"
        case .notes: "pencil.line"
        case .screenshots: "camera.viewfinder"
        case .transcript: "waveform.badge.microphone"
        }
    }
}

/// Notion 風タブバー。選択中はピル型背景、ホバーで薄いハイライト。
private struct DetailTabBar: View {
    @Binding var selection: DetailTab
    @ObservedObject var viewModel: CaptionViewModel
    @ObservedObject var sidebarViewModel: SidebarViewModel

    var body: some View {
        HStack(spacing: 2) {
            ForEach(DetailTab.allCases) { tab in
                DetailTabButton(
                    tab: tab,
                    isSelected: selection == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = tab
                    }
                }
            }
            Spacer()
            SessionSettingsMenu(viewModel: viewModel)
            TranscribeButton(viewModel: viewModel, sidebarViewModel: sidebarViewModel)
        }
    }
}

/// セッション設定メニュー（音声ソース・言語選択）。
private struct SessionSettingsMenu: View {
    @ObservedObject var viewModel: CaptionViewModel
    @State private var isHovered = false

    var body: some View {
        Menu {
            // 音声ソース（サブメニュー）
            Menu("音声ソース") {
                ForEach(AudioSourceMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.audioSourceMode = mode
                    } label: {
                        if viewModel.audioSourceMode == mode {
                            Label(mode.label, systemImage: "checkmark")
                        } else {
                            Text(mode.label)
                        }
                    }
                    .disabled(viewModel.isListening)
                }
            }

            // 文字起こし言語（サブメニュー）
            Menu("文字起こし言語") {
                if viewModel.filteredLocales.isEmpty {
                    let id = viewModel.selectedLocale
                    let name = Locale.current.localizedString(forIdentifier: id) ?? id
                    Button {
                        viewModel.changeLocale(id)
                    } label: {
                        Label(name, systemImage: "checkmark")
                    }
                } else {
                    ForEach(viewModel.filteredLocales, id: \.identifier) { locale in
                        let id = locale.identifier
                        let name = locale.localizedString(forIdentifier: id) ?? id
                        Button {
                            viewModel.changeLocale(id)
                        } label: {
                            if viewModel.selectedLocale == id {
                                Label(name, systemImage: "checkmark")
                            } else {
                                Text(name)
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
                )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// 文字起こし開始/停止ボタン。
private struct TranscribeButton: View {
    @ObservedObject var viewModel: CaptionViewModel
    @ObservedObject var sidebarViewModel: SidebarViewModel

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(viewModel.isListening ? .white : .white)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.isListening ? Color.red : Color.accentColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.analyzerReady || sidebarViewModel.selectedProjectURL == nil)
        .keyboardShortcut(.space, modifiers: [])
    }

    private func toggle() {
        if viewModel.isViewingHistory {
            guard let dbQueue = sidebarViewModel.dbQueue,
                  let projectURL = sidebarViewModel.selectedProjectURL,
                  let project = sidebarViewModel.selectedProject,
                  let vaultURL = sidebarViewModel.currentVault?.url,
                  let transcriptionId = viewModel.currentTranscriptionId else { return }
            Task {
                await viewModel.startListening(
                    dbQueue: dbQueue,
                    projectURL: projectURL,
                    projectId: project.id,
                    projectName: project.name,
                    vaultURL: vaultURL,
                    appendingTo: transcriptionId
                )
            }
        } else {
            guard let dbQueue = sidebarViewModel.dbQueue,
                  let projectURL = sidebarViewModel.selectedProjectURL,
                  let project = sidebarViewModel.selectedProject,
                  let vaultURL = sidebarViewModel.currentVault?.url else { return }
            viewModel.toggleListening(
                dbQueue: dbQueue,
                projectURL: projectURL,
                projectId: project.id,
                projectName: project.name,
                vaultURL: vaultURL
            )
        }
    }

    private var iconName: String {
        viewModel.isListening ? "stop.fill" : "circle.fill"
    }

    private var label: String {
        viewModel.isListening ? "Stop transcribing" : "Start transcribing"
    }
}

/// Notion 風の個別タブボタン。
private struct DetailTabButton: View {
    let tab: DetailTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                Text(tab.label)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? Color.primary.opacity(0.08)
                            : isHovered ? Color.primary.opacity(0.04) : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// メインコントロールウィンドウ（議事録ビュー）。
struct ControlPanelView: View {
    @ObservedObject var viewModel: CaptionViewModel
    @ObservedObject var sidebarViewModel: SidebarViewModel
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var selectedTab: DetailTab = .transcript

    var body: some View {
        VStack(spacing: 12) {
            // 準備中プログレス
            if viewModel.isPreparingAnalyzer {
                ProgressView(L10n.preparingSpeechRecognition)
                    .progressViewStyle(.linear)
            }

            // タブ切り替え
            DetailTabBar(selection: $selectedTab, viewModel: viewModel, sidebarViewModel: sidebarViewModel)

            // タブコンテンツ
            GroupBox {
                switch selectedTab {
                case .summary:
                    summaryTabContent
                case .notes:
                    notesTabContent
                case .screenshots:
                    screenshotsTabContent
                case .transcript:
                    transcriptTabContent
                }
            }
            .frame(minHeight: 280)

            // エラー表示
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            // 要約ステータス
            if viewModel.isSummaryGenerating {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.generatingSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            if let summaryError = viewModel.summaryError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(summaryError)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            if let summaryURL = viewModel.lastSummaryURL {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(L10n.summaryGenerated)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button(L10n.openSummary) {
                        AppSettings.shared.markdownEditor.open(summaryURL)
                    }
                    .font(.caption)
                    Spacer()
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 500)
        .navigationTitle(headerTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.currentTranscriptionId != nil {
                    Button(action: { viewModel.exportTranscript() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(viewModel.store.segments.isEmpty)
                    .help(L10n.export)
                }
            }
        }
    }

    // MARK: - Tab Contents

    @ViewBuilder
    private var summaryTabContent: some View {
        if let summaryURL = viewModel.lastSummaryURL {
            VStack {
                Spacer()
                Button(L10n.openSummary) {
                    AppSettings.shared.markdownEditor.open(summaryURL)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView {
                Label(L10n.summary, systemImage: "list.bullet.clipboard")
            } description: {
                if viewModel.isSummaryGenerating {
                    ProgressView(L10n.generatingSummary)
                } else {
                    Text("要約はまだ生成されていません")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var notesTabContent: some View {
        ContentUnavailableView {
            Label(L10n.notes, systemImage: "pencil.line")
        } description: {
            Text("ノート機能は準備中です")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var screenshotsTabContent: some View {
        ContentUnavailableView {
            Label(L10n.screenshots, systemImage: "camera.viewfinder")
        } description: {
            Text("スクリーンショット機能は準備中です")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var transcriptTabContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.store.segments) { segment in
                        TranscriptRowView(segment: segment)
                    }

                    // 録音中インジケータ
                    if viewModel.isListening {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                            Text(L10n.recognizing)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 68)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(8)
            }
            .onChange(of: viewModel.store.segments.count) {
                withAnimation {
                    proxy.scrollTo("bottom")
                }
            }
        }
    }

    // MARK: - Computed

    /// ヘッダーに表示する「プロジェクト名 - トランスクリプション名」。
    private var headerTitle: String {
        guard let project = sidebarViewModel.selectedProject else { return "" }
        let transcriptName: String
        if let transcriptionId = viewModel.currentTranscriptionId,
           let record = sidebarViewModel.transcriptionsForSelectedProject.first(where: { $0.id == transcriptionId }) {
            transcriptName = record.title.isEmpty
                ? Self.headerDateFormatter.string(from: record.startedAt)
                : record.title
        } else {
            transcriptName = "new"
        }
        return "\(project.name) - \(transcriptName)"
    }

    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f
    }()


}
