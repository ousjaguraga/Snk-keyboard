//
//  Extensions.swift
//  snk-keyboard
//
//  Created by Ovenger on 10/9/24.
//
import UIKit


extension UIColor {
    static let keyboardBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0) // Dark Mode
            : UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1.0) // Light Mode
    }

    static let letterKeyBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // Dark Mode
            : UIColor.white // Light Mode
    }

    static let functionKeyBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 72/255, green: 72/255, blue: 74/255, alpha: 1.0) // Dark Mode
            : UIColor(red: 172/255, green: 177/255, blue: 183/255, alpha: 1.0) // Light Mode
    }

    static let functionKeyTextColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.black
    }

    static let letterKeyTextColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.black
    }

    static let popupBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // Dark Mode
            : UIColor.white // Light Mode
    }

    static let popupTextColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.black
    }

    static let suggestionBarBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0) // Dark Mode
            : UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1.0) // Light Mode
    }

    static let suggestionButtonBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // Dark Mode
            : UIColor.white // Light Mode
    }

    static let suggestionButtonTextColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.black
    }

    static let separatorColor = UIColor.gray.withAlphaComponent(0.5)
}
