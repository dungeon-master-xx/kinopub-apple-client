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

  /// User-facing copy. Lives here rather than in `KinoPubBackend` because this is the target that
  /// owns `Localizable.xcstrings`.
  ///
  /// kino.pub's own `error_description` wins when it sends one — it's already localized server-side.
  /// These strings cover the cases where it sends only an error code, which is exactly the path that
  /// used to surface as a raw `APIClientError error 0`.
  var localizedMessage: String {
    if case .networkError(let error) = self {
      if let backendError = error as? BackendError {
        if let description = backendError.errorDescription, !description.isEmpty {
          return description
        }

        switch backendError.errorCode {
        case .authorizationPending:
          return "Waiting for the code to be confirmed on kino.pub.".localized
        case .slowDown:
          return "The server asked the app to check less often.".localized
        case .expiredToken:
          return "The activation code expired. Requesting a new one.".localized
        case .accessDenied:
          return "Device activation was denied.".localized
        case .invalidClient:
          return "This app build isn't recognized by the KinoPub server.".localized
        case .unauthorized:
          return "Your KinoPub session isn't authorized. Try activating again.".localized
        default:
          break
        }
      }
      // Transport failures fall through: URLError's own message ("The Internet connection appears
      // to be offline.") is localized by the system in every language the app ships, which beats
      // anything this catalog could cover.
    }

    return errorDescription ?? description
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

  /// A transport-level failure worth retrying: offline, timed out, connection dropped.
  /// Cancellation is explicitly excluded — that's the caller deciding to stop, not a flaky network.
  var isRetryableTransportError: Bool {
    guard case .networkError(let error) = self, !(error is BackendError) else { return false }
    guard !isCancellationError else { return false }
    if error is URLError { return true }
    return (error as NSError).domain == NSURLErrorDomain
  }

  private var backendError: BackendError? {
    guard case .networkError(let error) = self else { return nil }
    return error as? BackendError
  }

}

extension Error {
  /// The string to put in front of the user for any error. Routes `APIClientError` through the
  /// localized copy above and leaves everything else to Foundation.
  var userFacingMessage: String {
    if let apiError = self as? APIClientError {
      return apiError.localizedMessage
    }
    return localizedDescription
  }

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
