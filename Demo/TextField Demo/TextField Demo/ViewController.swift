//
//  ViewController.swift
//  TextField Demo
//
//  Created by Darren Ford on 15/6/2022.
//

import Cocoa
import DSFMaxLengthDisplayTextField
import DSFStepperView

import Combine

class ViewController: NSViewController {

	@IBOutlet weak var titleField: DSFMaxLengthDisplayTextField!
	@IBOutlet weak var descriptiveTextField: DSFMaxLengthDisplayTextField!
	@IBOutlet weak var descriptiveMaxCount: DSFStepperView!

	private var titleFieldCancellable: BackwardsCompatibleCancellable? = nil

	override func viewDidLoad() {
		super.viewDidLoad()

		/// Bind the text field length to the
		descriptiveTextField.bind(
			NSBindingName(rawValue: "maxCharacters"),
			to: descriptiveMaxCount!,
			withKeyPath: "numberValue"
		)

		NSColorPanel.shared.showsAlpha = true

		// Programatically set the title field to check that we work correctly when we set it via code
		self.titleField.stringValue = "12345678901234567890123456789012345678901234567890"

		// Use the 'safe' wrapper to handle combine
		if #available(macOS 10.15, *) {
			self.titleFieldCancellable = titleField.validityPublisher
				.removeDuplicates()
				.sink { newValue in
					Swift.print("Title Validity changed: \(newValue)")
				}
				.backwardsCompatibleCancellable()
		}

		self.descriptiveTextField.isValidChangedCallback = { newValue in
			Swift.print("Descriptive Validity changed: \(newValue)")
		}

		self.descriptiveTextField.contentChangedCallback = {
			Swift.print("Descriptive trimmed: \(self.descriptiveTextField.trimmedStringValue)")
		}
	}

	deinit {
		self.titleFieldCancellable?.cancel()
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func setFeedbackTitle(_ sender: Any) {
		titleField.stringValue = "Example: Xcode crashes when the autocomplete popup appears on screen."
	}

	@IBAction func resetControl(_ sender: Any) {
		self.descriptiveTextField.trimToMaxLength()
	}
}
