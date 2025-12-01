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
import MessageUI

// Utility to send feedback, possibly including logs

fileprivate let FeedbackSubjectTemplate = "%@ Feedback"
fileprivate let CrashSubjectTemplate = "%@ Crash Report"

fileprivate let FeedbackMessageTemplate = """
Replace this text with your specific feedback.   If you are reporting a problem, it is best to leave any 
log attachments in place; they are transcripts of events that occurred in %@ games and will help in diagnosing
the problem.  If you prefer to delete the logs it is your call.
"""

fileprivate let CrashMessageTemplate = """
Replace this text with a description of what you were doing at the moment of the crash.
Leave the log attachments in place; they are needed to diagnose the crash.  They are transcripts
of events that occurred in %@ games leading up to the crash but do not include personal data.
"""

public class Feedback {
    // Send feedback.  Return true if mail is enabled on this platform and the email client was opened
    //    (not a guarantee that mail was sent, since sending is actually up to the user).  The delegate
    //    can determine whether email was actually sent.
    // The arguments are
    //     the app name
    //     the mail destination
    //     a hosting view controller
    //     a mail composer delegate (may be the same object as host)
    //     optional flag indicating that the feedback is a crash report
    // It is up to the delegate to dismiss the view and record the outcome.
    public static func send(_ appName: String, dest: String, host: UIViewController,
                            delegate: MFMailComposeViewControllerDelegate, isCrash: Bool = false) -> Bool {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = delegate
            mail.setToRecipients([dest])
            let messageTemplate = isCrash ? CrashMessageTemplate : FeedbackMessageTemplate
            let subjectTemplate = isCrash ? CrashSubjectTemplate : FeedbackSubjectTemplate
            let messageBody = String(format: messageTemplate, appName)
            mail.setMessageBody(messageBody, isHTML: true)
            let subject = String(format: subjectTemplate, appName)
            mail.setSubject(subject)
            let logs = Logger.getAllLogIndices()
            if logs.count > 0 {
                addLog(mail, logs[0])
            }
            if logs.count > 1 {
                addLog(mail, logs[1])
            }
            Logger.logPresent(mail, host: host, animated: true)
            return true
        } else {
            return false
        }
    }

    // Add a log to the outgoing email
    private static func addLog(_ mail: MFMailComposeViewController, _ index: Int) {
        let logPath = Logger.makeLogPath(index)
        let url = URL(fileURLWithPath: logPath)
        if let attachmentData = try? Data(contentsOf: url) {
            mail.addAttachmentData(attachmentData, mimeType: "text/plain", fileName: Logger.LogPrefix + String(index))
        } else {
            Logger.log(String(format: "Unable to read data from log with path %@", logPath))
        }
    }
}
