//
//  APIClientError+Description.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 27.07.2023.
//

import Foundation
import KinoPubBackend

extension APIClientError: @retroactive CustomStringConvertible {
  public var description: String {
    errorDescription ?? "Unknown KinoPub API error"
  }

  var isAuthorizationPending: Bool {
    backendError?.errorCode == .authorizationPending
  }

  var shouldSlowAuthorizationPolling: Bool {
    backendError?.errorCode == .slowDown
  }

  var isActivationCodeExpired: Bool {
    backendError?.errorCode == .expiredToken
  }

  var isRetryableTransportError: Bool {
    guard case .networkError(let error) = self, !(error is BackendError) else { return false }
    if error is URLError { return true }
    let nsError = error as NSError
    return nsError.domain == NSURLErrorDomain
  }

  private var backendError: BackendError? {
    guard case .networkError(let error) = self else { return nil }
    return error as? BackendError
  }

}

extension Error {
  /// `true` when this error — or any error it wraps — represents a cancelled request.
  /// Requests get cancelled normally when a screen disappears or the user navigates away
  /// mid-load (e.g. the Home shelves firing several requests at once), so these must never
  /// be surfaced to the user as an error.
  var isCancellationError: Bool {
    if self is CancellationError {
      return true
    }
    let nsError = self as NSError
    if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
      return true
    }
    if let apiError = self as? APIClientError, case .networkError(let underlying) = apiError {
      return underlying.isCancellationError
    }
    if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
      return underlying.isCancellationError
    }
    return false
  }
}
