import UIKit

@available(iOS 15.0, *)
final class KeyboardLayoutGuideAdapter {

    weak var view: UIView?
    var actionBlock: KeyboardDidMoveBlock?
    private var observation: NSKeyValueObservation?
    private var lastLayoutFrame: CGRect = .zero
    private var wasVisible = false

    init(view: UIView, actionBlock: @escaping KeyboardDidMoveBlock) {
        self.view = view
        self.actionBlock = actionBlock

        let guide = view.keyboardLayoutGuide
        observation = guide.observe(\.layoutFrame, options: [.new, .old]) { [weak self] _, change in
            self?.handleLayoutChange(oldFrame: change.oldValue, newFrame: change.newValue)
        }
    }

    deinit {
        observation?.invalidate()
    }

    private func handleLayoutChange(oldFrame: CGRect?, newFrame: CGRect?) {
        guard let view = view, newFrame != nil else { return }

        let screenHeight = view.bounds.height
        guard screenHeight > 0 else { return }

        let guide = view.keyboardLayoutGuide
        let guideFrame = guide.layoutFrame

        let isVisible = guideFrame.height > view.safeAreaInsets.bottom
        let beginFrame = lastLayoutFrame.isEmpty ? CGRect(x: 0, y: screenHeight, width: view.bounds.width, height: 0) : lastLayoutFrame
        let endFrame = CGRect(x: 0, y: guideFrame.minY, width: guideFrame.width, height: guideFrame.height)

        let opening = isVisible && !wasVisible
        let closing = !isVisible && wasVisible

        if opening || closing || beginFrame != endFrame {
            actionBlock?(beginFrame, endFrame, opening, closing)
        }

        wasVisible = isVisible
        lastLayoutFrame = endFrame
    }
}
