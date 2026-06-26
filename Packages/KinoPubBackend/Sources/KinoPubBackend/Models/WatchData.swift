//
//  WatchData.swift
//
//
//  Created by Kirill Kunst on 11.11.2023.
//

import Foundation

public struct WatchData: Codable, Hashable {
  
  public struct Season: Codable, Hashable {
    public var id: Int
    public var number: Int
    public var status: Int
    public var episodes: [WatchDataVideoItem]
  }
  
  public struct WatchDataItem: Codable, Hashable {
    public var seasons: [Season]?
    public var videos: [WatchDataVideoItem]?
  }
  
  public struct WatchDataVideoItem: Codable, Hashable {
    public var id: Int
    public var number: Int
    public var title: String
    public var time: TimeInterval
    public var status: Int
    /// Total length (seconds) and last-mark timestamp — present in the live response, previously
    /// dropped. Optional so any slimmer response still decodes.
    public var duration: TimeInterval?
    public var updated: TimeInterval?
  }
  
  public var item: WatchDataItem
  
  init(item: WatchDataItem) {
    self.item = item
  }
}

public extension WatchData {
  static var mock: WatchData {
    WatchData(item: WatchDataItem())
  }
}
