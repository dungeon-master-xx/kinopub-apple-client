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

extension APIClientError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .urlError:
      return "The server URL is invalid."
    case .invalidUrlParams:
      return "The request contains invalid URL parameters."
    case .networkError(let error):
      guard let backendError = error as? BackendError else {
        return "A network error occurred: \(error.localizedDescription)"
      }

      if let description = backendError.errorDescription, !description.isEmpty {
        return description
      }

      switch backendError.errorCode {
      case .authorizationPending:
        return "Device authorization is still pending."
      case .slowDown:
        return "The server asked the app to check less frequently."
      case .expiredToken:
        return "The device activation code expired."
      case .accessDenied:
        return "Device activation was denied."
      case .invalidClient:
        return "The app is not recognized by the KinoPub server."
      case .unauthorized:
        return "The KinoPub session is not authorized."
      default:
        return "KinoPub server error: \(backendError.errorCode.rawValue)"
      }
    case .decodingError(let error):
      return "The KinoPub server returned an unexpected response: \(error.localizedDescription)"
    }
  }
}
