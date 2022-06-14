//
//  DSFMaxLengthDisplayTextField.swift
//
//  Copyright © 2022 Darren Ford. All rights reserved.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if os(macOS)

import AppKit
import DSFAppearanceManager
import VIViewInvalidating

#if canImport(Combine)
import Combine
#endif

/// A text field that indicates its maximum length by using highlighting the additional characters
/// using a background color and (optional) underline
@IBDesignable
open class DSFMaxLengthDisplayTextField: NSTextField, VIViewCustomInvalidating {

	// MARK: - Counting

	/// The maximum number of grapheme clusters allowed in the field (eg. "🧖🏼‍♀️💆‍♂️🙆🏾abc" == 6)
	@IBInspectable @VIViewInvalidating(.display)
	public dynamic var maxCharacters: Int = 20

	// MARK: - Styling

	/// The color to display the characters beyond the maximum length
	@IBInspectable @VIViewInvalidating(.display)
	public dynamic var overflowTextColor: NSColor = NSColor.textColor

	/// The color to display the characters beyond the maximum length
	@IBInspectable @VIViewInvalidating(.display)
	public dynamic var overflowTextBackgroundColor: NSColor = .systemRed.withAlphaComponent(0.5)

	/// Underline the overflow characters.
	///
	/// The 'Differentiate without color' setting in Accessibility settings overrides this value
	@IBInspectable @VIViewInvalidating(.display)
	public dynamic var underlineOverflowCharacters: Bool = false

	/// If true, overrides the default textfield behaviour when a colorwell is chosen
	/// when the text field is selected.
	@IBInspectable public var overrideDefaultTextFieldColorSelection: Bool = false

	// MARK: - Validity

	/// Is the current length of the text in the text field less than `maxLength`?  (observable)
	@objc public internal(set) dynamic var isValid: Bool = true

	/// A publisher for changes in the field's validity.
	@available(macOS 10.15, *)
	public lazy var validityPublisher: AnyPublisher<Bool, Never> = {
		guard let p = self._isValidPublisher else {
			// If the caller can call this function, then our backwards compatibility wrapper CANNOT be nil.
			fatalError("Cannot unwrap combine publisher - compatibility wrapper is nil (internal programming error)")
		}
		return p.publisher
	}()

	// MARK: - Observable properties

	/// The number of characters (grapheme clusters) in the field (observable)
	@objc public dynamic var characterCount: Int = 0

	/// The number of additional characters available within the field (observable)
	@objc public dynamic var charactersAvailable: Int { self.maxCharacters - self.stringValue.count }

	/// The number of overflow characters (grapheme clusters) (ie. the number of characters beyond the maximum allowed) in the field (observable)
	@objc public dynamic var overflowCharacterCount: Int = 0

	/// The trimmed value of the content (observable)
	@objc public dynamic var trimmedStringValue: String {
		let rawString = self.stringValue
		if rawString.count <= self.maxCharacters {
			return rawString
		}
		let index = rawString.index(rawString.startIndex, offsetBy: self.maxCharacters)
		return String(rawString[rawString.startIndex ..< index])
	}

	// MARK: - NSTextField overrides

	/// The text field's content
	@objc override public var stringValue: String {
		didSet {
			self.update()
		}
	}

	/// The foreground color for characters within the valid range
	override open var textColor: NSColor? {
		get { super.textColor }
		set {
			if self.overrideDefaultTextFieldColorSelection == false {
				super.textColor = newValue
			}
		}
	}

	/// The background color for characters within the valid range
	override open var backgroundColor: NSColor? {
		get { super.backgroundColor }
		set {
			if self.overrideDefaultTextFieldColorSelection == false {
				super.backgroundColor = newValue
			}
		}
	}

	// MARK: - Callbacks

	/// A callback that will be called whenever the content changes
	@objc public var contentChangedCallback: (() -> Void)?

	/// A callback that will be called whenever the validity changes
	@objc public var isValidChangedCallback: ((Bool) -> Void)?

	// MARK: - Create

	/// Create a new text field
	override public init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.setup()
	}

	/// Create a new text field via Interface Builder
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.setup()
	}

	// MARK: - Private

	internal var observer: NSObjectProtocol?

	// A Combine publisher for the `isValid` property
	internal let _isValidPublisher = BackwardsCompatiblePublisher<Bool>()

	deinit {
		DSFAppearanceCache.shared.deregister(self)
		self.observer = nil
	}
}

// MARK: - Convenience Methods

public extension DSFMaxLengthDisplayTextField {
	/// Trim the content to the maximum length
	@objc func trimToMaxLength() {
		self.stringValue = self.trimmedStringValue
	}
}

#endif
