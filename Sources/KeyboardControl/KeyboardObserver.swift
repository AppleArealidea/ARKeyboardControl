import UIKit

public typealias KeyboardDidMoveBlock = (
    _ keyboardBeginFrame: CGRect,
    _ keyboardEndFrame: CGRect,
    _ opening: Bool,
    _ closing: Bool
) -> Void

final class KeyboardObserver: NSObject {

    private weak var view: UIView?
    private let handler: KeyboardDidMoveBlock
    private var classifier: KeyboardEventClassifier

    var isKeyboardVisible: Bool { classifier.isKeyboardVisible }

    init(view: UIView, handler: @escaping KeyboardDidMoveBlock) {
        self.view = view
        self.handler = handler
        // The keyboard may already be up when the control is added.
        let isUp = view.window != nil
            && view.keyboardLayoutGuide.layoutFrame.height > view.safeAreaInsets.bottom
        classifier = KeyboardEventClassifier(isKeyboardVisible: isUp)
        super.init()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                           name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                           name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                           name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardDidHide(_:)),
                           name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        deliver(.willShow, notification)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        deliver(.willChangeFrame, notification)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        deliver(.willHide, notification)
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        deliver(.didHide, notification)
    }

    private func deliver(_ kind: KeyboardNotificationKind, _ notification: Notification) {
        guard let view else { return }
        let info = notification.userInfo ?? [:]
        // Another app's keyboard (Split View, Slide Over) is not ours to react to.
        if let isLocal = info[UIResponder.keyboardIsLocalUserInfoKey] as? Bool, !isLocal { return }
        let begin = frame(info[UIResponder.keyboardFrameBeginUserInfoKey], in: view)
        let end = frame(info[UIResponder.keyboardFrameEndUserInfoKey], in: view)
        guard let event = classifier.handle(kind, begin: begin, end: end) else { return }

        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curve = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(curve) << 16)
        let handler = self.handler
        UIView.animate(withDuration: duration, delay: 0, options: [options, .beginFromCurrentState]) {
            handler(event.begin, event.end, event.opening, event.closing)
        }
    }

    private func frame(_ value: Any?, in view: UIView) -> CGRect? {
        guard let value = value as? NSValue else { return nil }
        return view.convert(value.cgRectValue, from: nil)
    }
}
