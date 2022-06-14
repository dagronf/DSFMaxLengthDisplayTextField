//
//  BackwardCompatiblePublisher.swift
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

import Foundation

#if canImport(Combine)
import Combine
#endif

/// A OS-safe `AnyCancellable` wrapper abstracting away OS versions that don't support Combine
public class BackwardsCompatibleCancellable {
	/// Create a BackwardsCompatibleCancellable from an AnyCancellable
	@available(macOS 10.15, iOS 13, tvOS 13, *)
	public init(_ cancellable: AnyCancellable) {
		_cancellable = cancellable
	}

	/// Cancel the publisher
	public func cancel() {
		if #available(OSX 10.15, iOS 13, tvOS 13, *) {
			(_cancellable as? AnyCancellable)?.cancel()
		}
	}

	// The wrapped cancellable
	private let _cancellable: AnyObject

	deinit {
		self.cancel()
	}
}

@available(macOS 10.15, iOS 13, tvOS 13, *)
extension AnyCancellable {
	/// Type-erase the AnyCancellable to a `CompatibleCancellable` type.
	@inlinable public func backwardsCompatibleCancellable() -> BackwardsCompatibleCancellable {
		BackwardsCompatibleCancellable(self)
	}
}

/// A wrapper class for abstracting away Combine OS compatibility
public class BackwardsCompatiblePublisher<ValueType> {

	/// Does the current OS support Combine publishing?
	public static var CanPublish: Bool {
		if #available(OSX 10.15, iOS 13, tvOS 13, *) {
			return true
		}
		return false
	}

	/// Create a publisher. If the OS does not support Combine, returns nil.
	public init?() {
		if #available(OSX 10.15, iOS 13, tvOS 13, *) {
			self._publisher = PassthroughSubject<ValueType, Never>()
		}
		else {
			return nil
		}
	}

	/// Push a new value to the publisher
	public func send(_ value: ValueType) {
		if #available(OSX 10.15, iOS 13, tvOS 13, *) {
			self.__passthroughSubject.send(value)
		}
		else {
			// In theory, this should never be hit as unsupporting versions return nil in the init()
			fatalError("Error: Combine is not available for this platform version.")
		}
	}

	// A type-erased publisher
	private let _publisher: AnyObject?
}

@available(macOS 10.15, iOS 13, tvOS 13, *)
extension BackwardsCompatiblePublisher {
	/// Combine publisher.
	///
	/// Note that the publisher can send events on non-main threads, so its important
	/// for your listeners to swap to the main thread if they are updating UI
	public var publisher: AnyPublisher<ValueType, Never> {
		return self.__passthroughSubject.eraseToAnyPublisher()
	}
}

@available(macOS 10.15, iOS 13, tvOS 13, *)
private extension BackwardsCompatiblePublisher {
	// Internal publisher to allow us to send new values
	var __passthroughSubject: PassthroughSubject<ValueType, Never> {
		return self._publisher as! PassthroughSubject<ValueType, Never>
	}
}
