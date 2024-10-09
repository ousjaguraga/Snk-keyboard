import UIKit

class KeyButton: UIButton {
    var popupView: UIView?
    var popupLabel: UILabel?
    private var initialTouchPoint: CGPoint?
    private var currentPopupOffset: CGFloat = 0

    /// Closure to handle key press action
    var keyPressAction: (() -> Void)?

    /// Enables the popup display when the key is pressed.
    func enablePopup() {
        // Remove all existing targets to prevent default .touchUpInside actions
        self.removeTarget(nil, action: nil, for: .allEvents)

        // Initialize and configure the gesture recognizer
        let touchGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTouchGesture(_:)))
        touchGesture.minimumPressDuration = 0
        touchGesture.cancelsTouchesInView = true // Prevent button's default touch events
        self.addGestureRecognizer(touchGesture)
    }

    @objc private func handleTouchGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: self)
            showPopup()
        //case .changed:
            //handlePopupDrag(gesture)
        case .ended, .cancelled:
            // Call the keyPressAction closure
            self.keyPressAction?()
            hidePopup()
            initialTouchPoint = nil
            currentPopupOffset = 0
        default:
            break
        }
    }

   
    /// Displays the popup view above the key with customized corner radius.
    @objc func showPopup() {
        guard popupView == nil, let windowView = self.window else { return }

        // Hide the key label when the popup shows
        self.titleLabel?.alpha = 0

        // Get the frame of the key button relative to the window
        let keyFrameInWindow = self.convert(self.bounds, to: windowView)

        // Define popup dimensions
        let popupWidth: CGFloat = self.bounds.width * 1.6 // initial 1.3
        let popupHeight: CGFloat = self.bounds.height * 1.65

        // Calculate initial popupX to center above the key
        let popupX = keyFrameInWindow.midX - popupWidth / 2
        let popupY = keyFrameInWindow.origin.y - popupHeight + 10

        // Create the popup view
        popupView = UIView(frame: CGRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight))
        popupView?.backgroundColor = .popupBackground
        popupView?.layer.borderWidth = 0
        popupView?.layer.borderColor = UIColor.lightGray.cgColor
        popupView?.layer.shadowOpacity = 0.2
        popupView?.layer.shadowOffset = CGSize(width: 0, height: 0)
        popupView?.layer.shadowRadius = 4
        popupView?.alpha = 0 // Start transparent for animation
        popupView?.transform = CGAffineTransform(scaleX: 0.3, y: 0.3) // Start scaled down for animation

        // Create a custom path for rounded corners
        let cornerRadius: CGFloat = 10 // Slight rounding for top corners
        let path = UIBezierPath(
            roundedRect: popupView!.bounds,
            byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )

        // Apply the mask to the popup's layer
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        popupView?.layer.mask = maskLayer

        

        // Create and configure the label
        popupLabel = UILabel(frame: CGRect(x: 0, y: 0, width: popupWidth, height: popupHeight ))
        popupLabel?.textAlignment = .center
        popupLabel?.font = self.titleLabel?.font.withSize(36)
        popupLabel?.text = self.titleLabel?.text
        popupLabel?.textColor = .popupTextColor
        popupLabel?.adjustsFontSizeToFitWidth = true
        popupLabel?.minimumScaleFactor = 0.5

        popupView?.addSubview(popupLabel!)

        // Add the popup to the window
        windowView.addSubview(popupView!)

        // Animate the popup appearance
        UIView.animate(withDuration: 0.1, delay: 0, animations: {
            self.popupView?.alpha = 1
            self.popupView?.transform = CGAffineTransform.identity
        })
    }

    /// Hides the popup view with animation.
    @objc func hidePopup() {
        guard let popup = popupView else { return }

        // Show the key label again when the popup hides
        self.titleLabel?.alpha = 1

        UIView.animate(withDuration: 0.001, delay: 0, options: [.curveEaseIn], animations: {
            popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            popup.alpha = 0
        }, completion: { _ in
            popup.removeFromSuperview()
            self.popupView = nil
            self.popupLabel = nil
        })
    }
}
