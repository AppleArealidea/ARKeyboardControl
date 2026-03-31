# ARKeyboardControl

Lightweight Swift library that adds keyboard awareness and interactive dismissal to any `UIView`. Inspired by [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl), rewritten from scratch in pure Swift without method swizzling.

## Features

- **Interactive dismiss** — drag down to dismiss keyboard, like in iMessage
- **Non-panning mode** — track keyboard appearance/disappearance without gestures
- **Two callback modes** — frame-based (inside animation block) and constraint-based (before animation)
- **iOS 15+ optimization** — uses `keyboardLayoutGuide` for non-panning mode when available
- **Minimal footprint** — single associated object per view, clean teardown
- **No swizzling** — no `+load`, no method exchange, no global side effects

## Requirements

- iOS 13.0+
- Swift 5.7+

## Installation

### Swift Package Manager

Add the package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/AppleArealidea/ARKeyboardControl.git", from: "1.0.0")
]
```

Or add it as a local package in Xcode via File > Add Package Dependencies.

## Usage

### Interactive keyboard dismiss (chat screens)

```swift
import KeyboardControl

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    view.addKeyboardPanning { beginFrame, endFrame, opening, closing in
        // Called inside UIView.animate — update frames here
        if opening {
            tableView.contentOffset.y += beginFrame.minY - endFrame.minY
        }
    } constraintBasedActionHandler: { _, endFrame, _, _ in
        // Called before animation — update constraints here
        let offset = view.frame.height - endFrame.minY - view.safeAreaInsets.bottom
        bottomConstraint.constant = offset > 0 ? -offset : 0
    }
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    view.removeKeyboardControl()
}
```

### Keyboard awareness only (no gestures)

```swift
view.addKeyboardNonpanning { _, endFrame, opening, closing in
    let offset = view.frame.height - endFrame.origin.y - view.safeAreaInsets.bottom
    bottomConstraint.constant = offset > 0 ? -offset : 0
    view.layoutIfNeeded()
}
```

On iOS 15+ this automatically uses `keyboardLayoutGuide` under the hood.

### Gesture coordination

Access the pan gesture recognizer to coordinate with other gestures:

```swift
if let keyboardPan = view.keyboardPanRecognizer {
    myGesture.require(toFail: keyboardPan)
}
```

### Utilities

```swift
view.hideKeyboard()        // Programmatically dismiss
view.isKeyboardOpened      // Current state
view.keyboardFrameInView   // Keyboard frame in view's coordinate space
```

### Cleanup

Always call `removeKeyboardControl()` when the view is going away:

```swift
// In viewWillDisappear or deinit
view.removeKeyboardControl()
```

## API

```swift
public extension UIView {
    func addKeyboardPanning(
        frameBasedActionHandler: @escaping KeyboardDidMoveBlock,
        constraintBasedActionHandler: @escaping KeyboardDidMoveBlock
    )
    func addKeyboardNonpanning(actionHandler: @escaping KeyboardDidMoveBlock)
    func removeKeyboardControl()
    func hideKeyboard()

    var keyboardPanRecognizer: UIPanGestureRecognizer? { get }
    var keyboardFrameInView: CGRect { get }
    var isKeyboardOpened: Bool { get }
}

public typealias KeyboardDidMoveBlock = (
    _ keyboardBeginFrame: CGRect,
    _ keyboardEndFrame: CGRect,
    _ opening: Bool,
    _ closing: Bool
) -> Void
```

## Callback parameters

| Parameter | Description |
|-----------|-------------|
| `keyboardBeginFrame` | Keyboard frame before the transition (in view's coordinates) |
| `keyboardEndFrame` | Keyboard frame after the transition (in view's coordinates) |
| `opening` | `true` when keyboard is appearing |
| `closing` | `true` when keyboard is disappearing |

## License

MIT. See [LICENSE](LICENSE) for details.
