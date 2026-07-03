import UIKit

enum KeyboardFrameEvent {
    case willShow
    case willChange
    case willHide
    case kvoUpdate
}

enum KeyboardFrameValidation {
    /// Rejects CGRect.zero, minY==0 bogus frames (Share Extension return),
    /// and iOS 26 spurious height==0 on frame change while keyboard is visible.
    static func isValid(_ frame: CGRect, event: KeyboardFrameEvent, isKeyboardVisible: Bool) -> Bool {
        guard !frame.isNull else { return false }
        if frame.minY == 0 { return false }
        if event == .willChange && isKeyboardVisible && frame.height == 0 { return false }
        return true
    }

    static func offScreenFrame(in view: UIView) -> CGRect {
        let height = view.bounds.height
        return CGRect(x: 0, y: height, width: view.bounds.width, height: 0)
    }
}
