import XCTest
@testable import KeyboardControl

final class KeyboardFrameValidationTests: XCTestCase {

    func testRejectsZeroRect() {
        XCTAssertFalse(KeyboardFrameValidation.isValid(.zero, event: .willShow, isKeyboardVisible: false))
    }

    func testRejectsMinYZeroWithHeight() {
        let frame = CGRect(x: 0, y: 0, width: 390, height: 335)
        XCTAssertFalse(KeyboardFrameValidation.isValid(frame, event: .willShow, isKeyboardVisible: false))
    }

    func testAcceptsVisibleKeyboardFrame() {
        let frame = CGRect(x: 0, y: 539, width: 390, height: 335)
        XCTAssertTrue(KeyboardFrameValidation.isValid(frame, event: .willShow, isKeyboardVisible: false))
    }

    func testRejectsIOS26ZeroHeightChange() {
        let frame = CGRect(x: 0, y: 539, width: 390, height: 0)
        XCTAssertFalse(KeyboardFrameValidation.isValid(frame, event: .willChange, isKeyboardVisible: true))
    }

    func testAcceptsHideEndFrameBelowScreen() {
        let frame = CGRect(x: 0, y: 874, width: 390, height: 335)
        XCTAssertTrue(KeyboardFrameValidation.isValid(frame, event: .willHide, isKeyboardVisible: true))
    }
}
