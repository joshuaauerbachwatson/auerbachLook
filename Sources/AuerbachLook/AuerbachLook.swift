/**
 * Copyright (c) 2021-present, Joshua Auerbach
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit

// Constants and functions to help get a uniform appearance across various apps

fileprivate let OkButtonTitle = "Ok"
fileprivate let CancelButtonTitle = "Cancel"
fileprivate let ConfirmButtonTitle = "Confirm"

//
// Layout constants
//

/* The minimal border (in points) between things on the screen; even at the edges if you need the space */
public let border = CGFloat(3)

/* The pixel width of the shorter dimension of a tablet (used only to calibrate font sizes) */
public let tabletShortDimension = CGFloat(768)

/* The font size used for text on a tablet */
public let baseHelpFontSize = CGFloat(30)

/* The fixed height of a typical label */
public let fixedLabelHeight = CGFloat(25)

//
// Color constants
//

/* The background color to use for textual buttons */
public let ButtonBackground = UIColor.black

/* The normal text color to use except when you are using something else */
public let NormalTextColor = UIColor.black

/* The normal text color for TouchableLabels */
public let TouchableTextColor = UIColor.blue

/* The background color for touchable labels */
public let TouchableBackground = UIColor(white: 0.8, alpha: 1)

//
// Text constants
//

/* Title for the dismiss button of the "bummer" dialog */
let BummerButtonTitle = "Bummer"

/* Sound file names and extensions */
public let GameOverSound = "applause"
public let GameOverSoundExt = "wav"
public let ClickSound = "click"
public let ClickSoundExt = "wav"

//
// Functions (alphabetical)
//

// Display an error message modally, with a single "Bummer" button to dismiss the popup
// May have an optional handler to run when the user dismisses the dialog
public func bummer(title: String, message: String, host: UIViewController, handler: (()->Void)? = nil) {
    let action = UIAlertAction(title: BummerButtonTitle, style: .cancel) { _ in
        handler?()
    }
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(action)
    Logger.logPresent(alert, host: host, animated: true)
}

// Configure a button given a title and action and add it to a view
public func configureButton(_ button: UIButton, title: String, target: AnyObject, action: Selector, parent: UIView) {
    button.setTitle(title, for: .normal)
    button.titleLabel?.adjustsFontSizeToFitWidth = true
    button.titleLabel?.font = getTextFont()
    button.backgroundColor = ButtonBackground
    button.addTarget(target, action: action, for: .touchUpInside)
    button.layer.cornerRadius = 8
    parent.addSubview(button)
}

// Configure a label with a given a background color.  Text alignment is always centered and the initial text color
// 'normal'.  Sdds the label to a view
public func configureLabel(_ label: UILabel, _ color: UIColor, parent: UIView) {
    label.backgroundColor = color
    label.textColor = NormalTextColor
    label.font = getTextFont()
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    parent.addSubview(label)
}

// Configure a Text Field in a generally useful way, given a background color and a parent
public func configureTextField(_ ans: UITextField, _ color: UIColor, parent: UIView) {
    ans.font = getTextFont()
    ans.textAlignment = .center
    ans.backgroundColor = color
    ans.keyboardType = .alphabet
    ans.enablesReturnKeyAutomatically = true
    ans.autocorrectionType = .no
    parent.addSubview(ans)
}

// Configure a TouchableLabel given a background color and an action.  Add to a view
public func configureTouchableLabel(_ ans: TouchableLabel, target: AnyObject, action: Selector, tag: Int = 0, parent: UIView) {
    ans.view.backgroundColor = TouchableBackground
    ans.view.textColor = TouchableTextColor
    ans.view.textAlignment = .center
    ans.view.adjustsFontSizeToFitWidth = true
    ans.addTarget(target: target, action: action, tag: tag)
    parent.addSubview(ans)
}

// Configure a stepper
public func configureStepper(_ stepper: Stepper, delegate: StepperDelegate, value: Int, parent: UIView) {
    stepper.delegate = delegate
    stepper.value = value
    parent.addSubview(stepper)
}

// Compute a good anchor point and preferred size for popup dialogs with top arrows.  The anchor will be given in main
// view coordinates.
//   Inputs are:
//     The initiating subview.
//     The ideal preferred size.  The width must be able to fit on all screens and will not be reduced in the answer.  The
//        height may be reduced in the answer if necessary.
//     The bounds of the main view
//   The function attempts to place the anchor on the center of the bottom edge of the initiating view.  If that anchor 
//        would require the popup's height to be reduced, then the anchor is moved to (midX, minY) of the main view's bounds
//        and the returned height is either the requested height or the best height we can obtain.  Otherwise (height ok), if
//        any part of the X dimension of the popup would be off the screen or leave less than 'border' pixels at either edge,
//        the function moves the x of the anchor the minimal distance left or right to keep this from happening.
public func getDialogAnchorAndSize(_ initiator: UIView, _ size: CGSize, _ bounds: CGRect) -> (CGPoint, CGSize) {
    var y = initiator.frame.maxY
    var x : CGFloat
    if y + size.height > bounds.maxY {
        y = bounds.minY
        x = bounds.midX
    } else {
        let halfWidth = size.width / 2
        let maxX = bounds.maxX - border
        x = initiator.center.x
        if (x - halfWidth) < border {
            x = border + halfWidth
        } else if (x + halfWidth) > maxX {
            x = maxX - halfWidth
        }
    }
    let anchor = CGPoint(x: x, y: y)
    let maxHeight = bounds.maxY - y
    if (size.height <= maxHeight) {
        return (anchor, size)
    }
    return (anchor, CGSize(width: size.width, height: maxHeight))
}

// Get the appropriate font to use in a label, based on a base font size which is good for iPads.  Phones use a reduced font based on the
// ratio of their shortest dimension to the iPad's shortest dimension.
public func getTextFont() -> UIFont {
    let bounds = UIScreen.main.bounds
    let shortDimension = bounds.width < bounds.height ? bounds.width : bounds.height
    let fontRatio = min(shortDimension / tabletShortDimension, 1.0)
    return UIFont.systemFont(ofSize: baseHelpFontSize * fontRatio)
}

// Make a label configured in the standard way
public func makeLabel(_ color: UIColor, parent: UIView) -> UILabel {
    let label = UILabel()
    configureLabel(label, color, parent: parent)
    return label
}

// Make a text field configured in the standard way
public func makeTextField(_ color: UIColor, parent: UIView) -> UITextField {
    let ans = UITextField()
    configureTextField(ans, color, parent: parent)
    return ans
}

// Make a TouchableLabel configured in the standard way
public func makeTouchableLabel(target: AnyObject, action: Selector, parent: UIView, tag: Int = 0) -> TouchableLabel {
    let ans = TouchableLabel()
    configureTouchableLabel(ans, target: target, action: action, tag: tag, parent: parent)
    return ans
}

// Prompt for a string value using an alert controller
public func promptForName(_ vc: UIViewController, title: String, message: String, placeholder: String?,
                   handler: @escaping (String?)->Void) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancel = UIAlertAction(title: CancelButtonTitle, style: .cancel) { _ in
        // Do nothing
    }
    let useName = UIAlertAction(title: ConfirmButtonTitle, style: .default) { _ in
        handler(alert.textFields?.first?.text)
    }
    alert.addTextField() { field in
        field.placeholder = placeholder
    }
    alert.addAction(cancel)
    alert.addAction(useName)
    Logger.logPresent(alert, host: vc, animated: true)
}
