import XCTest
@testable import KeyboardControl

final class KeyboardEventClassifierTests: XCTestCase {

    private let hidden = CGRect(x: 0, y: 844, width: 390, height: 336)
    private let shown = CGRect(x: 0, y: 508, width: 390, height: 336)

    func testShowWhileHiddenIsOpening() {
        var classifier = KeyboardEventClassifier()
        let event = classifier.handle(.willShow, begin: hidden, end: shown)
        XCTAssertEqual(event, KeyboardEvent(begin: hidden, end: shown, opening: true, closing: false))
        XCTAssertTrue(classifier.isKeyboardVisible)
    }

    func testShowWhileVisibleIsDropped() {
        var classifier = KeyboardEventClassifier(isKeyboardVisible: true)
        XCTAssertNil(classifier.handle(.willShow, begin: hidden, end: shown))
        XCTAssertTrue(classifier.isKeyboardVisible)
    }

    func testChangeWhileVisibleIsPlainChange() {
        var classifier = KeyboardEventClassifier(isKeyboardVisible: true)
        let taller = CGRect(x: 0, y: 463, width: 390, height: 381)
        let event = classifier.handle(.willChangeFrame, begin: shown, end: taller)
        XCTAssertEqual(event, KeyboardEvent(begin: shown, end: taller, opening: false, closing: false))
    }

    func testChangeWhileHiddenIsDropped() {
        var classifier = KeyboardEventClassifier()
        XCTAssertNil(classifier.handle(.willChangeFrame, begin: hidden, end: shown))
        XCTAssertFalse(classifier.isKeyboardVisible)
    }

    func testHideWithFullTravelIsClosing() {
        var classifier = KeyboardEventClassifier(isKeyboardVisible: true)
        let event = classifier.handle(.willHide, begin: shown, end: hidden)
        XCTAssertEqual(event, KeyboardEvent(begin: shown, end: hidden, opening: false, closing: true))
        XCTAssertTrue(classifier.isKeyboardVisible, "visibility ends at didHide, not at willHide")
    }

    func testHideWithPartialTravelIsOpeningAndClosing() {
        // The end of an interactive drag: the keyboard is already most of the way down.
        var classifier = KeyboardEventClassifier(isKeyboardVisible: true)
        let dragged = CGRect(x: 0, y: 800, width: 390, height: 336)
        let event = classifier.handle(.willHide, begin: dragged, end: hidden)
        XCTAssertEqual(event, KeyboardEvent(begin: dragged, end: hidden, opening: true, closing: true))
    }

    func testHideEndFrameTakesTheBeginHeight() {
        // iOS reports the minimised bar (75 pt) as the end frame of a hide.
        var classifier = KeyboardEventClassifier(isKeyboardVisible: true)
        let minimised = CGRect(x: 0, y: 844, width: 390, height: 75)
        let event = classifier.handle(.willHide, begin: shown, end: minimised)
        XCTAssertEqual(event?.end, hidden)
    }

    func testHideWhileHiddenIsDropped() {
        var classifier = KeyboardEventClassifier()
        XCTAssertNil(classifier.handle(.willHide, begin: shown, end: hidden))
    }

    func testDidHideEndsVisibilityAndDeliversNothing() {
        var classifier = KeyboardEventClassifier(isKeyboardVisible: true)
        XCTAssertNil(classifier.handle(.didHide, begin: nil, end: nil))
        XCTAssertFalse(classifier.isKeyboardVisible)
    }

    func testShowWithoutFramesDeliversNothingButBecomesVisible() {
        var classifier = KeyboardEventClassifier()
        XCTAssertNil(classifier.handle(.willShow, begin: nil, end: shown))
        XCTAssertTrue(classifier.isKeyboardVisible)
    }

    func testFullCycleAllowsTheNextShow() {
        var classifier = KeyboardEventClassifier()
        _ = classifier.handle(.willShow, begin: hidden, end: shown)
        _ = classifier.handle(.willHide, begin: shown, end: hidden)
        _ = classifier.handle(.didHide, begin: nil, end: nil)
        XCTAssertNotNil(classifier.handle(.willShow, begin: hidden, end: shown))
    }
}
