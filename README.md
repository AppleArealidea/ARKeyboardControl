# ARKeyboardControl

Small Swift library that reports keyboard show, hide and frame-change events for a `UIView`. Inspired by [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl), rewritten in pure Swift. The package observes keyboard notifications and classifies them; it does not move views and does not recognise gestures.

## Requirements

- iOS 15.0+
- Swift 5.7+

## Installation

### Swift Package Manager

Add the package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/AppleArealidea/ARKeyboardControl.git", from: "2.0.0")
]
```

Or add it as a local package in Xcode via File > Add Package Dependencies.

## API

```swift
public extension UIView {
    func addKeyboardControl(actionHandler: @escaping KeyboardDidMoveBlock)
    func removeKeyboardControl()
    var isKeyboardOpened: Bool { get }
    var keyboardDismissPadding: CGFloat { get set }
}

public typealias KeyboardDidMoveBlock = (
    _ keyboardBeginFrame: CGRect,
    _ keyboardEndFrame: CGRect,
    _ opening: Bool,
    _ closing: Bool
) -> Void
```

- `addKeyboardControl(actionHandler:)` starts observing the keyboard for the view. The handler runs inside a `UIView` animation that uses the duration and curve of the keyboard notification. Frames are in the view's coordinate space. Calling it again replaces the previous observer of that view.
- `removeKeyboardControl()` stops observing.
- `isKeyboardOpened` becomes `true` when the keyboard starts to show and `false` at `keyboardDidHide`. When the control is added to a view that is already in a window, the initial value is taken from the view's `keyboardLayoutGuide`, so adding it while the keyboard is up works. When the view is not in a window yet (for example in `viewDidLoad`), it starts as `false`, and a keyboard that is already up is noticed only at its next show. It is `false` if no control was added. Notifications from another app's keyboard are ignored.
- `keyboardDismissPadding` widens the touch area of the interactive dismissal (`UIScrollView.keyboardDismissMode = .interactive`) above the keyboard: the drag takes the keyboard this many points before the finger reaches it. Set it to the height of the bar that rests on the keyboard, and the keyboard follows the finger as soon as the finger reaches the bar. Set it on the view whose `keyboardLayoutGuide` the bar is pinned to (typically the view controller's view); set on the scroll view itself, it has no effect. It forwards to `keyboardLayoutGuide.keyboardDismissPadding` (iOS 17+); on iOS 15 and 16 it does nothing and reads `0`. It does not need `addKeyboardControl`.

## Events

| Source notification | State when it arrives | `opening` | `closing` | Handler called |
|---|---|---|---|---|
| `keyboardWillShow` | keyboard hidden | `true` | `false` | yes |
| `keyboardWillShow` | keyboard already visible | - | - | no |
| `keyboardWillChangeFrame` | keyboard visible | `false` | `false` | yes |
| `keyboardWillChangeFrame` | keyboard hidden | - | - | no |
| `keyboardWillHide` (end frame is a full keyboard height below the begin frame) | keyboard visible | `false` | `true` | yes |
| `keyboardWillHide` (keyboard already partly lowered, for example at the end of an interactive drag) | keyboard visible | `true` | `true` | yes |
| `keyboardWillHide` | keyboard hidden | - | - | no |
| `keyboardDidHide` | any | - | - | no, it only marks the keyboard as hidden |

For `keyboardWillHide` the end frame passed to the handler has the height of the begin frame, because the system may report a shorter end frame there.

## Positioning views

Position views with `keyboardLayoutGuide`; use the handler for work a constraint cannot express.

```swift
inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

view.addKeyboardControl { [weak self] begin, end, opening, closing in
    // Runs inside the keyboard animation: adjust what constraints cannot express.
    guard let self, opening, !closing else { return }
    self.tableView.contentOffset.y += begin.minY - end.minY
}
```

Interactive dismissal comes from `UIScrollView.keyboardDismissMode = .interactive`.

## Changes

2.1.0 — `keyboardDismissPadding`

2.0.0 — breaking: see above

## License

MIT. See [LICENSE](LICENSE) for details.
