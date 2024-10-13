import UIKit

class KeyButton: UIButton {
    private var popupView: UIView?
    private var popupLabel: UILabel?
    var keyPressAction: (() -> Void)?

    func enablePopup() {
        removeTarget(nil, action: nil, for: .allEvents)
        let touchGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTouchGesture(_:)))
        touchGesture.minimumPressDuration = 0
        touchGesture.cancelsTouchesInView = true
        addGestureRecognizer(touchGesture)
    }

    @objc private func handleTouchGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            showPopup()
        case .ended, .cancelled:
            keyPressAction?()
            hidePopup()
        default:
            break
        }
    }

    @objc private func showPopup() {
        guard popupView == nil, let windowView = window else { return }

        titleLabel?.alpha = 0

        let keyFrameInWindow = convert(bounds, to: windowView)
        let popupWidth: CGFloat = bounds.width * 1.6
        let popupHeight: CGFloat = bounds.height * 1.65
        let popupX = keyFrameInWindow.midX - popupWidth / 2
        let popupY = keyFrameInWindow.origin.y - popupHeight + 10

        popupView = UIView(frame: CGRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight))
        popupView?.backgroundColor = .popupBackground
        popupView?.layer.cornerRadius = 10
        popupView?.layer.masksToBounds = true
        popupView?.layer.shadowOpacity = 0.2
        popupView?.layer.shadowOffset = .zero
        popupView?.layer.shadowRadius = 4
        popupView?.alpha = 0

        popupLabel = UILabel(frame: popupView!.bounds)
        popupLabel?.textAlignment = .center
        popupLabel?.font = titleLabel?.font.withSize(36)
        popupLabel?.text = titleLabel?.text
        popupLabel?.textColor = .popupTextColor
        popupLabel?.adjustsFontSizeToFitWidth = true
        popupLabel?.minimumScaleFactor = 0.5

        popupView?.addSubview(popupLabel!)
        windowView.addSubview(popupView!)

        UIView.animate(withDuration: 0.01, delay: 0, options: .curveEaseOut, animations: {
            self.popupView?.alpha = 1
        })
    }

    @objc private func hidePopup() {
        guard let popup = popupView else { return }

        titleLabel?.alpha = 1

        UIView.animate(withDuration: 0.01, delay: 0, options: .curveEaseIn, animations: {
            popup.alpha = 0
        }, completion: { _ in
            popup.removeFromSuperview()
            self.popupView = nil
            self.popupLabel = nil
        })
    }
}
