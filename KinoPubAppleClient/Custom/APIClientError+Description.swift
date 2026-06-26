//
//  APIClientError+Description.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 27.07.2023.
//

import Foundation
import KinoPubBackend

extension APIClientError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .urlError:
      return "Wrong URL"
    case .invalidUrlParams:
      return "Invalid URL params"
    case .decodingError(let error):
      return "Decoding issue: \(error)"
    case .networkError(let error):
      if let error = error as? BackendError {
        return error.errorDescription ?? error.localizedDescription
      }
      return "Networking issue: \(error)"
    }
  }

  var isAuthorizationPending: Bool {
    switch self {
    case .networkError(let error):
      if let backendError = error as? BackendError, backendError.errorCode == .authorizationPending {
        return true
      }
      break
    default: return false
    }
    return false
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
