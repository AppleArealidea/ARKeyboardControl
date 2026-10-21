import XCTest
import KeyboardControl

final class KeyboardDismissPaddingTests: XCTestCase {

    func testPaddingIsForwardedToKeyboardLayoutGuide() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("keyboardDismissPadding needs iOS 17") }
        let view = UIView()
        view.keyboardDismissPadding = 52
        XCTAssertEqual(view.keyboardLayoutGuide.keyboardDismissPadding, 52)
        XCTAssertEqual(view.keyboardDismissPadding, 52)
    }

    func testPaddingReadsGuideValue() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("keyboardDismissPadding needs iOS 17") }
        let view = UIView()
        XCTAssertEqual(view.keyboardDismissPadding, 0)
        view.keyboardLayoutGuide.keyboardDismissPadding = 30
        XCTAssertEqual(view.keyboardDismissPadding, 30)
    }
}
