import CoreGraphics

enum KeyboardNotificationKind {
    case willShow
    case willChangeFrame
    case willHide
    case didHide
}

struct KeyboardEvent: Equatable {
    let begin: CGRect
    let end: CGRect
    let opening: Bool
    let closing: Bool
}

/// Turns the keyboard notification stream into the events the handler receives.
/// Frames are expected in the observing view's coordinates.
struct KeyboardEventClassifier {

    private(set) var isKeyboardVisible: Bool

    init(isKeyboardVisible: Bool = false) {
        self.isKeyboardVisible = isKeyboardVisible
    }

    mutating func handle(_ kind: KeyboardNotificationKind, begin: CGRect?, end: CGRect?) -> KeyboardEvent? {
        switch kind {
        case .willShow:
            guard !isKeyboardVisible else { return nil }
            isKeyboardVisible = true
            guard let begin, let end else { return nil }
            return KeyboardEvent(begin: begin, end: end, opening: true, closing: false)

        case .willChangeFrame:
            guard isKeyboardVisible, let begin, let end else { return nil }
            return KeyboardEvent(begin: begin, end: end, opening: false, closing: false)

        case .willHide:
            guard isKeyboardVisible, let begin, var end else { return nil }
            // The system may report a shorter end frame (the minimised bar);
            // the handler gets the height the keyboard had when it started to hide.
            end.size.height = begin.size.height
            let travelsFully = abs(end.origin.y - begin.origin.y) >= begin.height
            return KeyboardEvent(begin: begin, end: end, opening: !travelsFully, closing: true)

        case .didHide:
            isKeyboardVisible = false
            return nil
        }
    }
}
