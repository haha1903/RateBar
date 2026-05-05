@testable import RateBar
import XCTest

/// Tests for the launch-at-login service wrapper and menu toggle state.
@MainActor
final class LaunchAtLoginTests: XCTestCase {
    func testToggleEnable() throws {
        let service = SpyLaunchAtLoginService(status: .notRegistered)
        let launchAtLogin = LaunchAtLogin(service: service)

        launchAtLogin.isEnabled = true

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertEqual(service.unregisterCallCount, 0)
        XCTAssertTrue(launchAtLogin.isEnabled)
        XCTAssertNil(launchAtLogin.lastError)
    }

    func testToggleDisable() throws {
        let service = SpyLaunchAtLoginService(status: .enabled)
        let launchAtLogin = LaunchAtLogin(service: service)

        launchAtLogin.isEnabled = false

        XCTAssertEqual(service.registerCallCount, 0)
        XCTAssertEqual(service.unregisterCallCount, 1)
        XCTAssertFalse(launchAtLogin.isEnabled)
        XCTAssertNil(launchAtLogin.lastError)
    }

    func testStatusReflectsRegistration() throws {
        let service = SpyLaunchAtLoginService(status: .notRegistered)
        let launchAtLogin = LaunchAtLogin(service: service)

        XCTAssertFalse(launchAtLogin.isEnabled)

        launchAtLogin.isEnabled = true

        XCTAssertEqual(launchAtLogin.status, .enabled)
        XCTAssertTrue(launchAtLogin.isEnabled)
    }

    func testLaunchAtLoginToggleInvokesSetter() {
        let spy = LaunchAtLoginToggleSpy()
        let toggle = LaunchAtLoginToggle(isEnabled: false, setEnabled: spy.setEnabled)

        toggle.setEnabled(true)

        XCTAssertEqual(spy.values, [true])
        XCTAssertEqual(toggle.title, LocalizedStrings.launchAtLogin)
    }
}

@MainActor
private final class SpyLaunchAtLoginService: LaunchAtLoginServicing {
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    var status: LaunchAtLoginStatus

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    /// Records registration and mirrors the enabled status that SMAppService would report.
    func register() throws {
        registerCallCount += 1
        status = .enabled
    }

    /// Records unregistration and mirrors the disabled status that SMAppService would report.
    func unregister() throws {
        unregisterCallCount += 1
        status = .notRegistered
    }
}

@MainActor
private final class LaunchAtLoginToggleSpy {
    private(set) var values: [Bool] = []

    /// Records the latest toggle value sent by the menu control.
    func setEnabled(_ isEnabled: Bool) {
        values.append(isEnabled)
    }
}
