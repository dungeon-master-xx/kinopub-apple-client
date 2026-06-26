//
//  DeviceCapabilities.swift
//  KinoPubAppleClient
//
//  Detects whether this device can DECODE HEVC (incl. 10-bit / HDR10), so we advertise HEVC/4K to
//  kino.pub only where the stream will actually play. When HEVC+4K are on, kino.pub serves HDR titles
//  as an HDR10-only master (10-bit HEVC Main10, VIDEO-RANGE=PQ) with NO SDR fallback. A device that
//  can decode that plays it fine — AVPlayer tone-maps HDR10 down on SDR displays (e.g. the base iPad),
//  so true-HDR display capability is NOT required, only 10-bit HEVC decode. The Simulator can't decode
//  it and shows the native player's "unplayable" crossed-out play, so it's excluded explicitly.
//

import Foundation
import VideoToolbox
import CoreMedia

enum DeviceCapabilities {

  /// Whether this hardware can decode HEVC (and therefore the HDR10 master). True on A10+ real
  /// devices (incl. iPad A16, even though its display is SDR — playback is tone-mapped). False on the
  /// Simulator and on pre-HEVC hardware, where advertising HEVC would yield an undecodable stream.
  static var supportsHEVC: Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
    #endif
  }
}
