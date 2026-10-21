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

    /// Extra touch area above the keyboard for the interactive dismissal of a scroll view
    /// (`keyboardDismissMode = .interactive`): the drag takes the keyboard this many points
    /// before the finger reaches it. Set it to the height of the bar that rests on the
    /// keyboard, and the keyboard follows the finger as soon as the finger reaches the bar.
    /// Set it on the view whose `keyboardLayoutGuide` the bar is pinned to (typically the view
    /// controller's view); on the scroll view itself it has no effect.
    /// Backed by `keyboardLayoutGuide.keyboardDismissPadding` on iOS 17 and later;
    /// earlier it does nothing and reads 0.
    var keyboardDismissPadding: CGFloat {
        get {
            guard #available(iOS 17.0, *) else { return 0 }
            return keyboardLayoutGuide.keyboardDismissPadding
        }
        set {
            guard #available(iOS 17.0, *) else { return }
            keyboardLayoutGuide.keyboardDismissPadding = newValue
        }
    }
}
