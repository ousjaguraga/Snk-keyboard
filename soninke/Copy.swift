/*
 
import UIKit
import AudioToolbox

// MARK: - KeyButton Class

/// Custom UIButton subclass to represent keys on the keyboard.
/// Handles the display of popup views when keys are pressed.
class KeyButton: UIButton {
    var popupView: UIView?
    var popupLabel: UILabel?
    
    /// Enables the popup display when the key is pressed.
    func enablePopup() {
        self.addTarget(self, action: #selector(showPopup), for: .touchDown)
        self.addTarget(self, action: #selector(hidePopup), for: [.touchUpInside, .touchDragExit, .touchCancel, .touchUpOutside])
    }
    
    /// Displays the popup view above the key with customized bottom border radius.
    @objc func showPopup() {
        guard popupView == nil, let windowView = self.window else { return }
        
        // Get the frame of the key button relative to the window
        let keyFrameInWindow = self.convert(self.bounds, to: windowView)
        
        // Define popup dimensions
        let popupWidth: CGFloat = self.bounds.width * 1.3
        let popupHeight: CGFloat = self.bounds.height * 1.5
        
        // Calculate initial popupX to center above the key
        var popupX = keyFrameInWindow.midX - popupWidth / 2
        let popupY = keyFrameInWindow.origin.y - popupHeight + 10
        
        // Adjust popupX to stay within window bounds with padding
        let padding: CGFloat = 25
        if popupX < padding {
            popupX = padding
        } else if popupX + popupWidth > windowView.bounds.width - padding {
            popupX = windowView.bounds.width - popupWidth - padding
        }
        
        // Calculate the position of the key center relative to the popup
        let keyCenterXInPopup = keyFrameInWindow.midX - popupX
        
        // Create the popup view
        popupView = UIView(frame: CGRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight))
        popupView?.backgroundColor = UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // #636366
        // Remove the uniform corner radius
        // popupView?.layer.cornerRadius = 8
        popupView?.layer.borderWidth = 0
        popupView?.layer.borderColor = UIColor.lightGray.cgColor
        //popupView?.layer.shadowColor = UIColor.black.cgColor
        popupView?.layer.shadowOpacity = 0.2
        popupView?.layer.shadowOffset = CGSize(width: 0, height: 0)
        popupView?.layer.shadowRadius = 4
        popupView?.alpha = 0 // Start transparent for animation
        popupView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Start scaled down for animation
        
        // Create a custom path for rounded top corners and sharp bottom corners
        let cornerRadius: CGFloat = 40
        let path = UIBezierPath(
            roundedRect: popupView!.bounds,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        // Apply the mask to the popup's layer
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        popupView?.layer.mask = maskLayer
        
        // Create the triangle (arrow) using CAShapeLayer
        let triangleHeight: CGFloat = 10
        let triangleWidth: CGFloat = 20
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: keyCenterXInPopup - triangleWidth / 2, y: popupHeight - triangleHeight))
        trianglePath.addLine(to: CGPoint(x: keyCenterXInPopup, y: popupHeight))
        trianglePath.addLine(to: CGPoint(x: keyCenterXInPopup + triangleWidth / 2, y: popupHeight - triangleHeight))
        trianglePath.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = trianglePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = UIColor.lightGray.cgColor
        shapeLayer.lineWidth = 1
        popupView?.layer.addSublayer(shapeLayer)
        
        // Create and configure the label
        popupLabel = UILabel(frame: CGRect(x: 0, y: 0, width: popupWidth, height: popupHeight - triangleHeight))
        popupLabel?.textAlignment = .center
        popupLabel?.font = self.titleLabel?.font.withSize(36)
        popupLabel?.text = self.titleLabel?.text
        popupLabel?.textColor = self.titleColor(for: .normal)
        popupLabel?.adjustsFontSizeToFitWidth = true
        popupLabel?.minimumScaleFactor = 0.5
        
        popupView?.addSubview(popupLabel!)
        
        // Add the popup to the window
        windowView.addSubview(popupView!)
        
        // Animate the popup appearance
        UIView.animate(withDuration: 0.2, animations: {
            self.popupView?.alpha = 1
            self.popupView?.transform = CGAffineTransform.identity
        })
        
        // Add a tap gesture recognizer to dismiss the popup when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        tapGesture.cancelsTouchesInView = false
        windowView.addGestureRecognizer(tapGesture)
    }
    
    /// Dismisses the popup view with animation.
    @objc func dismissPopup() {
        guard let popup = popupView else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            popup.alpha = 0
            popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            popup.removeFromSuperview()
            self.popupView = nil
            
            // Remove the tap gesture recognizer to prevent multiple recognizers
            if let windowView = self.window {
                windowView.gestureRecognizers?.forEach { gesture in
                    if gesture is UITapGestureRecognizer {
                        windowView.removeGestureRecognizer(gesture)
                    }
                }
            }
        })
    }
    
    /// Hides the popup view when the key is released.
    @objc func hidePopup() {
        popupView?.removeFromSuperview()
        popupView = nil
        popupLabel = nil
    }
}

// MARK: - KeyboardViewController Class

/// Custom keyboard view controller handling the layout and behavior of the keyboard.
class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    var keyboardView: UIView!
    var keyButtons: [KeyButton] = []
    
    /// Shift state: .off = lowercase, .on = shift enabled, .capsLock = caps lock enabled
    var shiftState: ShiftState = .off
    
    /// Keyboard state: .letters, .numbers, .symbols
    var keyboardState: KeyboardState = .letters
    
    // Auto-completion properties
    var suggestionBar: UIView!
    var suggestions: [String] = []
    var suggestionButtons: [UIButton] = []
    var selectedSuggestion: String?
    var wordList: [String] = []
    
    /// Enum to represent the shift state
    enum ShiftState {
        case off
        case on
        case capsLock
    }
    
    /// Enum to represent the keyboard state
    enum KeyboardState {
        case letters
        case numbers
        case symbols
    }
    
    // Shifted symbols mapping
    let numberShiftMappings: [String: String] = [
        "1": "!", "2": "@", "3": "#", "4": "$", "5": "%",
        "6": "^", "7": "&", "8": "*", "9": "(", "0": ")",
        "-": "_", "=": "+", "[": "{", "]": "}", ";": ":",
        "'": "\"", "\\": "|", ",": "<", ".": ">", "/": "?"
    ]
    
    // Property to hold the pan gesture recognizer for spacebar cursor control
    var spacebarPanGesture: UIPanGestureRecognizer?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWordList()
        setupKeyboard()
    }
    
    // MARK: - Word List Loading
    
    /// Loads the word list from a text file for suggestions.
    func loadWordList() {
        if let path = Bundle.main.path(forResource: "SoninkeWords", ofType: "txt") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                wordList = content.components(separatedBy: .newlines)
            } catch {
                print("Error loading word list: \(error)")
            }
        } else {
            print("Word list file not found")
        }
    }
    
    // MARK: - Keyboard Setup
    
    /// Sets up the keyboard layout and keys.
    func setupKeyboard() {
        // Remove existing subviews if any
        if keyboardView != nil {
            keyboardView.subviews.forEach { $0.removeFromSuperview() }
            keyboardView.removeFromSuperview()
        }
        keyButtons.removeAll()
        
        // Initialize the keyboard view
        keyboardView = UIView(frame: view.frame)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)
        
        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor),
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        keyboardView.clipsToBounds = false
        view.clipsToBounds = false
        
        // Add the suggestion bar
        addSuggestionBar()
        
        // Choose the appropriate keys based on keyboard state
        let keys: [[String]]
        switch keyboardState {
        case .letters:
            keys = letterKeys
        case .numbers:
            keys = numberKeys
        case .symbols:
            keys = symbolKeys
        }
        
        addKeys(for: keys)
        updateShiftState()
        updateKeyColors(isDarkMode: (textDocumentProxy.keyboardAppearance == .dark))
        updateReturnKey()
    }
    
    // MARK: - Suggestion Bar
    
    /// Adds the suggestion bar at the top of the keyboard.
    func addSuggestionBar() {
        suggestionBar = UIView()
        suggestionBar.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.addSubview(suggestionBar)
        
        NSLayoutConstraint.activate([
            suggestionBar.leftAnchor.constraint(equalTo: keyboardView.leftAnchor),
            suggestionBar.rightAnchor.constraint(equalTo: keyboardView.rightAnchor),
            suggestionBar.topAnchor.constraint(equalTo: keyboardView.topAnchor),
            suggestionBar.heightAnchor.constraint(equalToConstant: 50)
        ])
        
       
    }
        
    /// Handles the selection of a suggestion.
    @objc func suggestionTapped(_ sender: UIButton) {
        guard let suggestion = sender.title(for: .normal) else { return }
        let proxy = textDocumentProxy
        
        // Replace the current word with the selected suggestion
        if let currentWord = proxy.documentContextBeforeInput?.components(separatedBy: .whitespacesAndNewlines).last {
            for _ in 0..<currentWord.count {
                proxy.deleteBackward()
            }
        }
        proxy.insertText(suggestion + " ")
    }
    
    // MARK: - Key Layout
    
    /// Adds keys to the keyboard based on the provided key layout.
    func addKeys(for keys: [[String]]) {
        var previousRow: UIView? = nil
        let keyHeight: CGFloat = 44
        let keySpacing: CGFloat = 6
        let rowVerticalPadding: CGFloat = 8
        
        // Define side paddings for each row to match iOS keyboard
        let rowSidePaddings: [CGFloat] = [3, 26, 3, 3]
        let rowVerticalPaddings: [CGFloat] = [8, 8, 12, 8]
        
        for (rowIndex, rowKeys) in keys.enumerated() {
            let rowView = UIView()
            rowView.translatesAutoresizingMaskIntoConstraints = false
            keyboardView.addSubview(rowView)
            
            let sidePadding = rowSidePaddings[rowIndex]
            let verticalPadding = rowVerticalPaddings[rowIndex]
            
            NSLayoutConstraint.activate([
                rowView.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: sidePadding),
                rowView.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -sidePadding),
                rowView.heightAnchor.constraint(equalToConstant: keyHeight)
            ])
            
            if let prevRow = previousRow {
                rowView.topAnchor.constraint(equalTo: prevRow.bottomAnchor, constant: verticalPadding).isActive = true
            } else {
                // Adjust for suggestion bar height
                rowView.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor, constant: verticalPadding).isActive = true
            }
            
            // Determine if this row contains the Shift key
            if rowKeys.contains("Shift") {
                // Assuming Shift is only in the third row (index 2)
                addShiftRowKeys(rowKeys, to: rowView, keySpacing: keySpacing)
            } else if rowIndex == keys.count - 1 {
                // Last row, handle keys individually
                addLastRowKeys(rowKeys, to: rowView, keySpacing: keySpacing)
            } else {
                // Other rows
                addStandardRowKeys(rowKeys, to: rowView, keySpacing: keySpacing)
            }
            
            previousRow = rowView
        }
        
        // Adjust bottom constraint for the last row
        previousRow?.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -rowVerticalPadding).isActive = true
    }
    
    /// Adds keys to standard rows (excluding the last and shift rows).
    func addStandardRowKeys(_ rowKeys: [String], to rowView: UIView, keySpacing: CGFloat) {
        var keyButtonsInRow: [KeyButton] = []
        
        // Create key buttons and add them to the row
        for key in rowKeys {
            let keyButton = createKeyButton(title: key)
            rowView.addSubview(keyButton)
            keyButton.translatesAutoresizingMaskIntoConstraints = false
            
            keyButton.topAnchor.constraint(equalTo: rowView.topAnchor).isActive = true
            keyButton.bottomAnchor.constraint(equalTo: rowView.bottomAnchor).isActive = true
            
            keyButtonsInRow.append(keyButton)
            keyButtons.append(keyButton)
        }
        
        // Set constraints between keys
        for (index, keyButton) in keyButtonsInRow.enumerated() {
            if index == 0 {
                keyButton.leftAnchor.constraint(equalTo: rowView.leftAnchor).isActive = true
            } else {
                let previousKey = keyButtonsInRow[index - 1]
                keyButton.leftAnchor.constraint(equalTo: previousKey.rightAnchor, constant: keySpacing).isActive = true
                // Equal width
                keyButton.widthAnchor.constraint(equalTo: previousKey.widthAnchor).isActive = true
            }
        }
        
        // Right anchor of last key
        if let lastKey = keyButtonsInRow.last {
            lastKey.rightAnchor.constraint(equalTo: rowView.rightAnchor).isActive = true
        }
    }
    
    /// Adds keys to the shift row (third row), handling shift and delete keys with additional margin.
    func addShiftRowKeys(_ rowKeys: [String], to rowView: UIView, keySpacing: CGFloat) {
        guard rowKeys.count >= 2 else { return } // Ensure there are enough keys
        
        // Extract the titles for the special keys and middle keys
        let shiftKeyTitle = rowKeys.first!
        let deleteKeyTitle = rowKeys.last!
        let middleKeyTitles = Array(rowKeys[1..<(rowKeys.count - 1)])
        
        // Create the Shift key button
        let shiftKeyButton = createKeyButton(title: shiftKeyTitle)
        rowView.addSubview(shiftKeyButton)
        shiftKeyButton.translatesAutoresizingMaskIntoConstraints = false
        
        shiftKeyButton.topAnchor.constraint(equalTo: rowView.topAnchor).isActive = true
        shiftKeyButton.bottomAnchor.constraint(equalTo: rowView.bottomAnchor).isActive = true
        keyButtons.append(shiftKeyButton)
        
        // Create the Delete key button
        let deleteKeyButton = createKeyButton(title: deleteKeyTitle)
        rowView.addSubview(deleteKeyButton)
        deleteKeyButton.translatesAutoresizingMaskIntoConstraints = false
        
        deleteKeyButton.topAnchor.constraint(equalTo: rowView.topAnchor).isActive = true
        deleteKeyButton.bottomAnchor.constraint(equalTo: rowView.bottomAnchor).isActive = true
        keyButtons.append(deleteKeyButton)
        
        // Create the middle key buttons
        var middleKeyButtons: [KeyButton] = []
        for keyTitle in middleKeyTitles {
            let keyButton = createKeyButton(title: keyTitle)
            rowView.addSubview(keyButton)
            keyButton.translatesAutoresizingMaskIntoConstraints = false
            
            keyButton.topAnchor.constraint(equalTo: rowView.topAnchor).isActive = true
            keyButton.bottomAnchor.constraint(equalTo: rowView.bottomAnchor).isActive = true
            
            middleKeyButtons.append(keyButton)
            keyButtons.append(keyButton)
        }
        
        guard let referenceKey = middleKeyButtons.first else { return }
        
        // Constraints for the Shift key
        shiftKeyButton.leftAnchor.constraint(equalTo: rowView.leftAnchor).isActive = true
        // Make Shift key wider
        shiftKeyButton.widthAnchor.constraint(equalTo: referenceKey.widthAnchor, multiplier: 1.2).isActive = true
        
        // Space between Shift key and middle keys
        if let firstMiddleKey = middleKeyButtons.first {
            firstMiddleKey.leftAnchor.constraint(equalTo: shiftKeyButton.rightAnchor, constant: keySpacing * 3.5).isActive = true
        }
        
        // Constraints for middle keys
        for (index, keyButton) in middleKeyButtons.enumerated() {
            if index == 0 {
                // Left anchor already set
            } else {
                let previousKey = middleKeyButtons[index - 1]
                keyButton.leftAnchor.constraint(equalTo: previousKey.rightAnchor, constant: keySpacing).isActive = true
                keyButton.widthAnchor.constraint(equalTo: previousKey.widthAnchor).isActive = true
            }
        }
        
        // Space between last middle key and Delete key
        if let lastMiddleKey = middleKeyButtons.last {
            deleteKeyButton.leftAnchor.constraint(equalTo: lastMiddleKey.rightAnchor, constant: keySpacing * 3.5).isActive = true
        }
        
        // Constraints for Delete key
        deleteKeyButton.widthAnchor.constraint(equalTo: shiftKeyButton.widthAnchor).isActive = true
        deleteKeyButton.rightAnchor.constraint(equalTo: rowView.rightAnchor).isActive = true
    }
    
    /// Adds keys to the last row, handling special keys like "Space" and "Return".
    func addLastRowKeys(_ rowKeys: [String], to rowView: UIView, keySpacing: CGFloat) {
        var keyButtonsDict: [String: KeyButton] = [:]
        for key in rowKeys {
            let keyButton = createKeyButton(title: key)
            rowView.addSubview(keyButton)
            keyButton.translatesAutoresizingMaskIntoConstraints = false
            keyButton.topAnchor.constraint(equalTo: rowView.topAnchor).isActive = true
            keyButton.bottomAnchor.constraint(equalTo: rowView.bottomAnchor).isActive = true
            
            keyButtonsDict[key] = keyButton
            keyButtons.append(keyButton)
        }
        
        if let firstKey = keyButtonsDict[rowKeys.first ?? ""], let lastKey = keyButtonsDict[rowKeys.last ?? ""] {
            firstKey.leftAnchor.constraint(equalTo: rowView.leftAnchor).isActive = true
            firstKey.widthAnchor.constraint(equalToConstant: 60).isActive = true
            
            lastKey.rightAnchor.constraint(equalTo: rowView.rightAnchor).isActive = true
            lastKey.widthAnchor.constraint(equalToConstant: 60).isActive = true
            
            if let spaceKey = keyButtonsDict["Space"] {
                spaceKey.leftAnchor.constraint(equalTo: firstKey.rightAnchor, constant: keySpacing).isActive = true
                spaceKey.rightAnchor.constraint(equalTo: lastKey.leftAnchor, constant: -keySpacing).isActive = true
                spaceKey.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
                
                // Add Gesture Recognizer for Cursor Control
                addSpacebarPanGesture(to: spaceKey)
            }
        }
    }
    
    // MARK: - Key Creation
    
    /// Creates a KeyButton with the given title and sets up its appearance and actions.
    func createKeyButton(title: String) -> KeyButton {
        let button = KeyButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        switch title {
        case "Globe":
            let globeImage = UIImage(systemName: "globe")
            button.setImage(globeImage, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityLabel = "Globe"
        
        case "Shift":
            // Update shift key image based on shift state
            let shiftImageName: String
            switch shiftState {
            case .off:
                shiftImageName = keyboardState == .letters ? "shift" : "123"
            case .on:
                shiftImageName = keyboardState == .letters ? "shift.fill" : "123"
            case .capsLock:
                shiftImageName = "capslock.fill"
            }
            let shiftImage = UIImage(systemName: shiftImageName)
            button.setImage(shiftImage, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityLabel = "Shift"
            // Highlight shift key when active
            if shiftState == .on || shiftState == .capsLock {
                button.backgroundColor = UIColor(red: 0.725, green: 0.753, blue: 0.780, alpha: 1.0) // Lighter gray
            } else {
                button.backgroundColor = UIColor(red: 0.667, green: 0.694, blue: 0.722, alpha: 1.0) // Default gray
            }
        case "Dictation":
            let micImage = UIImage(systemName: "mic.fill")
            button.setImage(micImage, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityLabel = "Dictation"
        case "Space":
            button.setTitle("Space", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = UIColor.white
            button.layer.cornerRadius = 5
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 1
            button.accessibilityLabel = "Space"
        case "Return":
            let title = returnKeyTitle()
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.systemBlue
            button.layer.cornerRadius = 5
            button.accessibilityLabel = "Return"
        case "123", "ABC":
            let displayTitle = keyboardState == .letters ? "123" : "ABC"
            button.setTitle(displayTitle, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = UIColor(red: 0.667, green: 0.694, blue: 0.722, alpha: 1.0)
            button.accessibilityLabel = "ABC"
        default:
            let displayTitle: String
            if keyboardState == .letters {
                displayTitle = shiftState == .off ? title.lowercased() : title.uppercased()
            } else if keyboardState == .numbers || keyboardState == .symbols {
                if shiftState != .off, let shiftedTitle = numberShiftMappings[title] {
                    displayTitle = shiftedTitle
                } else {
                    displayTitle = title
                }
            } else {
                displayTitle = title
            }
            button.setTitle(displayTitle, for: .normal)
            button.accessibilityLabel = title // Store the original title
            button.titleLabel?.font = UIFont.systemFont(ofSize: 26)
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = UIColor.white
            button.layer.cornerRadius = 5
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 1
        }
        
        // Add target action
        if title == "Globe" {
            button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        } else {
            button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        }
        
        // Special keys styling
        if ["Shift", "Delete", "⌫", "Globe", "Return", "123", "ABC", "Dictation"].contains(title) {
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = UIColor(red: 0.667, green: 0.694, blue: 0.722, alpha: 1.0) // Gray color
            button.layer.cornerRadius = 5
        }
        
        // Enable pop-up overlay
        if !["Shift", "Delete", "⌫", "Globe", "Return", "Space", "123", "ABC"].contains(title) {
            button.enablePopup()
        }
        
        return button
    }
    
    // MARK: - Key Actions
    /// Updates the suggestions based on the current input.
    func updateSuggestions() {
        // Remove previous suggestion buttons and separators
        suggestionButtons.forEach { $0.removeFromSuperview() }
        suggestionButtons.removeAll()
        suggestionBar.subviews.forEach { if $0.tag == 999 { $0.removeFromSuperview() } } // Remove separators

        selectedSuggestion = nil // Reset selected suggestion

        // Get the current word
        let proxy = textDocumentProxy
        var currentWord = proxy.documentContextBeforeInput ?? ""
        currentWord = currentWord.components(separatedBy: .whitespacesAndNewlines).last ?? ""

        guard !currentWord.isEmpty else { return } // No need to suggest if current word is empty

        // Find suggestions
        let matches = wordList.filter { $0.hasPrefix(currentWord.lowercased()) }
        let topSuggestions = Array(matches.prefix(3)) // Show top 3 suggestions

        // Find the closest match using Levenshtein distance
        var closestSuggestion: String?
        var minimumDistance = Int.max
        let distanceThreshold = 0

        for suggestion in topSuggestions {
            let distance = levenshteinDistance(suggestion.lowercased(), currentWord.lowercased())
            if distance < minimumDistance {
                minimumDistance = distance
                closestSuggestion = suggestion
            }
        }

        // If the minimum distance is within the threshold, set selectedSuggestion
        if minimumDistance <= distanceThreshold {
            selectedSuggestion = closestSuggestion
        } else {
            selectedSuggestion = nil // No close match found
        }

        // Create buttons for suggestions
        var previousView: UIView? = nil
        for (index, suggestion) in topSuggestions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            button.setTitleColor(.white, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

            // Highlight if it's an exact match
            if suggestion == selectedSuggestion {
                button.backgroundColor =  UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // #636366
            }

            suggestionBar.addSubview(button)
            suggestionButtons.append(button)

            // Constraints for equal width and positioning
            button.topAnchor.constraint(equalTo: suggestionBar.topAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: suggestionBar.bottomAnchor).isActive = true

            if let prev = previousView {
                // Set leading constraint to previous separator
                button.leftAnchor.constraint(equalTo: prev.rightAnchor).isActive = true
                // Equal width with the first button
                button.widthAnchor.constraint(equalTo: suggestionButtons[0].widthAnchor).isActive = true
            } else {
                // First button aligns to the left of suggestionBar
                button.leftAnchor.constraint(equalTo: suggestionBar.leftAnchor).isActive = true
            }

            previousView = button

            // Add vertical separator if not the last button
            if index < topSuggestions.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.tag = 999 // Tag for later removal
                suggestionBar.addSubview(separator)

                // Constraints for separator
                separator.topAnchor.constraint(equalTo: suggestionBar.topAnchor, constant: 8).isActive = true
                separator.bottomAnchor.constraint(equalTo: suggestionBar.bottomAnchor, constant: -8).isActive = true
                separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
                separator.leftAnchor.constraint(equalTo: button.rightAnchor).isActive = true

                previousView = separator
            }
        }

        // Last button or separator aligns to the right of suggestionBar
        previousView?.rightAnchor.constraint(equalTo: suggestionBar.rightAnchor).isActive = true
    }
    
    
  
    /// Calculates the Levenshtein distance between two strings.
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Count = s1.count
        let s2Count = s2.count

        var dist = [[Int]](repeating: [Int](repeating: 0, count: s2Count + 1), count: s1Count + 1)

        for i in 0...s1Count {
            dist[i][0] = i
        }
        for j in 0...s2Count {
            dist[0][j] = j
        }

        for i in 1...s1Count {
            for j in 1...s2Count {
                if s1[s1.index(s1.startIndex, offsetBy: i - 1)] == s2[s2.index(s2.startIndex, offsetBy: j - 1)] {
                    dist[i][j] = dist[i - 1][j - 1] // No operation needed
                } else {
                    dist[i][j] = min(
                        dist[i - 1][j] + 1,    // Deletion
                        dist[i][j - 1] + 1,    // Insertion
                        dist[i - 1][j - 1] + 1 // Substitution
                    )
                }
            }
        }
        return dist[s1Count][s2Count]
    }

    
    /// Handles the key press actions for the keyboard.
    @objc func keyPressed(_ sender: UIButton) {
        let proxy = textDocumentProxy as UITextDocumentProxy

        AudioServicesPlaySystemSound(1104)

        var key: String? = sender.title(for: .normal)

        // If title is nil, try to get it from accessibilityLabel (for special keys)
        if key == nil {
            key = sender.accessibilityLabel
        }

        guard let keyPressed = key else { return }

        switch keyPressed {
        case "Shift":
            handleShiftKey()
        case "⌫", "Delete":
            proxy.deleteBackward()
        case "Space", "Bira", "Bera":
            if let suggestion = selectedSuggestion {
                // Replace the current word with the selected suggestion
                if let context = proxy.documentContextBeforeInput {
                    let words = context.components(separatedBy: .whitespacesAndNewlines)
                    if let currentWord = words.last {
                        for _ in 0..<currentWord.count {
                            proxy.deleteBackward()
                        }
                    }
                }
                proxy.insertText(suggestion + " ")
            } else {
                proxy.insertText(" ")
            }
        //case "return", "Return", "Go", "Search", "Join", "Next", "Route", "Send", "Done", "Call", "Continue":
            //proxy.insertText("\n")
        case "saage", "Saage", "daga", "muuru", "Join", "dangi", "Route", "xeyi", "duguta", "xiri":
            proxy.insertText("\n")
        case "123", "ABC":
            handleKeyboardToggle()
        default:
            let character: String
            if keyboardState == .letters {
                character = shiftState == .off ? keyPressed.lowercased() : keyPressed.uppercased()
            } else if keyboardState == .numbers || keyboardState == .symbols {
                if shiftState != .off, let shiftedChar = numberShiftMappings[keyPressed] {
                    character = shiftedChar
                } else {
                    character = keyPressed
                }
            } else {
                character = keyPressed
            }
            proxy.insertText(character)
            if shiftState == .on && keyboardState == .letters {
                shiftState = .off
                updateShiftState()
            }
        }

        updateSuggestions()
    }
    
    // MARK: - Shift Key Handling
    
    /// Handles the shift key functionality including switching between number and symbol keyboards.
    func handleShiftKey() {
        switch keyboardState {
        case .letters:
            // In letters keyboard, shift cycles through shift states
            switch shiftState {
            case .off:
                shiftState = .on
            case .on:
                shiftState = .capsLock
            case .capsLock:
                shiftState = .off
            }
            updateShiftState()
        case .numbers:
            // In numbers keyboard, shift switches to symbols keyboard
            keyboardState = .symbols
            shiftState = .off
            setupKeyboard()
        case .symbols:
            // In symbols keyboard, shift switches back to numbers keyboard
            keyboardState = .numbers
            shiftState = .off
            setupKeyboard()
        }
    }
    
    /// Updates the shift state of the keyboard, changing key titles accordingly.
    func updateShiftState() {
        for button in keyButtons {
            if let key = button.accessibilityLabel {
                if key == "Shift" {
                    // Update shift key appearance
                    let shiftImageName: String
                    switch shiftState {
                    case .off:
                        shiftImageName = keyboardState == .letters ? "shift" : "123"
                    case .on:
                        shiftImageName = keyboardState == .letters ? "shift.fill" : "123"
                    case .capsLock:
                        shiftImageName = "capslock.fill"
                    }
                    let shiftImage = UIImage(systemName: shiftImageName)
                    button.setImage(shiftImage, for: .normal)
                    
                    // Highlight shift key when active
                    if shiftState == .on || shiftState == .capsLock {
                        button.backgroundColor = UIColor(red: 0.725, green: 0.753, blue: 0.780, alpha: 1.0) // Lighter gray
                    } else {
                        button.backgroundColor = UIColor(red: 0.667, green: 0.694, blue: 0.722, alpha: 1.0) // Default gray
                    }
                } else if keyboardState == .letters && key.count == 1 {
                    // Update letter keys
                    let updatedKey = shiftState == .off ? key.lowercased() : key.uppercased()
                    button.setTitle(updatedKey, for: .normal)
                } else if keyboardState == .numbers || keyboardState == .symbols {
                    if shiftState != .off, let shiftedTitle = numberShiftMappings[key] {
                        button.setTitle(shiftedTitle, for: .normal)
                    } else {
                        button.setTitle(key, for: .normal)
                    }
                }
            }
        }
    }
    
    // MARK: - Keyboard Toggle Handling
    
    /// Handles toggling between letter and number keyboards.
    func handleKeyboardToggle() {
        switch keyboardState {
        case .letters:
            keyboardState = .numbers
            shiftState = .off
        default:
            keyboardState = .letters
            shiftState = .off
        }
        setupKeyboard()
    }
    
    // MARK: - Text Changes
    
    /// Handles text changes in the input field.
    override func textDidChange(_ textInput: UITextInput?) {
        let proxy = self.textDocumentProxy
        let keyboardAppearance = proxy.keyboardAppearance ?? .default
        
        let isDarkMode = (keyboardAppearance == .dark)
        updateKeyColors(isDarkMode: isDarkMode)
        
        updateSuggestions()
        updateReturnKey()
    }
    
    /// Updates the key colors to match the iOS keyboard on iPhone.
    func updateKeyColors(isDarkMode: Bool) {
        // Define color constants to match iOS keyboard colors
        let lightModeKeyboardBackground = UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1.0) // #D1D1D6
        let lightModeLetterKeyBackground = UIColor.white
        let lightModeLetterKeyBorderColor = UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1.0) // #D1D1D6
        let lightModeFunctionKeyBackground = UIColor(red: 172/255, green: 177/255, blue: 183/255, alpha: 1.0) // #ACB1B7

        let darkModeKeyboardBackground =     UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0) // #2C2C2E
        let darkModeLetterKeyBackground =    UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // #636366
        let darkModeFunctionKeyBackground =  UIColor(red: 72/255, green: 72/255, blue: 74/255, alpha: 1.0) // #48484A

        // Set the background color of the keyboard's main view to avoid transparency issues
        self.view.backgroundColor = isDarkMode ? darkModeKeyboardBackground : lightModeKeyboardBackground

        for button in keyButtons {
            if isDarkMode {
                if ["Shift", "Delete", "⌫", "Globe", "Return", "123", "ABC", "Dictation"].contains(button.accessibilityLabel ?? "") {
                    // Function keys in dark mode
                    button.backgroundColor = darkModeFunctionKeyBackground
                    button.setTitleColor(.white, for: .normal)
                } else {
                    // Letter keys in dark mode
                    button.backgroundColor = darkModeLetterKeyBackground
                    button.setTitleColor(.white, for: .normal)
                    button.layer.borderColor = UIColor.clear.cgColor
                }
                button.popupView?.backgroundColor = button.backgroundColor
                button.popupLabel?.textColor = .white
            } else {
                if ["Shift", "Delete", "⌫", "Globe", "Return", "123", "ABC", "Dictation"].contains(button.accessibilityLabel ?? "") {
                    // Function keys in light mode
                    button.backgroundColor = lightModeFunctionKeyBackground
                    button.setTitleColor(.black, for: .normal)
                } else {
                    // Letter keys in light mode
                    button.backgroundColor = lightModeLetterKeyBackground
                    button.setTitleColor(.black, for: .normal)
                    button.layer.borderColor = lightModeLetterKeyBorderColor.cgColor
                }
                button.popupView?.backgroundColor = button.backgroundColor
                button.popupLabel?.textColor = .black
            }
        }
        
        // Update suggestion bar colors to match the iOS keyboard
        let lightModeSuggestionBarBackground = lightModeKeyboardBackground
        let darkModeSuggestionBarBackground = darkModeKeyboardBackground

        suggestionBar.backgroundColor = isDarkMode ? darkModeSuggestionBarBackground : lightModeSuggestionBarBackground
        suggestionButtons.forEach { button in
            button.backgroundColor = isDarkMode ? darkModeLetterKeyBackground : lightModeLetterKeyBackground
            button.setTitleColor(isDarkMode ? .white : .black, for: .normal)
        }
    }
    



    // MARK: - Return Key Title
    
    /// Returns the appropriate title for the return key based on the returnKeyType.
    func returnKeyTitle() -> String {
        let returnKeyType = textDocumentProxy.returnKeyType ?? .default
        switch returnKeyType {
        case .go:
            return "daga"
        case .google, .yahoo:
            return "muuru"
        case .search:
            return "muuru"
        case .join:
            return "join"
        case .next:
            return "Kaane"
        case .route:
            return "route"
        case .send:
            return "xeyi"
        case .done:
            return "duguta"
        case .emergencyCall:
            return "A Xiri"
        case .continue:
            return "dangi"
        default:
            return "saage"
        }
    }
    
    /// Updates the title of the return key based on the current returnKeyType.
    func updateReturnKey() {
        for button in keyButtons {
            if button.accessibilityLabel == "Return" {
                let title = returnKeyTitle()
                button.setTitle(title, for: .normal)
            }
        }
    }
    
    // MARK: - Gesture Handlers
    
    /// Adds a pan gesture recognizer to the spacebar for cursor control.
    func addSpacebarPanGesture(to button: UIButton) {
        spacebarPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSpacebarPan(_:)))
        spacebarPanGesture?.maximumNumberOfTouches = 1
        button.addGestureRecognizer(spacebarPanGesture!)
        button.isUserInteractionEnabled = true
    }
    
    /// Handles the pan gesture on the space bar to move the cursor.
    @objc func handleSpacebarPan(_ gesture: UIPanGestureRecognizer) {
        let proxy = textDocumentProxy
        let translation = gesture.translation(in: self.view)
        gesture.setTranslation(.zero, in: self.view)
        
        switch gesture.state {
        case .began, .changed:
            let cursorMovement = Int(translation.x / 10) // Adjust sensitivity as needed
            if cursorMovement != 0 {
                for _ in 0..<abs(cursorMovement) {
                    if cursorMovement > 0 {
                        proxy.adjustTextPosition(byCharacterOffset: 1)
                    } else {
                        proxy.adjustTextPosition(byCharacterOffset: -1)
                    }
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Key Layout Definitions
    
    /// Defines the layout for letter keys.
    let letterKeys: [[String]] = [
        // Row 1
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        // Row 2 with side margins
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        // Row 3 with Shift and Delete keys
        ["Shift", "ñ", "ŋ", "x", "c", "b", "n", "m", "⌫"],
        // Row 4
        ["123", "Space", "Return"]
    ]
    
    /// Defines the layout for number keys.
    let numberKeys: [[String]] = [
        // Row 1
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        // Row 2 with side margins
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        // Row 3 with Shift and Delete keys
        ["Shift", ".", ",", "?", "!", "'", "#", "%", "⌫"],
        // Row 4
        ["ABC", "Space", "Return"]
    ]
    
    /// Defines the layout for symbol keys.
    let symbolKeys: [[String]] = [
        // Row 1
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        // Row 2 with side margins
        ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", ""],
        // Row 3 with Shift and Delete keys
        ["Shift", ".", ",", "?", "!", "'", "-", "/", "⌫"],
        // Row 4
        ["ABC", "Space", "Return"]
    ]
}

*/
