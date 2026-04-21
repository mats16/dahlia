import AppKit
import Foundation
@testable import Dahlia

#if canImport(Testing)
import Testing

@MainActor
struct GoogleDriveStoreTests {
    @Test
    func restoreWithoutDriveScopeStaysSignedOut() async {
        let signInProvider = MockGoogleSignInProvider(
            hasPreviousSignIn: true,
            restoreResult: .success(calendarOnlySession)
        )
        let store = GoogleDriveStore(
            signInProvider: signInProvider,
            apiClient: MockGoogleDriveAPIClient(),
            presentingWindowProvider: { NSWindow() }
        )

        await store.restoreSessionIfNeeded()

        #expect(store.state == .signedOut)
        #expect(!store.isAuthorized)
        #expect(store.account == calendarOnlySession.account)
    }

    @Test
    func signInRequestsDriveScopes() async {
        let signInProvider = MockGoogleSignInProvider(
            signInResult: .success(driveSession)
        )
        let store = GoogleDriveStore(
            signInProvider: signInProvider,
            apiClient: MockGoogleDriveAPIClient()
        )

        await store.signIn()

        #expect(signInProvider.signInRequestedScopes == [GoogleOAuthScope.drive])
    }
}

private let calendarOnlySession = GoogleSession(
    account: GoogleCalendarAccount(id: "user-1", displayName: "Kazuki", email: "kazuki@example.com"),
    accessToken: "calendar-token",
    grantedScopes: GoogleOAuthScope.authorizationScopes(for: GoogleOAuthScope.calendar)
)

private let driveSession = GoogleSession(
    account: GoogleCalendarAccount(id: "user-1", displayName: "Kazuki", email: "kazuki@example.com"),
    accessToken: "drive-token",
    grantedScopes: GoogleOAuthScope.authorizationScopes(for: GoogleOAuthScope.drive)
)

@MainActor
private final class MockGoogleSignInProvider: GoogleSignInProviding {
    let isConfigured: Bool
    let hasPreviousSignIn: Bool
    var restoreResult: Result<GoogleSession, Error>
    var signInResult: Result<GoogleSession, Error>
    var refreshResult: Result<GoogleSession?, Error>
    private(set) var signInRequestedScopes: [Set<String>] = []

    init(
        isConfigured: Bool = true,
        hasPreviousSignIn: Bool = false,
        restoreResult: Result<GoogleSession, Error> = .success(driveSession),
        signInResult: Result<GoogleSession, Error> = .success(driveSession),
        refreshResult: Result<GoogleSession?, Error> = .success(driveSession)
    ) {
        self.isConfigured = isConfigured
        self.hasPreviousSignIn = hasPreviousSignIn
        self.restoreResult = restoreResult
        self.signInResult = signInResult
        self.refreshResult = refreshResult
    }

    func restorePreviousSignIn() async throws -> GoogleSession {
        try restoreResult.get()
    }

    func signIn(withPresentingWindow _: NSWindow, requestedScopes: Set<String>) async throws -> GoogleSession {
        signInRequestedScopes.append(requestedScopes)
        try signInResult.get()
    }

    func refreshCurrentSession() async throws -> GoogleSession? {
        try refreshResult.get()
    }

    func disconnect() async throws {}
}

private final class MockGoogleDriveAPIClient: GoogleDriveAPIClientProviding {
    func searchFolders(accessToken _: String, query _: String) async throws -> [GoogleDriveFolderItem] { [] }
    func listFolders(accessToken _: String, parentFolderId _: String?, driveId _: String?) async throws -> [GoogleDriveFolderItem] { [] }
    func listRecentFolders(accessToken _: String) async throws -> [GoogleDriveFolderItem] { [] }
    func listSharedDrives(accessToken _: String) async throws -> [GoogleDriveFolderItem] { [] }
    func fetchFolder(accessToken _: String, id _: String) async throws -> GoogleDriveFolderItem {
        GoogleDriveFolderItem(id: "folder-1", name: "Folder", detail: "My Drive")
    }

    func upsertGoogleDocument(
        accessToken _: String,
        parentFolderId _: String,
        fileName _: String,
        content _: String,
        appProperties _: [String: String]
    ) async throws -> String {
        "document-1"
    }
}
#endif
