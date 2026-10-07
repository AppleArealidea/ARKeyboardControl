import UIKit
import ObjectiveC

private var keyboardObserverKey: UInt8 = 0

public extension UIView {

    /// Calls `actionHandler` when the keyboard shows, hides or changes its frame.
    /// The handler runs inside an animation that matches the keyboard's, with
    /// frames in the receiver's coordinates. To position views, constrain them
    /// to `keyboardLayoutGuide`; use this for work a constraint cannot do.
    func addKeyboardControl(actionHandler: @escaping KeyboardDidMoveBlock) {
        let observer = KeyboardObserver(view: self, handler: actionHandler)
        objc_setAssociatedObject(self, &keyboardObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func removeKeyboardControl() {
        objc_setAssociatedObject(self, &keyboardObserverKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    var isKeyboardOpened: Bool {
        (objc_getAssociatedObject(self, &keyboardObserverKey) as? KeyboardObserver)?.isKeyboardVisible ?? false
    }
}
