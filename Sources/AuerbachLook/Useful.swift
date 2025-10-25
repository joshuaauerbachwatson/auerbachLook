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
import AVFoundation

// Miscellaneous Useful extensions and functions.

//
// Extensions
//

/* Make CGPoint hashable, and allow x and y to be swapped */
extension CGPoint : @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
    public var swapped : CGPoint {
        return CGPoint(x: self.y, y: self.x)
    }
}

/* Also add a swapped member to CGSize */
extension CGSize {
    public var swapped : CGSize {
        return CGSize(width: self.height, height: self.width)
    }
}

// 'Screenshot' initializers for UIImage from CALayer or UIView.  The image is created from the layer's content but does not reflect rotation
// that might be imparted by its transform.
extension UIImage {
    public convenience init(view: UIView) {
        self.init(layer: view.layer)
    }
    public convenience init(layer: CALayer, size: CGSize? = nil) {
        let sizeToUse = size ?? layer.bounds.size // use bounds, not frame, since frame might reflect a transform that will be ignored by the rendering
        UIGraphicsBeginImageContext(sizeToUse)
        layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}

/* Convenient constructor for colors (uses three integers 0-255 for RGB) */
public extension UIColor {
    convenience init(_ r: Int, _ g: Int, _ b: Int) {
        let div = CGFloat(255)
        self.init(red: r/div, green: g/div, blue: b/div, alpha: CGFloat(1.0))
    }
}

/* Java-like String.trim() */
public extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}

// Add 'center' property to CGRect and CALayer
public extension CGRect {
    var center : CGPoint {
        get { return CGPoint(x: midX, y: midY) }
        set {
            let dx = midX - minX
            let dy = midY - minY
            origin = newValue - CGPoint(x: dx, y: dy)
        }
    }
}
public extension CALayer {
    var center : CGPoint {
        get { return frame.center }
        set { frame.center = newValue }
    }
}

// Simplify some common call sequences to CATransaction
public extension CATransaction {
    static func beginNoAnimation() {
        begin()
        setAnimationDuration(0)
    }
    static func withNoAnimation(_ actions: ()->()) {
        beginNoAnimation()
        actions()
        commit()
    }
}

// Allow a CGSize or CGRect to be chararactized as landscape (vs portrait) and retrieve the min of height and width
public extension CGSize {
    var landscape: Bool {
        get {
            return width > height
        }
    }
    var minDimension: CGFloat {
        get {
            return landscape ? height : width
        }
    }
}
public extension CGRect {
    var landscape: Bool {
        get {
            return width > height
        }
    }
    var minDimension: CGFloat {
        get {
            return landscape ? height : width
        }
    }
}

// Allow any UIResponder to find its UIViewController
// Issues fatal error if there is none
public extension UIResponder {
    var controller: UIViewController {
        if let vc = self as? UIViewController {
            return vc
        }
        guard let next else {
            Logger.logFatalError("Unable to find UIViewController for UIResponder")
        }
        return next.controller
    }
}

//
// Operators
//

/* Permit addition of two points (allows a translation to be applied to a point) */
public func + (_ p: CGPoint, _ q: CGPoint) -> CGPoint {
    return CGPoint(x: p.x + q.x, y: p.y + q.y)
}

/* Permit subtraction of two points (allows a translation to be applied to a point in a negative direction) */
public func - (_ p: CGPoint, _ q: CGPoint) -> CGPoint {
    return CGPoint(x: p.x - q.x, y: p.y - q.y)
}

/* Permits a point (translation) to be added to a rectangle */
public func + (_ rect: CGRect, _ q: CGPoint) -> CGRect {
    return CGRect(origin: rect.origin + q, size: rect.size)
}

/* Permits a point (translation) to be subtracted from a rectangle */
public func - (_ rect: CGRect, _ q: CGPoint) -> CGRect {
    return CGRect(origin: rect.origin - q, size: rect.size)
}

/* Multiplies a point by a scale factor */
public func * (_ point: CGPoint, _ scale: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scale, y: point.y * scale)
}

/* Multiplies a size by a scale factor (using CGAffineTransform) */
public func * (_ size: CGSize, _ scale: CGFloat) -> CGSize {
    return size.applying(CGAffineTransform(scaleX: scale, y: scale))
}

/* Applies a scale factor to a rectangle (using CGAffineTransform) */
public func * (_ rect: CGRect, _ scale: CGFloat) -> CGRect {
    return rect.applying(CGAffineTransform(scaleX: scale, y: scale))
}

//
// Functions (alphabetical)
//

// Add a border to an image
public func addBorder(_ image: UIImage, _ borderSize: CGFloat) -> UIImage {
    let imageSize = image.size
    let borderedSize = CGSize(width: imageSize.width + 2 * borderSize, height: imageSize.height + 2 * borderSize)
    let bordered = UIView(frame: CGRect(origin: CGPoint.zero, size: borderedSize))
    bordered.backgroundColor = UIColor.black
    let inner = UIImageView(frame: CGRect(x: borderSize, y: borderSize, width: imageSize.width, height: imageSize.height))
    inner.image = image
    bordered.addSubview(inner)
    return UIImage(view: bordered)
}

// Convenience for getting the X value to place one view to the right of another.  The optional
// gap argument gives the amount of space between, defaulting to DialogSpacer.
public func after(_ view: UIView, gap: CGFloat = DialogSpacer) -> CGFloat {
    return view.frame.maxX + gap
}

// Conveniece for getting the Y value to place one view below another.  The optional
// gap argument gives the amount of space between, defaulting to DialogSpacer.
public func below(_ view: UIView, gap: CGFloat = DialogSpacer) -> CGFloat {
    return view.frame.maxY + gap
}

// Display a dialog with a cancellation button that does nothing and a second button that does something
public func confirmBeforeDoing(host: UIViewController, destructive: Bool, title: String, message: String, doNothing: String, doSomething: String,
                        handler: @escaping ()->Void) {
    let ignore = UIAlertAction(title: doNothing, style: .cancel) { _ in
        // Do nothing if this is chosen
    }
    let proceed = UIAlertAction(title: doSomething, style: destructive ? .destructive : .default) { _ in
        handler()
    }
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(ignore)
    alert.addAction(proceed)
    Logger.logPresent(alert, host: host, animated: true)
}

// Crop an image to a given rectangle
public func cropImage(_ original: UIImage, _ rect: CGRect) -> UIImage {
    // A correct cropping requires the image to be in the "up" orientation, so we first assure that.
    let imageToCrop = ensureUpOrientation(original)
    // Cropping is available at the CGImage level, so get that form
    guard let cgi = imageToCrop.cgImage else { return original }  // Hopefully, won't return here (our images should have CGImage properties)
    // Adjust cropping rectangle to the scale of the image
    let scale = imageToCrop.scale
    let cropRect = rect.applying(CGAffineTransform(scaleX: scale, y: scale))
    // Perform cropping
    guard let newcgi = cgi.cropping(to: cropRect) else { return original } // Again, hoping ...
    // Restore to UIImage form, restoring scale as well.
    let ans = UIImage(cgImage: newcgi, scale: scale, orientation: .up)
    return ans
}

// Constant used by the below and after functions as the default gap value.
public let DialogSpacer = CGFloat(4)

// Ensure that an image is in the "up" orientation by redrawing it if not
public func ensureUpOrientation(_ image: UIImage)->UIImage {
    if image.imageOrientation == .up {
        return image
    }
    UIGraphicsBeginImageContextWithOptions(image.size, true, 1.0)
    image.draw(at: .zero)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage ?? image
}

// Get documents directory as a URL.  This method will crash the app if there is no documents directory, but I believe that never happens.
public func getDocDirectory() -> URL {
    if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        return docs
    }
    // There is no point in logging the error since (1) when debugging the fatalError will report its text on the console and (2) in production there is no
    // way to log the error without a doc directory
    fatalError("Documents directory is missing")
}

// Get the size of a file, if possible (returns nil if the attempt fails, but I don't believe this is likely)
public func getFileSize(_ path: String) -> UInt64? {
    let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path)
    let size = fileAttributes?[FileAttributeKey.size]
    return (size as? NSNumber)?.uint64Value
}

// In a given container, for a given prefix, find the first file suffix not corresponding to an existing file.
// Designed to be called withOUT the optional suffix argument; that is used for recursive calls.
public func findFirstFreeFileName(_ container: URL, _ prefix: String, _ suffix: Int = 1) -> (String, Int) {
    let toTry = container.appendingPathComponent(prefix + String(suffix)).path
    if FileManager.default.fileExists(atPath: toTry) {
        return findFirstFreeFileName(container, prefix, suffix + 1)
    }
    return (toTry, suffix)
}

// Get the suffix portion of a file name in prefix/suffix form
public func getSuffix(_ file: String, _ prefixLen: Int) -> Int? {
    let indexFrom = file.index(file.startIndex, offsetBy: prefixLen)
    return Int(file.suffix(from: indexFrom))
}

// Hide some controls.  For added flexibility, controls may be nil
public func hide(_ ctls: UIView?...) {
    for ctl in ctls {
        ctl?.isHidden = true
    }
}

// Move a path by a given translation distance
public func movePath(_ path: CGPath, by: CGPoint) -> CGPath? {
    var transform = CGAffineTransform(translationX: by.x, y: by.y)
    return path.copy(using: &transform)
}

// Special packaging of bummer for noting holes in the implementation during development (shouldn't be called in production).
// To allow it to be called in tight places, it will present on the console if no host is given to present the dialog.
// If a host is given, the dialog is always attempted but does not always work since the host could be busy with another dialog or
// may not be fully initialized.  We don't test for these conditions because there isn't a solidly reliable test.   If the dialog
// fails, it will result in a message on the console, but a less informative one.
public func notImplemented(_ function: String, host maybeHost: UIViewController?) {
    if let host = maybeHost {
        bummer(title: "Not Implemented", message: "You need to write the code for \(function)", host: host)
    } else {
        print("Not implemented: you need to write the code for \(function)")
    }
}

// Convenience for setting the frame of a view.  Returns the view as a further convenience for chaining.
@discardableResult
public func place(_ view: UIView, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> UIView {
    view.frame = CGRect(x: x, y: y, width: width, height: height)
    return view
}

// Play a sound.  Returns the player, which must be kept long enough to let the sound complete.
public func playSound(_ name: String, _ ext: String) -> AVAudioPlayer? {
    guard let url = Bundle.module.url(forResource: name, withExtension: ext) else { return nil }
    try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
    try? AVAudioSession.sharedInstance().setActive(true)
    guard let player = try? AVAudioPlayer(contentsOf: url, fileTypeHint: nil) else { return nil }
    player.play()
    return player
}

// Random Bool
public func randomBool() -> Bool {
    return arc4random_uniform(2) == 1
}

// Random double in the range -1.0...1.0
public func randomDouble() -> Double {
    return drand48() * 2.0 - 1.0
}

// Choose a random origin for a rectangle of a given size to fit entirely inside another rectangle
public func randomOrigin(_ size: CGSize, _ outer: CGRect) -> CGPoint {
    let minX = outer.minX
    let minY = outer.minY
    let maxX = outer.maxX - size.width
    let maxY = outer.maxY - size.height
    let x = minX + drand48() * (maxX - minX)
    let y = minY + drand48() * (maxY - minY)
    return CGPoint(x: x, y: y)
}

// Generate a random alphameric string
public func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}

// Resize an image given the original image and a target rectangle
public func resizeImage(_ original: UIImage, to: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(to, true, 0.0)
    original.draw(in: CGRect(origin: CGPoint.zero, size: to))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return scaledImage ?? original
}

// Rotate a CGPath around zero.
public func rotatePath(_ path: CGPath, by: CGFloat) -> CGPath? {
    var transform = CGAffineTransform(rotationAngle: by)
    return path.copy(using: &transform)
}

// Rotate one point around another
public func rotatePoint(_ point: CGPoint, around: CGPoint, by: CGFloat) -> CGPoint {
    let dx = point.x - around.x
    let dy = point.y - around.y
    let radius = sqrt(dx * dx + dy * dy)
    let azimuth = atan2(dy, dx) + by
    let x = around.x + radius * cos(azimuth)
    let y = around.y + radius * sin(azimuth)
    return CGPoint(x: x, y: y)
}


// Run an sequence of automations provided as an array of functions
public func runAnimationSequence(_ seq: [()->Void], completion: @escaping ()->Void) {
    var next = 0
    func runNextAnimation() {
        guard next < seq.count else { return }
        let animation = seq[next]
        next += 1
        CATransaction.begin()
        CATransaction.setCompletionBlock({ runNextAnimation() })
        animation()
        if next == seq.count {
            completion()
        }
        CATransaction.commit()
    }
    runNextAnimation()
}

// Determine the safe area of a main view.  Since we are assuming at least iOS 11, we
// can use the safeAreaInsets property of the view to compute the result.
public func safeAreaOf(_ view: UIView) -> CGRect {
    let insets = view.safeAreaInsets
    return view.bounds.inset(by: insets)
}

// Parse a file name into prefix and suffix form while looking for a particular prefix; useful when scanning a folder for files
// of a given kind.  Boolean return aids in chaining when scanning for multiple kinds in a single pass.
@discardableResult
public func screenFileName(_ file: String, prefix: String, into: inout [Int]) -> Bool {
    if file.hasPrefix(prefix), let suffix = getSuffix(file, prefix.count) {
        into.append(suffix)
        return true
    }
    return false
}

// Alternative to previous screenFileName when not chaining in an iterationa
public func screenFileName(_ file: String, prefix: String) -> Int {
    if file.hasPrefix(prefix), let suffix = getSuffix(file, prefix.count) {
        return suffix
    }
    return -1
}

// Provide a shuffled version of an array
public func shuffle<T>(_ array : [T]) -> [T] {
    var holder = [T]()
    holder.append(contentsOf: array)
    var ans = [T]()
    while !holder.isEmpty {
        let toRemove = Int(arc4random_uniform(UInt32(holder.count)))
        ans.append(holder.remove(at: toRemove))
    }
    return ans
}

// Unhide some controls.  For added flexibility, controls may be nil.
public func unhide(_ ctls: UIView?...) {
    for ctl in ctls {
        ctl?.isHidden = false
    }
}
