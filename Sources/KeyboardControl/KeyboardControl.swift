import UIKit
import ObjectiveC

private var keyboardObserverKey: UInt8 = 0

public extension UIView {

    // MARK: - Panning (interactive keyboard dismiss)

    func addKeyboardPanning(
        frameBasedActionHandler: @escaping KeyboardDidMoveBlock,
        constraintBasedActionHandler: @escaping KeyboardDidMoveBlock
    ) {
        let observer = getOrCreateObserver()
        observer.frameBasedBlock = frameBasedActionHandler
        observer.constraintBasedBlock = constraintBasedActionHandler

        if let scrollView = self as? UIScrollView {
            scrollView.keyboardDismissMode = .interactive
        }

        if observer.panHandler == nil {
            observer.panHandler = KeyboardPanHandler(view: self, observer: observer)
        } else {
            observer.panHandler?.observer = observer
        }
        observer.registerNotificationObservers(ifNeeded: .panning)
    }

    // MARK: - Non-panning (keyboard awareness only)

    func addKeyboardNonpanning(actionHandler: @escaping KeyboardDidMoveBlock) {
        let observer = getOrCreateObserver()
        observer.frameBasedBlock = actionHandler

        if #available(iOS 15.0, *) {
            let adapter = KeyboardLayoutGuideAdapter(view: self, actionBlock: actionHandler)
            observer.layoutGuideAdapter = adapter
            observer.registerNotificationObservers(ifNeeded: .keyboardOnly)
        } else {
            observer.registerNotificationObservers(ifNeeded: .keyboardOnly)
        }
    }

    // MARK: - Cleanup

    func removeKeyboardControl() {
        guard let observer = keyboardObserver else { return }
        observer.tearDown()
        objc_setAssociatedObject(self, &keyboardObserverKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - Keyboard utilities

    func hideKeyboard() {
        keyboardObserver?.hideKeyboard()
    }

    var keyboardPanRecognizer: UIPanGestureRecognizer? {
        keyboardObserver?.panHandler?.panRecognizer
    }

    var keyboardFrameInView: CGRect {
        keyboardObserver?.keyboardFrameInView() ?? CGRect(x: 0, y: UIScreen.main.bounds.height, width: 0, height: 0)
    }

    var isKeyboardOpened: Bool {
        keyboardObserver?.isKeyboardVisible ?? false
    }

    // MARK: - Private

    private var keyboardObserver: KeyboardObserver? {
        objc_getAssociatedObject(self, &keyboardObserverKey) as? KeyboardObserver
    }

    private func getOrCreateObserver() -> KeyboardObserver {
        if let existing = keyboardObserver { return existing }
        let observer = KeyboardObserver(view: self)
        objc_setAssociatedObject(self, &keyboardObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observer
    }
}
