//
//  DSFMaxLengthDisplayTextField+private.swift
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
import Foundation

import DSFAppearanceManager
import VIViewInvalidating

extension DSFMaxLengthDisplayTextField: DSFAppearanceCacheNotifiable {
	public func appearanceDidChange() {
		self.update()
	}

	public func invalidate(view: VIViewType) {
		self.update()
	}
}

internal extension DSFMaxLengthDisplayTextField {
	func setup() {
		self.allowsEditingTextAttributes = true

		self.observer = NotificationCenter.default.addObserver(
			forName: NSControl.textDidChangeNotification,
			object: self,
			queue: .main
		) { [weak self] _ in
			self?.update()
		}

		DSFAppearanceCache.shared.register(self)
	}

	func update() {
		// Need to update the content on the main thread
		DispatchQueue.main.async { [weak self] in
			self?._update()
		}
	}

	private func _update() {
		let defaultTraits: [NSAttributedString.Key: Any] = [
			.font: self.font as Any,
			.foregroundColor: NSColor.textColor,
		]

		self.willChangeValue(for: \Self.characterCount)
		self.willChangeValue(for: \Self.charactersAvailable)
		self.willChangeValue(for: \Self.trimmedStringValue)
		defer { self.didChangeValue(for: \Self.trimmedStringValue) }
		defer { self.didChangeValue(for: \Self.charactersAvailable) }
		defer { self.didChangeValue(for: \Self.characterCount) }

		let rawString: String
		let editingContent: NSMutableAttributedString?
		let staticContent: NSMutableAttributedString?

		if let editor = self.currentEditor() as? NSTextView,
			let e: NSMutableAttributedString = editor.textStorage
		{
			editingContent = e
			rawString = e.string
			staticContent = nil
		}
		else {
			editingContent = nil
			rawString = self.stringValue
			staticContent = NSMutableAttributedString(attributedString: attributedStringValue)
		}

		// Make sure we tell the control that we're editing its content IF we are currently editing!
		editingContent?.beginEditing()
		defer { editingContent?.endEditing() }

		// Should be editing or static. Fail if not.
		assert([editingContent, staticContent].compactMap { $0 }.count == 1)

		self.characterCount = rawString.count
		self.overflowCharacterCount = max(0, rawString.count - self.maxCharacters)

		if let e = editingContent {
			e.setAttributes(defaultTraits, range: NSRange(location: 0, length: e.length))
		}
		else if let s = staticContent {
			s.setAttributes(defaultTraits, range: NSRange(location: 0, length: s.length))
		}

		let wasPreviouslyValid = self.isValid
		let isNowValid = self.characterCount <= self.maxCharacters
		let hasChanged = wasPreviouslyValid != isNowValid

		if hasChanged {
			self.willChangeValue(for: \.isValid)
		}

		if self.characterCount <= self.maxCharacters {
			self.isValid = true
			if let s = staticContent {
				self.attributedStringValue = s
			}
			self.overflowCharacterCount = 0
		}
		else {
			self.isValid = false

			var overFlowAttributes: [NSAttributedString.Key: Any] = [
				.foregroundColor: self.overflowTextColor,
				.backgroundColor: self.overflowTextBackgroundColor,
			]

			// Calculate the range from grapheme into utf16
			let index = rawString.index(rawString.startIndex, offsetBy: self.maxCharacters)
			let endIndex = rawString.endIndex
			let mappedRange = NSRange(index ..< endIndex, in: rawString)

			if self.underlineOverflowCharacters || DSFAppearanceCache.shared.differentiateWithoutColor {
				overFlowAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
			}

			if let e = editingContent {
				e.addAttributes(overFlowAttributes, range: mappedRange)
			}
			else if let s = staticContent {
				s.addAttributes(overFlowAttributes, range: mappedRange)
				self.attributedStringValue = s
			}
		}

		// Call the content change callback
		self.contentChangedCallback?()

		if hasChanged {
			self.didChangeValue(for: \.isValid)

			// Push out the validity to the publisher
			self._isValidPublisher?.send(isValid)

			// Push the validity change out to the callback
			self.isValidChangedCallback?(isValid)
		}
	}
}

#endif
