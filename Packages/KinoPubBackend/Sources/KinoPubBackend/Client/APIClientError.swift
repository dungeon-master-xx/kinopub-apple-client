//
//  APIClientError.swift
//
//
//  Created by Kirill Kunst on 21.07.2023.
//

import Foundation

public enum APIClientError: Error {
  case urlError
  case invalidUrlParams
  case networkError(Error)
  case decodingError(Error)
}

/// Without this, `localizedDescription` falls back to Foundation's generic
/// "The operation couldn't be completed. (KinoPubBackend.APIClientError error 0.)", which is what
/// the activation screen used to show instead of the real reason.
///
/// This stays deliberately technical: it's the string that reaches logs and any caller that hasn't
/// localized the failure itself. User-facing copy for the codes the UI cares about lives in the app
/// target, where the string catalog is (see `APIClientError.localizedMessage`).
extension APIClientError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .urlError:
      return "The server URL is invalid."
    case .invalidUrlParams:
      return "The request contains invalid URL parameters."
    case .networkError(let error):
      guard let backendError = error as? BackendError else {
        return error.localizedDescription
      }

      if let description = backendError.errorDescription, !description.isEmpty {
        return description
      }

      return "KinoPub server error: \(backendError.errorCode.rawValue)"
    case .decodingError(let error):
      return "The KinoPub server returned an unexpected response: \(error.localizedDescription)"
    }
  }
}
