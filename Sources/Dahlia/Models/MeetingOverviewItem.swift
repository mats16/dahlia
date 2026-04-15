import Foundation
import GRDB

/// Meetings ワークスペースに表示する一覧用の集約モデル。
struct MeetingOverviewItem: Decodable, Equatable, FetchableRecord, Identifiable {
    var meetingId: UUID
    var projectId: UUID
    var projectName: String
    var meetingName: String
    var status: MeetingStatus
    var duration: TimeInterval?
    var createdAt: Date
    var segmentCount: Int
    var latestSegmentText: String?

    var id: UUID { meetingId }

    var meeting: MeetingRecord {
        MeetingRecord(
            id: meetingId,
            projectId: projectId,
            name: meetingName,
            status: status,
            duration: duration,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
