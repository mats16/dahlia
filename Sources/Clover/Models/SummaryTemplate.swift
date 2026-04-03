import Foundation

/// 要約テンプレートファイルを表す値型。
struct SummaryTemplate: Identifiable, Hashable {
    let url: URL

    var id: String { url.lastPathComponent }

    /// ファイル名（拡張子なし）: "customer_meeting"
    var name: String { url.deletingPathExtension().lastPathComponent }

    /// 表示名: "customer_meeting" → "customer meeting"
    var displayName: String { name.replacingOccurrences(of: "_", with: " ") }
}
