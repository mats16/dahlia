import Foundation
import GRDB
@testable import Dahlia

#if canImport(Testing)
import Testing

struct AppDatabaseManagerTests {
    @Test
    func initializesInMemoryDatabaseWithGoogleDriveFolderColumn() throws {
        let database = try AppDatabaseManager(path: ":memory:")

        let columns = try database.dbQueue.read { db in
            try String.fetchAll(db, sql: "PRAGMA table_info(projects)")
        }

        #expect(columns.contains("googleDriveFolderId"))
    }

    @Test
    func repositoryUpdatesProjectGoogleDriveFolder() throws {
        let database = try AppDatabaseManager(path: ":memory:")
        let repository = MeetingRepository(dbQueue: database.dbQueue)
        let vault = VaultRecord(
            id: .v7(),
            path: "/tmp/test-vault",
            name: "Test Vault",
            createdAt: Date(),
            lastOpenedAt: Date()
        )
        try repository.insertVault(vault)

        let project = try repository.fetchOrCreateProject(name: "Project A", vaultId: vault.id)
        try repository.updateProjectGoogleDriveFolder(id: project.id, folderId: "folder-123")

        let updatedProject = try #require(repository.fetchProject(id: project.id))
        #expect(updatedProject.googleDriveFolderId == "folder-123")
    }
}
#elseif canImport(XCTest)
import XCTest

final class AppDatabaseManagerTests: XCTestCase {
    func testInitializesInMemoryDatabaseWithGoogleDriveFolderColumn() throws {
        let database = try AppDatabaseManager(path: ":memory:")

        let columns = try database.dbQueue.read { db in
            try String.fetchAll(db, sql: "PRAGMA table_info(projects)")
        }

        XCTAssertTrue(columns.contains("googleDriveFolderId"))
    }

    func testRepositoryUpdatesProjectGoogleDriveFolder() throws {
        let database = try AppDatabaseManager(path: ":memory:")
        let repository = MeetingRepository(dbQueue: database.dbQueue)
        let vault = VaultRecord(
            id: .v7(),
            path: "/tmp/test-vault",
            name: "Test Vault",
            createdAt: Date(),
            lastOpenedAt: Date()
        )
        try repository.insertVault(vault)

        let project = try repository.fetchOrCreateProject(name: "Project A", vaultId: vault.id)
        try repository.updateProjectGoogleDriveFolder(id: project.id, folderId: "folder-123")

        let updatedProject = try XCTUnwrap(repository.fetchProject(id: project.id))
        XCTAssertEqual(updatedProject.googleDriveFolderId, "folder-123")
    }
}
#endif
