import Foundation

enum GoogleDriveFolderItemKind: Equatable {
    case folder
    case sharedDrive
}

struct GoogleDriveFolderItem: Equatable, Identifiable {
    let id: String
    let name: String
    let detail: String
    let kind: GoogleDriveFolderItemKind

    init(
        id: String,
        name: String,
        detail: String,
        kind: GoogleDriveFolderItemKind = .folder
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.kind = kind
    }
}
