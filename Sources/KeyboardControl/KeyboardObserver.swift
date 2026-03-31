import UIKit

public typealias KeyboardDidMoveBlock = (
    _ keyboardBeginFrame: CGRect,
    _ keyboardEndFrame: CGRect,
    _ opening: Bool,
    _ closing: Bool
) -> Void

final class KeyboardObserver: NSObject {

    weak var view: UIView?
    var frameBasedBlock: KeyboardDidMoveBlock?
    var constraintBasedBlock: KeyboardDidMoveBlock?
    var panHandler: KeyboardPanHandler?
    var layoutGuideAdapter: AnyObject?

    private(set) var isKeyboardVisible = false
    private(set) var currentKeyboardFrame: CGRect = .zero

    var activeInput: UIResponder?
    var keyboardView: UIView? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: "frame")
            if let kv = keyboardView {
                kv.addObserver(self, forKeyPath: "frame", options: [], context: nil)
            }
        }
    }

    init(view: UIView) {
        self.view = view
        super.init()
    }

    deinit {
        tearDown()
    }

    // MARK: - Setup

    func setupNotificationObservers() {
        let nc = NotificationCenter.default

        nc.addObserver(self, selector: #selector(textInputDidBeginEditing(_:)),
                       name: UITextField.textDidBeginEditingNotification, object: nil)
        nc.addObserver(self, selector: #selector(textInputDidBeginEditing(_:)),
                       name: UITextView.textDidBeginEditingNotification, object: nil)

        nc.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                       name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidShow),
                       name: UIResponder.keyboardDidShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                       name: UIResponder.keyboardWillHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide),
                       name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    func tearDown() {
        NotificationCenter.default.removeObserver(self)

        if let view = view, let pan = panHandler {
            view.removeGestureRecognizer(pan.panRecognizer)
        }
        panHandler = nil

        keyboardView = nil
        activeInput = nil
        frameBasedBlock = nil
        constraintBasedBlock = nil
        layoutGuideAdapter = nil
    }

    // MARK: - Text Input Tracking

    @objc private func textInputDidBeginEditing(_ notification: Notification) {
        guard let responder = notification.object as? UIResponder else { return }
        activeInput = responder
        ensureInputAccessoryView(for: responder)
    }

    private func ensureInputAccessoryView(for responder: UIResponder) {
        if let tf = responder as? UITextField, tf.inputAccessoryView == nil {
            tf.inputAccessoryView = makeNullAccessoryView()
            activeInput = tf
            refreshKeyboardView()
        } else if let tv = responder as? UITextView, tv.inputAccessoryView == nil, tv.isEditable {
            tv.inputAccessoryView = makeNullAccessoryView()
            activeInput = tv
            refreshKeyboardView()
        }
    }

    private func makeNullAccessoryView() -> UIView {
        let v = UIView(frame: .zero)
        v.backgroundColor = .clear
        return v
    }

    private func refreshKeyboardView() {
        keyboardView = activeInput?.inputAccessoryView?.superview
        keyboardView?.isHidden = false
    }

    // MARK: - Keyboard Notifications

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let view = view, !isKeyboardVisible else { return }
        let info = notification.userInfo ?? [:]

        let beginFrame = frameInView(info[UIResponder.keyboardFrameBeginUserInfoKey], view: view)
        let endFrame = frameInView(info[UIResponder.keyboardFrameEndUserInfoKey], view: view)
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16)

        keyboardView?.isHidden = false
        isKeyboardVisible = true
        currentKeyboardFrame = endFrame

        let hasConstraintBlock = constraintBasedBlock != nil && !endFrame.isNull && !beginFrame.isNull
        if hasConstraintBlock {
            constraintBasedBlock?(beginFrame, endFrame, true, false)
        }

        UIView.animate(withDuration: duration, delay: 0, options: [options, .beginFromCurrentState], animations: {
            if hasConstraintBlock {
                view.layoutIfNeeded()
            }
            if self.frameBasedBlock != nil && !endFrame.isNull && !beginFrame.isNull {
                self.frameBasedBlock?(beginFrame, endFrame, true, false)
            }
        }, completion: { _ in
            self.panHandler?.installIfNeeded()
        })
    }

    @objc private func keyboardDidShow() {
        refreshKeyboardView()
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let view = view, isKeyboardVisible else { return }
        let info = notification.userInfo ?? [:]

        let beginFrame = frameInView(info[UIResponder.keyboardFrameBeginUserInfoKey], view: view)
        let endFrame = frameInView(info[UIResponder.keyboardFrameEndUserInfoKey], view: view)
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16)

        currentKeyboardFrame = endFrame

        let hasConstraintBlock = constraintBasedBlock != nil && !endFrame.isNull && !beginFrame.isNull
        if hasConstraintBlock {
            constraintBasedBlock?(beginFrame, endFrame, false, false)
        }

        UIView.animate(withDuration: duration, delay: 0, options: [options, .beginFromCurrentState], animations: {
            if hasConstraintBlock {
                view.layoutIfNeeded()
            }
            if self.frameBasedBlock != nil && !endFrame.isNull && !beginFrame.isNull {
                self.frameBasedBlock?(beginFrame, endFrame, false, false)
            }
        })
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let view = view, isKeyboardVisible else { return }
        let info = notification.userInfo ?? [:]

        let beginFrame = frameInView(info[UIResponder.keyboardFrameBeginUserInfoKey], view: view)
        var endFrame = frameInView(info[UIResponder.keyboardFrameEndUserInfoKey], view: view)
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16)

        endFrame.size.height = beginFrame.size.height

        let hasConstraintBlock = constraintBasedBlock != nil && !endFrame.isNull && !beginFrame.isNull
        if hasConstraintBlock {
            constraintBasedBlock?(beginFrame, endFrame, false, true)
        }

        UIView.animate(withDuration: duration, delay: 0, options: [options, .beginFromCurrentState], animations: {
            if hasConstraintBlock {
                view.layoutIfNeeded()
            }

            let yDiff = abs(endFrame.origin.y - beginFrame.origin.y)

            if self.frameBasedBlock != nil && !endFrame.isNull && !beginFrame.isNull {
                if yDiff >= beginFrame.height {
                    self.frameBasedBlock?(beginFrame, endFrame, false, true)
                } else {
                    self.frameBasedBlock?(beginFrame, endFrame, true, true)
                }
            }
        }, completion: { _ in
            self.panHandler?.uninstall()
        })
    }

    @objc private func keyboardDidHide() {
        keyboardView?.isHidden = false
        keyboardView?.isUserInteractionEnabled = true
        keyboardView = nil
        activeInput = nil
        isKeyboardVisible = false
        currentKeyboardFrame = .zero
    }

    // MARK: - KVO (keyboard view frame during panning)

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "frame",
              let kv = object as? UIView,
              kv === keyboardView,
              let view = view,
              !kv.isHidden else { return }

        let endFrame = view.convert(kv.frame, from: kv.superview)
        guard endFrame != currentKeyboardFrame else { return }

        frameBasedBlock?(endFrame, endFrame, false, false)
        if constraintBasedBlock != nil {
            constraintBasedBlock?(endFrame, endFrame, false, false)
            view.layoutIfNeeded()
        }
        currentKeyboardFrame = endFrame
    }

    // MARK: - Helpers

    func hideKeyboard() {
        guard let kv = keyboardView else { return }
        kv.isHidden = true
        kv.isUserInteractionEnabled = false
        activeInput?.resignFirstResponder()
    }

    func keyboardFrameInView() -> CGRect {
        guard let view = view, let kv = keyboardView else {
            return CGRect(x: 0, y: UIScreen.main.bounds.height, width: 0, height: 0)
        }
        return view.convert(kv.frame, from: kv.superview)
    }

    func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for sub in view.subviews {
            if let found = findFirstResponder(in: sub) { return found }
        }
        return nil
    }

    private func frameInView(_ value: Any?, view: UIView) -> CGRect {
        guard let nsValue = value as? NSValue else { return .null }
        return view.convert(nsValue.cgRectValue, from: nil)
    }
}
