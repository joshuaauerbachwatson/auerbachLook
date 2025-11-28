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

// Base class for popover dialogs that make choices from items in a simple table view.   Sections are supported
// (in "grouped" style) but the implementation is biased toward simple cases with just one section.

// Constants
fileprivate let headerText = "Tap on a list item to choose it"
fileprivate let backgroundColor = UIColor.lightGray
fileprivate let headerTextColor = UIColor.white
fileprivate let headerBackground = UIColor.black
fileprivate let pickerTextColor = UIColor.black
fileprivate let pickerBackground = UIColor.white
fileprivate let expectedWidth = CGFloat(300)
fileprivate let margin = CGFloat(10)
fileprivate let spacing = CGFloat(6)
fileprivate let tabletCtlHeight = CGFloat(30)
fileprivate let phoneCtlHeight = CGFloat(15)
fileprivate let reuseIdentifier = "tableDialog"

// The class itself
open class TableDialogController : PopupViewController, UITableViewDelegate,  UITableViewDataSource {

    // State
    public let sectionCount : Int
    private let header = UILabel()
    private var picker : UITableView!  // Delayed init (viewDidLoad)
    private var width = CGFloat(0)  // Will be reset in viewDidLoad

    // Recompute ctlHeight for phones to avoid scrolling issues
    private static var ctlHeight : CGFloat {
        let isPhone = UIScreen.main.traitCollection.userInterfaceIdiom == .phone
        return isPhone ? phoneCtlHeight : tabletCtlHeight
    }

    // Initialized with the owning view, the size, and the anchor point (optionally, direction with a default of .up and section count with a default of 1)
    public init(_ view: UIView, size: CGSize, anchor: CGPoint, direction: UIPopoverArrowDirection = .up, sectionCount: Int = 1) {
        self.sectionCount = sectionCount
        super.init(size, view, CGRect(origin: anchor, size: CGSize.zero), direction)
    }

    // Necessary but useless
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Should be closely coordinated with the layout done in viewDidLoad.  This function calculates the approximate height needed to
    // compactly display a given number of rows.  For convenience it returns a size, not just a height, but the width is statically determined.
    public class func getPreferredSize(_ rows : Int) -> CGSize {
        let headerY = margin
        let pickerY = headerY + ctlHeight + spacing
        return CGSize(width: expectedWidth, height: pickerY + rows * (ctlHeight + spacing) + margin)
    }

    // Create and layout the subviews
    public override func viewDidLoad() {
        // Layout assumes preferred size was respected
        let x = margin
        width = preferredContentSize.width - 2 * margin
        let headerY = margin
        let pickerY = headerY + Self.ctlHeight + spacing
        let pickerHeight = preferredContentSize.height - pickerY - spacing

        // Header
        header.text = headerText
        header.textColor = headerTextColor
        header.backgroundColor = headerBackground
        header.textAlignment = .center
        header.adjustsFontSizeToFitWidth = true
        header.frame = CGRect(x: x, y: headerY, width: width, height: Self.ctlHeight)
        view.addSubview(header)

        // Table View
        let frame = CGRect(x: x, y: pickerY, width: width, height: pickerHeight)
        picker = UITableView(frame: frame, style: sectionCount > 1 ? .grouped: .plain) // Satisfies delayed init
        picker.rowHeight = Self.ctlHeight + spacing
        picker.sectionHeaderHeight = picker.rowHeight
        picker.sectionFooterHeight = 0
        picker.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        picker.dataSource = self
        picker.delegate = self
        picker.frame = CGRect(x: x, y: pickerY, width: width, height: pickerHeight)
        picker.register(TableDialogCell.self, forCellReuseIdentifier: reuseIdentifier)
        view.addSubview(picker)
    }

    // animate the row selection when view appears.  Specializations provide the row via getCurrentRow()
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let path = getCurrentPath()
        picker.selectRow(at: path, animated: true, scrollPosition: .none)
    }

    // Conform to requirements of this protocol method.  Specializations do the deletion via deletePath or deleteRow
    public func tableView(_ tableView: UITableView, commit: UITableViewCell.EditingStyle, forRowAt path: IndexPath) {
        if commit == .delete {
            deletePath(path)
            tableView.deleteRows(at: [path], with: UITableView.RowAnimation.fade)
        } // Ignore insertions for now
    }

    // Conform to requirements of this protocol method.  Specializations initialize the the row text in initializePath
    // or initializeRow
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        if let label = cell.textLabel {
            initializePath(label, indexPath)
        }
        return cell
    }

    // Conform to the requirements of this protocol method.  Specializations take row-specific actions.
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if pathSelected(indexPath) {
            Logger.logDismiss(self, host: (presentingViewController ?? self), animated: true)
        }
    }

    // Implement the optional numberOfSections here to avoid the need for subclasses to worry about it since we need to know
    // about sections anyway.  Subclasses still need to implement the 'path' methods for multiple sections.
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sectionCount
    }

    // Subclasses must provide real implementations of either the 'row' methods (single section) or the 'path' methods
    // (multiple sections).  The subclass can omit implementing the "delete" method if (but only if) it sets the table
    // view not editable.  All must implement tableView:numberOfRowsInSection.

    // Called when a row is selected.  Returns true to dismiss the dialog, false to handle dismissal separately
    open func rowSelected(_ row: Int) -> Bool {
        Logger.logFatalError("Must implement 'rowSelected'")
    }

    // Provide the information for each row's label
    open func initializeRow(_ label: UILabel, _ row: Int) {
        Logger.logFatalError("Must implement 'initializeRow'")
    }

    // Get the currently selected row
    open func getCurrentRow() -> Int {
        Logger.logFatalError("Must implement 'getCurrentRow'")
    }

    // Delete from the model given a row number
    open func deleteRow(_ row: Int) {
        Logger.logFatalError("Must implement 'deleteRow'")
    }

    // Get the number of rows in a section
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Logger.logFatalError("Must implement 'tableView(_:numberOfRowsInSection:)'")
    }

    // Subclasses must provide overrides of these methods iff using sections (defaults work only for single section case)

    // Called when a path is selected.  Returns true to dismiss the dialog, false to handle dismissal separately
    open func pathSelected(_ path: IndexPath) -> Bool {
        if path.section == 0 {
            return rowSelected(path.row)
        }
        Logger.logFatalError("Must implement 'pathSelected' when there are multiple sections")
    }

    // Provide the information for each path's label
    open func initializePath(_ label: UILabel, _ path: IndexPath) {
        if path.section == 0 {
            initializeRow(label, path.row)
            return
        }
        Logger.logFatalError("Must implement 'initializePath' when there are multiple sections")
    }

    // Get the currently selected path
    open func getCurrentPath() -> IndexPath {
        if sectionCount == 1 {
            return IndexPath(row: getCurrentRow(), section: 0)
        }
        Logger.logFatalError("Must implement 'getCurrentPath' when there are multiple sections")
    }

    // Delete from the model given a path
    open func deletePath(_ path: IndexPath) {
        if path.section == 0 {
            deleteRow(path.row)
            return
        }
        Logger.logFatalError("Must implement 'deletePath' when there are multiple sections")
    }

    // Customize the rows to ensure texts are visible across a range of possible settings for font size
    public class TableDialogCell : UITableViewCell {
        public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            if let textLabel = self.textLabel {
                textLabel.adjustsFontSizeToFitWidth = true
            }
        }

        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
