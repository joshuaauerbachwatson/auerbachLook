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
import WebKit
import MessageUI

// Controller for a full screen modal view with a web view and a button to dismiss it.  Used to display help texts.

let HelpTextBackground = UIColor.white // Also used by TipController
let HelpViewBackground = UIColor(170, 110, 40) // Also used by TipController
fileprivate let SendFeedback = "sendFeedback" // Internal script name
fileprivate let ResetTips = "resetTips" /* Internal script name */
fileprivate let ReturnLabelWidth = CGFloat(150)
fileprivate let NoEmailTitle = "No Email"
fileprivate let NoEmailMessage =
    "Cannot send problem report because email is not configured on this device or is not available to this app"
fileprivate let HelpExt = "html"

public protocol TipResetter {
    func reset()
}

public class HelpController: UIViewController {
    let helpPage : String // The HTML contents, not a resource name
    let baseURL: URL?     // THe URL to use as a base (may be nil if helpPage is self-contained)
    let email : String?
    let returnText : String? // If nil, keeps the Return button from appearing
    let appName : String
    let tipReset : TipResetter?
    let returnButton = UIButton()
    var webView : WKWebView!  // Delayed init (viewDidLoad)

    // Arguments are 
    // - The HTML to display as Help
    // - The URL to use as a base (may be nil if HTML is self-contained)
    // - (optional) The email address to which feedback should be sent.
    // - Text to use in the return button (if empty, the entire return button is omitted),
    // - The name to use when referring to the app.
    // - (optional) The TipResetter to invoke when the option to restore tips is selected.
    public init(html: String, baseURL: URL?, email: String?, returnText: String?, appName: String,
                tipReset: TipResetter? = nil) {
        self.helpPage = html
        self.email = email
        self.returnText = returnText
        self.tipReset = tipReset
        self.appName = appName
        self.baseURL = baseURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = UIModalPresentationStyle.fullScreen
    }
    
    // Backward compatible init which takes resource name rather than HTML string in first argument
    public convenience init(helpPage: String, email: String, returnText: String?, appName: String,
                            tipReset: TipResetter? = nil) {
        let path = Bundle.main.url(forResource: helpPage, withExtension: HelpExt)!
        guard let html = try? String(contentsOf: path, encoding: .utf8) else {
            Logger.logFatalError("Help file could not be loaded")
        }
        self.init(html: html, baseURL: path, email: email, returnText: returnText, appName: appName, tipReset: tipReset)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Set up view
    public override func viewDidLoad() {
        // Background
        view.backgroundColor = HelpViewBackground

        // Return button
        if let returnText = self.returnText {
            returnButton.setTitle(returnText, for: .normal)
            returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
            returnButton.backgroundColor = ButtonBackground
            returnButton.addTarget(self, action: #selector(returnTouched), for: .touchUpInside)
            returnButton.layer.cornerRadius = 8
            self.view.addSubview(returnButton)
        }

        // Web view
        let config = WKWebViewConfiguration()
        let contentCtl = WKUserContentController()
        contentCtl.add(self, name: SendFeedback)
        contentCtl.add(self, name: ResetTips)
        config.userContentController = contentCtl
        webView = WKWebView(frame: CGRect.zero, configuration: config) // Satisfies delayed init
        webView.backgroundColor = HelpTextBackground
        view.addSubview(webView)
        webView.loadHTMLString(helpPage, baseURL: baseURL)
    }

    // Allow view to be rotated.   We will redo the layout each time while preserving all controller state.
    public override var shouldAutorotate: Bool {
        get {
            return true
        }
    }

    // Respond to request to do new layout
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        doLayout()
    }

    // Support all orientations.   Can layout for portrait or landscape, with tablet or phone type dimensions
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .all
        }
    }

    // Calculate frames for all the subviews based on orientation
    func doLayout() {
        let webX = border
        let webY: CGFloat
        if returnText != nil {
            let returnY = safeAreaOf(view).minY + border
            let returnX = view.bounds.width / CGFloat(2) - ReturnLabelWidth / 2
            returnButton.frame = CGRect(x: returnX, y: returnY, width: ReturnLabelWidth, height: fixedLabelHeight)
            webY = returnButton.frame.maxY + border
        } else {
            webY = safeAreaOf(view).minY + border
        }
        let webWidth = view.bounds.width - 2 * border
        let webHeight = view.bounds.maxY - border - webY
        webView.frame = CGRect(x: webX, y: webY, width: webWidth, height: webHeight)
    }

    // Dismiss view when return button touched
    @objc func returnTouched() {
        Logger.logDismiss(self, host: (presentingViewController ?? self), animated: true)
    }
}

// Conform to WKScriptMessageHandler and MFMailComposeViewControllerDelegate
extension HelpController : WKScriptMessageHandler, MFMailComposeViewControllerDelegate {
    // Dispatch "scripts" to internal functions
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle scripts
        switch message.name {
        case ResetTips:
            tipReset?.reset()
        case SendFeedback:
            if let email {
                if !Feedback.send(appName, dest: email, host: self) {
                    bummer(title: NoEmailTitle, message: NoEmailMessage, host: self)
                }
            }
        default:
            Logger.log("userContentController called with unexpected handler name: " + message.name)
        }
    }

    // Implement the delegate function to dismiss the mail client
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        Logger.logDismiss(controller, host: self, animated: false)
    }
}
