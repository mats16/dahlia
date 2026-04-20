import Foundation
@testable import Dahlia

#if canImport(Testing)
import Testing

struct AgentServiceTests {
    @Test
    func resolveLaunchArgumentsFallsBackToClaudeWhenBlank() {
        let arguments = AgentService.resolveLaunchArguments(from: "   ")

        #expect(arguments == ["claude"])
    }

    @Test
    func resolveLaunchArgumentsSplitsCommandAndArguments() {
        let arguments = AgentService.resolveLaunchArguments(from: "isaac --profile local")

        #expect(arguments == ["isaac", "--profile", "local"])
    }
}
#elseif canImport(XCTest)
import XCTest

final class AgentServiceTests: XCTestCase {
    func testResolveLaunchArgumentsFallsBackToClaudeWhenBlank() {
        XCTAssertEqual(AgentService.resolveLaunchArguments(from: "   "), ["claude"])
    }

    func testResolveLaunchArgumentsSplitsCommandAndArguments() {
        XCTAssertEqual(
            AgentService.resolveLaunchArguments(from: "isaac --profile local"),
            ["isaac", "--profile", "local"]
        )
    }
}
#endif
