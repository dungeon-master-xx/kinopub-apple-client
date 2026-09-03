//
//  AuthModel.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 27.07.2023.
//

import Foundation
import SwiftUI
import KinoPubBackend
import KinoPubLogging
import OSLog

@MainActor
class AuthModel: ObservableObject {

  private var authService: AuthorizationService
  private var authState: AuthState
  private var errorHandler: ErrorHandler

  @Published var deviceCode: String = ""
  @Published var close: Bool = false
  /// The page the user opens to enter the code (shown as a hint, e.g. "kino.pub/device").
  @Published var verificationURL: String = ""

  private var tempVerificationResponse: VerificationResponse?
  private var pollingTask: Task<Void, Never>?

  /// Consecutive transport failures tolerated before activation gives up and tells the user. The
  /// device code stays valid across a dropped connection, so a blip must not kill activation — but
  /// retrying forever would leave a dead screen looking alive.
  private static let maxTransportRetries = 5

  init(authService: AuthorizationService, authState: AuthState, errorHandler: ErrorHandler) {
    self.authService = authService
    self.authState = authState
    self.errorHandler = errorHandler
  }

  /// Stops activation polling. Called when the activation screen goes away — the task holds a
  /// strong reference to this model while it loops, so without this it would keep hitting the API
  /// (and keep the model alive) long after the user closed the screen.
  func cancelPolling() {
    pollingTask?.cancel()
    pollingTask = nil
  }

  func fetchDeviceCode() {
    Logger.app.debug("Fetch device code...")
    cancelPolling()
    errorHandler.reset()
    Task {
      do {
        let response = try await authService.fetchDeviceCode()
        self.deviceCode = response.userCode
        self.verificationURL = response.verificationUri
        self.tempVerificationResponse = response
        Logger.app.debug("receive device code: \(response.userCode)")
        startPolling(for: response)
      } catch {
        handleError(error)
      }
    }
  }

  func copyCode() {
    guard !deviceCode.isEmpty else { return }
    #if os(iOS)
    UIPasteboard.general.string = deviceCode
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(deviceCode, forType: .string)
    #endif
  }

  /// Human-friendly activation page (host + path, without the scheme), e.g. "kino.pub/device".
  var activationDisplayURL: String {
    guard let url = URL(string: verificationURL), let host = url.host else { return verificationURL }
    let path = url.path
    return path.isEmpty || path == "/" ? host : host + path
  }

  func openActivationURL() {
    guard let urlString = tempVerificationResponse?.verificationUri, let url = URL(string: urlString) else {
      return
    }

    Logger.app.debug("open activation url: \(url)")

    #if os(iOS)
    UIApplication.shared.open(url)
    #endif
  }

  private func startPolling(for response: VerificationResponse) {
    pollingTask?.cancel()
    pollingTask = Task { [weak self] in
      guard let self else { return }

      var interval = max(response.interval, 1)
      var transportFailures = 0
      let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))

      while !Task.isCancelled {
        if Date() >= expiresAt {
          Logger.app.debug("device code expired; requesting a replacement")
          fetchDeviceCode()
          return
        }

        do {
          try await Task.sleep(for: .seconds(interval))
          try Task.checkCancellation()
          Logger.app.debug("request token...")
          try await authService.fetchToken(by: response)
          authState.userState = .authorized
          authState.shouldShowAuthentication = false
          errorHandler.reset()
          Logger.app.debug("token requested")
          return
        } catch is CancellationError {
          return
        } catch let error as APIClientError {
          if error.isCancellationError {
            return
          }
          if error.isAuthorizationPending {
            // The server answered, so whatever connection trouble we had is over.
            transportFailures = 0
            continue
          }
          if error.shouldSlowAuthorizationPolling {
            transportFailures = 0
            interval += 5
            Logger.app.debug("authorization poll slowed to \(interval) seconds")
            continue
          }
          if error.isActivationCodeExpired {
            Logger.app.debug("server expired device code; requesting a replacement")
            fetchDeviceCode()
            return
          }
          if error.isRetryableTransportError {
            transportFailures += 1
            guard transportFailures < Self.maxTransportRetries else {
              Logger.app.debug("giving up after \(transportFailures) transport failures")
              handleError(error)
              return
            }
            Logger.app.debug("transient polling error \(transportFailures)/\(Self.maxTransportRetries): \(error)")
            continue
          }

          handleError(error)
          return
        } catch {
          handleError(error)
          return
        }
      }
    }
  }

  private func handleError(_ error: Error) {
    Logger.app.debug("got error: \(error)")
    // `setError` drops cancellations on its own, so they never reach the user as an alert.
    errorHandler.setError(error)
  }

}
