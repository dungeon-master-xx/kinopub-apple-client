//
//  BackendError.swift
//
//
//  Created by Kirill Kunst on 27.07.2023.
//

import Foundation

/// A server error identifier.
///
/// This is deliberately an open string-backed type instead of an enum. OAuth device-flow servers
/// may add standard errors such as `slow_down`, `expired_token`, or `access_denied`; decoding the
/// entire response must not fail just because the client has not seen a particular value before.
public struct BackendErrorCode: RawRepresentable, Codable, Hashable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public static let authorizationPending = Self(rawValue: "authorization_pending")
  public static let slowDown = Self(rawValue: "slow_down")
  public static let expiredToken = Self(rawValue: "expired_token")
  public static let accessDenied = Self(rawValue: "access_denied")
  public static let invalidClient = Self(rawValue: "invalid_client")
  public static let unauthorized = Self(rawValue: "unauthorized")
}

public struct BackendError: Error, Codable, Sendable {
  public var status: Int
  public var errorCode: BackendErrorCode
  public var errorDescription: String?

  private enum CodingKeys: String, CodingKey {
    case status
    case errorCode = "error"
    case errorDescription = "error_description"
  }
}
