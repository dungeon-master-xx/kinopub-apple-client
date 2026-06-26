//
//  AppContext.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 26.07.2023.
//

import Foundation
import SwiftUI
import KinoPubBackend
import KinoPubKit

// MARK: - Env key

private struct AppContextKey: EnvironmentKey {
  static let defaultValue: AppContextProtocol = AppContext.shared
}

extension EnvironmentValues {
  var appContext: AppContextProtocol {
    get { self[AppContextKey.self] }
    set { self[AppContextKey.self] = newValue }
  }
}

// MARK: - AppContextProtocol

typealias AppContextProtocol = AuthorizationServiceProvider
& VideoContentServiceProvider
& CollectionsServiceProvider
& DeviceServiceProvider
& ConfigurationProvider
& KeychainStorageProvider
& AccessTokenServiceProvider
& DownloadManagerProvider
& DownloadedFilesDatabaseProvider
& FileSaverProvider
& UserServiceProvider
& UserActionsServiceProvider
& LocalWatchProgressProvider
& TMDBServiceProvider

// MARK: - AppContext

struct AppContext: AppContextProtocol {
  
  var configuration: Configuration
  var authService: AuthorizationService
  var contentService: VideoContentService
  var collectionsService: CollectionsService
  var deviceService: DeviceService
  var accessTokenService: AccessTokenService
  var userService: UserService
  var keychainStorage: KeychainStorage
  var fileSaver: FileSaving
  var downloadManager: DownloadManager<DownloadMeta>
  var downloadedFilesDatabase: DownloadedFilesDatabase<DownloadMeta>
  var downloadNotificationManager: DownloadNotificationManager
  var seasonDownloadManager: SeasonDownloadManager
  var actionsService: UserActionsService
  var localProgressStore: LocalWatchProgressStore
  var tmdbService: TMDBService
  /// Offline HLS downloads (iOS). Accessed directly via `AppContext.shared` (not in the protocol).
  var hlsDownloadsStore: HLSDownloadsStore
  var hlsDownloadManager: HLSAssetDownloadManager

  static let shared: AppContext = {
    let configuration = BundleConfiguration()
    let keychainStorage = KeychainStorageImpl()
    let accessTokenService = AccessTokenServiceImpl(storage: keychainStorage)
    
    // Downloads
    
    let fileSaver = FileSaver()
    let downloadedFilesDatabase = DownloadedFilesDatabase<DownloadMeta>(fileSaver: fileSaver)
    let downloadsControlDatabase = DownloadsControlDatabase<DownloadMeta>(fileSaver: fileSaver)
    let downloadManager = DownloadManager<DownloadMeta>(fileSaver: fileSaver,
                                                        database: downloadedFilesDatabase,
                                                        controlDatabase: downloadsControlDatabase)
    let downloadNotificationManager = DownloadNotificationManager()
    let seasonDownloadManager = SeasonDownloadManager(downloadManager: downloadManager,
                                                      notifications: downloadNotificationManager)
    // Offline HLS downloads (iOS): keeps quality + all audio tracks + subtitles. Notifications mirror
    // the mp4 path. On macOS HLSAssetDownloadManager is a no-op shim (mp4 path is used there).
    let hlsDownloadsStore = HLSDownloadsStore()
    let hlsDownloadManager = HLSAssetDownloadManager(store: hlsDownloadsStore)
    hlsDownloadManager.onDownloadFinished = { [weak downloadNotificationManager] meta in
      downloadNotificationManager?.notifyFinished(title: meta.notificationTitle, identifier: "\(meta.id)")
    }
    hlsDownloadManager.onDownloadFailed = { [weak downloadNotificationManager] meta in
      downloadNotificationManager?.notifyFailed(title: meta.notificationTitle, identifier: "\(meta.id)")
    }
    hlsDownloadManager.restorePendingDownloads()
    // Post a local notification when a download finishes/fails. Episodes that belong to a bulk
    // season download are folded into a single "season downloaded" notification instead.
    downloadManager.onDownloadFinished = { [weak seasonDownloadManager, weak downloadNotificationManager] url, meta in
      let handledBySeason = seasonDownloadManager?.handleFinished(url: url) ?? false
      if !handledBySeason {
        downloadNotificationManager?.notifyFinished(title: meta.notificationTitle, identifier: "\(meta.id)")
      }
    }
    downloadManager.onDownloadFailed = { [weak downloadNotificationManager] _, meta, _ in
      downloadNotificationManager?.notifyFailed(title: meta.notificationTitle, identifier: "\(meta.id)")
    }
    // Api Client
    let apiClient = makeApiClient(with: configuration.baseURL, accessTokenService: accessTokenService)
    
    let authService = AuthorizationServiceImpl(apiClient: apiClient,
                                               configuration: configuration,
                                               accessTokenService: accessTokenService)
    return AppContext(configuration: configuration,
                      authService: authService,
                      contentService: VideoContentServiceImpl(apiClient: apiClient),
                      collectionsService: CollectionsServiceImpl(apiClient: apiClient),
                      deviceService: DeviceServiceImpl(apiClient: apiClient),
                      accessTokenService: accessTokenService,
                      userService: UserServiceImpl(apiClient: apiClient),
                      keychainStorage: keychainStorage,
                      fileSaver: fileSaver,
                      downloadManager: downloadManager,
                      downloadedFilesDatabase: downloadedFilesDatabase,
                      downloadNotificationManager: downloadNotificationManager,
                      seasonDownloadManager: seasonDownloadManager,
                      actionsService: UserActionsServiceImpl(apiClient: apiClient),
                      localProgressStore: LocalWatchProgressStore(),
                      tmdbService: TMDBServiceImpl(apiKey: configuration.tmdbAPIKey),
                      hlsDownloadsStore: hlsDownloadsStore,
                      hlsDownloadManager: hlsDownloadManager)
  }()
  
  // MARK: - API Client building
  
  private static func makeApiClient(with baseURL: String, accessTokenService: AccessTokenService) -> APIClient {
    APIClient(baseUrl: baseURL,
              plugins: [
                CURLLoggingPlugin(),
                ResponseLoggingPlugin(),
                AccessTokenPlugin(accessTokenService: accessTokenService)
              ],
              cache: ResponseCache())
  }
}
