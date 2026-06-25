//
//  DeviceService.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 25.06.2026.
//

import Foundation
import KinoPubBackend

protocol DeviceService {
  func fetchCurrentDevice() async throws -> DeviceInfo
  func fetchSettings(deviceId: Int) async throws -> DeviceSettings
  func updateSettings(deviceId: Int, settings: DeviceSettings) async throws
  /// Registers this device's name/specs so it isn't listed as "unknown".
  func registerDeviceName() async
  /// Advertises this hardware's real capabilities (HEVC/4K) to the server so kino.pub serves
  /// HEVC + HDR10 renditions to the native player. Enable-only; never turns a capability off.
  func syncCapabilities() async
}

protocol DeviceServiceProvider {
  var deviceService: DeviceService { get set }
}

struct DeviceServiceMock: DeviceService {

  func fetchCurrentDevice() async throws -> DeviceInfo {
    DeviceInfo.mock()
  }

  func fetchSettings(deviceId: Int) async throws -> DeviceSettings {
    DeviceSettings.mock()
  }

  func updateSettings(deviceId: Int, settings: DeviceSettings) async throws {
    // no-op
  }

  func registerDeviceName() async {
    // no-op
  }

  func syncCapabilities() async {
    // no-op
  }
}
