/**
 * Copyright (c) 2021-present, Joshua Auerbach and Perry Cheng
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

// Code in this file donated by Perry Cheng

import UIKit

open class PopupViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    public init(_ size: CGSize, _ sourceView: UIView, _ sourceRect: CGRect, _ direction: UIPopoverArrowDirection) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = UIModalPresentationStyle.popover
        preferredContentSize = size
        let popoverPC = self.popoverPresentationController
        popoverPC?.sourceView = sourceView
        popoverPC?.sourceRect = sourceRect
        popoverPC?.permittedArrowDirections = direction
        popoverPC?.delegate = self
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This is neceesary for popover to work on the iPhone
    open func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
