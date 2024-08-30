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

// A dead-simple chooser from among supplied colors which must be modest in number (3-15).   
// Nine colors is optimal giving a 3 x 3 layout.  Colors are laid out in rows of three.
public protocol ColorChooserDelegate {
    func colorChosen(_ colorIndex: Int, _ tag: Int)
    func initialColor(_ tag: Int) -> Int
}

public class ColorChooser : PopupViewController {
    // Constants
    private static let colorSquareSide = CGFloat(90)
    private static let markerSize = CGSize(width: 10, height: 10)
    private static let rowSize = 3
    private typealias C = ColorChooser

    // State
    let delegate : ColorChooserDelegate
    let colors : [UIColor]
    let background : UIColor
    let selectionMarker : UIView
    let tag : Int
    var views = [UIView]()

    public init(_ delegate: ColorChooserDelegate, _ colors: [UIColor], _ background: UIColor, _ anchor: CGPoint,
         _ direction: UIPopoverArrowDirection, _ sourceView: UIView, _ tag: Int) {
        self.delegate = delegate
        self.colors = colors
        self.background = background
        self.selectionMarker = UIView()
        self.tag = tag
        super.init(C.computePreferredSize(colors.count), sourceView, CGRect(origin: anchor, size: CGSize.zero), direction)
    }

    // Useless but required
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Create subviews in viewDIdLoad
    public override func viewDidLoad() {
        for i in 0..<colors.count {
            let box = TouchableView<UIView>(UIView(), target: self, action: #selector(colorTouched), tag: i)
            box.view.backgroundColor = colors[i]
            views.append(box)
            self.view.addSubview(box)
        }
        selectionMarker.backgroundColor = background
        self.view.addSubview(selectionMarker)
        self.view.backgroundColor = background
    }

    // Complete initialization, do layout
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let bounds = self.view.bounds
        let sideMargin = (bounds.width - preferredContentSize.width) / 2
        let topMargin = (bounds.height - preferredContentSize.height) / 2
        assert(sideMargin >= 0 && topMargin >= 0)
        let x = bounds.minX + sideMargin + border
        let y = bounds.minY + topMargin + border
        var row = 0
        var formerFrame : CGRect? = nil
        var rowStart = CGRect(x: x, y: y, width: C.colorSquareSide, height: C.colorSquareSide)
        let initialColor = delegate.initialColor(tag)
        for i in 0..<views.count {
            let view = views[i]
            if let former = formerFrame {
                if row == 0 {
                    // New row
                    view.frame = rowStart.offsetBy(dx: 0, dy: C.colorSquareSide + border)
                    rowStart = view.frame
                } else {
                    // Continuing a row
                    view.frame = former.offsetBy(dx: C.colorSquareSide + border, dy: 0)
                }
            } else {
                // Very first box
                view.frame = rowStart
            }
            if i == initialColor {
                selectionMarker.frame = CGRect(origin: CGPoint.zero, size: C.markerSize)
                selectionMarker.center = view.center
                self.view.bringSubviewToFront(selectionMarker)
            }
            formerFrame = view.frame
            row += 1
            if row == C.rowSize {
                row = 0
            }
        }
    }

    //  Actions

    @objc func colorTouched(_ button: UIButton) {
        delegate.colorChosen(button.tag, tag)
        Logger.logDismiss(self, host: (presentingViewController ?? self), animated: true)
    }

    private static func computePreferredSize(_ count: Int) -> CGSize {
        let width = rowSize * colorSquareSide + (rowSize + 1) * border
        let rows = (count + 1) / rowSize
        let height = rows * colorSquareSide + (rows + 1) * border
        return CGSize(width: width, height: height)
    }
}
