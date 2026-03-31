import UIKit

final class KeyboardPanHandler: NSObject, UIGestureRecognizerDelegate {

    private(set) var panRecognizer: UIPanGestureRecognizer!
    weak var observer: KeyboardObserver?
    private weak var targetView: UIView?
    private var triggerOffset: CGFloat = 0
    private var isInstalled = false

    init(view: UIView, observer: KeyboardObserver) {
        self.targetView = view
        self.observer = observer
        super.init()

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panDidChange(_:)))
        panRecognizer.minimumNumberOfTouches = 1
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = false
    }

    func installIfNeeded() {
        guard !isInstalled, let view = targetView else { return }
        view.addGestureRecognizer(panRecognizer)
        isInstalled = true
    }

    func uninstall() {
        guard isInstalled, let view = targetView else { return }
        view.removeGestureRecognizer(panRecognizer)
        isInstalled = false
    }

    // MARK: - Pan gesture

    @objc private func panDidChange(_ gesture: UIPanGestureRecognizer) {
        guard let observer = observer else { return }

        if observer.keyboardView == nil || observer.activeInput == nil || observer.keyboardView?.isHidden == true {
            if let view = targetView {
                observer.activeInput = observer.findFirstResponder(in: view)
            }
            observer.keyboardView = observer.activeInput?.inputAccessoryView?.superview
            observer.keyboardView?.isHidden = false
        } else {
            observer.keyboardView?.isHidden = false
        }

        guard let kv = observer.keyboardView, let kvSuperview = kv.superview else { return }

        let keyboardHeight = kv.bounds.height
        let windowHeight = kvSuperview.bounds.height
        let touchLocation = gesture.location(in: kvSuperview)

        if touchLocation.y > windowHeight - keyboardHeight - triggerOffset {
            kv.isUserInteractionEnabled = false
        } else {
            kv.isUserInteractionEnabled = true
        }

        switch gesture.state {
        case .began:
            gesture.maximumNumberOfTouches = gesture.numberOfTouches

        case .changed:
            var newFrame = kv.frame
            newFrame.origin.y = touchLocation.y + triggerOffset
            newFrame.origin.y = min(newFrame.origin.y, windowHeight)
            newFrame.origin.y = max(newFrame.origin.y, windowHeight - keyboardHeight)

            if newFrame.origin.y != kv.frame.origin.y {
                UIView.animate(withDuration: 0, delay: 0, options: [.beginFromCurrentState], animations: {
                    kv.frame = newFrame
                })
            }

        case .ended, .cancelled:
            let thresholdHeight = windowHeight - keyboardHeight - triggerOffset + 44.0
            let velocity = gesture.velocity(in: kv)
            let shouldDismiss = touchLocation.y >= thresholdHeight && velocity.y >= 0

            var newFrame = kv.frame
            newFrame.origin.y = shouldDismiss ? windowHeight : windowHeight - keyboardHeight

            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                kv.frame = newFrame
            }, completion: { _ in
                kv.isUserInteractionEnabled = !shouldDismiss
                if shouldDismiss {
                    observer.hideKeyboard()
                }
            })

            gesture.maximumNumberOfTouches = .max

        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panRecognizer || other === panRecognizer {
            return true
        }
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === panRecognizer else { return true }

        guard let touchView = touch.view else { return true }

        if !touchView.isFirstResponder ||
            (targetView is UITextView && targetView === touchView) {
            var current: UIView? = touchView
            while let parent = current?.superview {
                if parent is UITextView { return false }
                current = parent
            }
            return true
        }
        return false
    }
}
