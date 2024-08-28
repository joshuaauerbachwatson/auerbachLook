//
//  TipController.swift
//  Razor Puzzle
//
//  Created by Joshua Auerbach on 3/31/18.
//  Copyright © 2018 Joshua Auerbach. All rights reserved.
//

import UIKit
import WebKit

// Controller for an overlay view ("formSheet style") that displays a tip, with options to simply dismiss or never show again.
// The tip is expected to be html and is shown with a WKWebView
public protocol TipDelegate {
    func notAgain(_ tag: Int)
}
open class TipController: UIViewController {
    // Constants
    let OkText = "OK"
    let NotAgainText = "Don't show again"

    // Subviews
    let okButton = UIButton()
    let notAgainButton = UIButton()
    let webView = WKWebView()

    // Other state
    let html : String
    let delegate : TipDelegate
    let tag : Int

    public init(html: String, delegate: TipDelegate, tag: Int, contentSize: CGSize) {
        self.html = html
        self.delegate = delegate
        self.tag = tag
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = contentSize
        modalPresentationStyle = UIModalPresentationStyle.formSheet
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Set up view
    open override func viewDidLoad() {
        // Background
        view.backgroundColor = HelpViewBackground

        // Buttons
        configureButton(okButton, title: OkText, target: self, action: #selector(okTouched), parent: self.view)
        configureButton(notAgainButton, title: NotAgainText, target: self, action: #selector(notAgainTouched), parent: self.view)

        // Web view
        webView.backgroundColor = HelpTextBackground
        view.addSubview(webView)
        webView.loadHTMLString(html, baseURL: nil)
    }

    // Allow view to be rotated.   We will redo the layout each time while preserving all controller state.
    open override var shouldAutorotate: Bool {
        get {
            return true
        }
    }

    // Respond to request to do new layout
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        doLayout()
    }

    // Support all orientations.   Can layout for portrait or landscape, with tablet or phone type dimensions
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .all
        }
    }

    // Calculate frames for all the subviews based on orientation
    func doLayout() {
        let webX = border
        let webY = border
        let webWidth = view.bounds.width - 2 * border
        let webHeight = view.bounds.height - 3 * border - fixedLabelHeight
        webView.frame = CGRect(x: webX, y: webY, width: webWidth, height: webHeight)
        let buttonWidth = (webWidth - border) / 2
        okButton.frame = CGRect(x: webX, y: webView.frame.maxY + border, width: buttonWidth, height: fixedLabelHeight)
        notAgainButton.frame = okButton.frame.offsetBy(dx: buttonWidth + border, dy: 0)
    }

    // Indicate disablement when notAgain button touched (also dismiss)
    @objc func notAgainTouched() {
        delegate.notAgain(tag)
        Logger.logDismiss(self, host: (presentingViewController ?? self), animated: true)
    }

    // Dismiss view when ok button touched
    @objc func okTouched() {
        Logger.logDismiss(self, host: (presentingViewController ?? self), animated: true)
    }

    // Attempt to get this to work on a phone without getting turned into full screen
    // BTW it does not seem to have that effect in portrait mode.
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}


