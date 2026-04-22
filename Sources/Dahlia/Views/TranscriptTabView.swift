import SwiftUI

struct TranscriptTabView: View {
    private enum ScrollMetrics {
        static let bottomAnchorID = "transcript-bottom"
        static let coordinateSpaceName = "TranscriptTabScrollView"
        static let followThreshold: CGFloat = 32
    }

    private enum WindowMetrics {
        static let initialWindowSize = 150
        static let loadMoreCount = 100
    }

    private struct BottomOffsetPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    private struct BottomOffsetReader: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: BottomOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named(ScrollMetrics.coordinateSpaceName)).maxY
                    )
            }
            .frame(height: 1)
        }
    }

    @ObservedObject var store: TranscriptStore
    let isListening: Bool
    let showsRecordingIndicator: Bool
    let showsTranslatedText: Bool

    @State private var bottomOffset: CGFloat = 0
    @State private var shouldFollowLatest = true
    @State private var windowSize = WindowMetrics.initialWindowSize

    /// ForEach の ID 照合対象を制限するため、末尾 windowSize 件のみ返す。
    private var windowedSegments: [TranscriptSegment] {
        let segments = store.segments
        guard segments.count > windowSize else { return segments }
        return Array(segments.suffix(windowSize))
    }

    /// 配列確保なしでウィンドウ内のセグメント数を返す。
    private var windowedSegmentCount: Int {
        min(store.segments.count, windowSize)
    }

    private var hasMoreAbove: Bool {
        store.segments.count > windowSize
    }

    var body: some View {
        Group {
            if store.segments.isEmpty, !isListening {
                ContentUnavailableView {
                    Label(L10n.transcript, systemImage: "waveform.badge.microphone")
                } description: {
                    Text("文字起こしはまだありません")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                transcriptScrollView
            }
        }
    }

    private var transcriptScrollView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if hasMoreAbove {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .onAppear {
                                    loadMoreSegments()
                                }
                        }

                        ForEach(windowedSegments) { segment in
                            TranscriptRowView(
                                segment: segment,
                                showsTranslatedText: showsTranslatedText
                            )
                            .equatable()
                        }

                        if showsRecordingIndicator {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 12, height: 12)
                                Text(L10n.recognizing)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.leading, 68)
                        }

                        BottomOffsetReader()
                            .id(ScrollMetrics.bottomAnchorID)
                    }
                    .padding(8)
                }
                .coordinateSpace(name: ScrollMetrics.coordinateSpaceName)
                .onAppear {
                    refreshFollowState(viewportHeight: geometry.size.height, bottomOffset: bottomOffset)
                }
                .onChange(of: geometry.size.height) { _, newHeight in
                    refreshFollowState(viewportHeight: newHeight, bottomOffset: bottomOffset)
                }
                .onPreferenceChange(BottomOffsetPreferenceKey.self) { newOffset in
                    bottomOffset = newOffset
                    refreshFollowState(viewportHeight: geometry.size.height, bottomOffset: newOffset)
                }
                .onChange(of: windowedSegmentCount) { oldCount, newCount in
                    guard newCount > oldCount, shouldFollowLatest else { return }
                    scrollToBottom(using: proxy)
                }
                .onChange(of: shouldFollowLatest) { _, isFollowing in
                    if isFollowing {
                        windowSize = WindowMetrics.initialWindowSize
                    }
                }
            }
        }
    }

    private func loadMoreSegments() {
        windowSize = min(windowSize + WindowMetrics.loadMoreCount, store.segments.count)
    }

    private func refreshFollowState(viewportHeight: CGFloat, bottomOffset: CGFloat) {
        guard viewportHeight > 0 else {
            shouldFollowLatest = true
            return
        }

        let isNearBottom = bottomOffset - viewportHeight <= ScrollMetrics.followThreshold
        if shouldFollowLatest != isNearBottom {
            shouldFollowLatest = isNearBottom
        }
    }

    private func scrollToBottom(using proxy: ScrollViewProxy) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(ScrollMetrics.bottomAnchorID, anchor: .bottom)
        }
    }
}
