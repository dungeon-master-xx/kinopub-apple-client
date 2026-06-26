//
//  SettingsView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 22.07.2023.
//
import SwiftUI
import KinoPubBackend
import KinoPubKit
import KinoPubUI
import SkeletonUI

struct ProfileView: View {

  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.appContext) var appContext
  @StateObject private var model: ProfileModel
  @AppStorage("selectedLanguage") private var selectedLanguage: String = (Locale.current.language.languageCode?.identifier ?? "en")
  /// Caps streaming quality; read by PlayerManager when building the AVPlayerItem.
  @AppStorage(StreamQuality.userDefaultsKey) private var streamQuality: StreamQuality = .auto

  @State private var showLogoutAlert: Bool = false
  @State private var showStorage: Bool = false
  @Environment(\.sectionEmbedded) private var sectionEmbedded

  init(model: @autoclosure @escaping () -> ProfileModel) {
    _model = StateObject(wrappedValue: model())
  }
  
  var body: some View {
    if sectionEmbedded {
      profileContent
    } else {
      NavigationStack { profileContent }
    }
  }

  private var profileContent: some View {
    ZStack {
        Color.KinoPub.background.edgesIgnoringSafeArea(.all)
        VStack(alignment: .leading) {
          Form {
            Section {
              LabeledContent("User Name", value: model.userData.username)
                .skeleton(enabled: model.userData.skeleton ?? false)
              LabeledContent("User Subscription",
                             value: "\(model.userData.subscription.remainingDays) \("days".localized) · \(model.userData.subscription.endDateFormatted)")
                .skeleton(enabled: model.userData.skeleton ?? false)
              LabeledContent("Registration Date", value: "\(model.userData.registrationDateFormatted)")
                .skeleton(enabled: model.userData.skeleton ?? false)
              LabeledContent("App version", value: Bundle.main.appVersionLong)
            }
              
            languageSection

            videoQualitySection

            Section {
              Button {
                showStorage = true
              } label: {
                LabeledContent("Storage".localized) {
                  Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.KinoPub.subtitle)
                }
              }
#if os(macOS)
              .buttonStyle(PlainButtonStyle())
#endif
            }

            Section {
              NavigationLink("Device settings".localized) {
                DeviceSettingsView(model: DeviceSettingsModel(deviceService: appContext.deviceService,
                                                              errorHandler: errorHandler))
              }
              NavigationLink("Devices".localized) {
                DevicesView(model: DevicesListModel(deviceService: appContext.deviceService,
                                                    errorHandler: errorHandler))
              }
            }

            Section {
              Button(action: {
                showLogoutAlert = true
              }, label: {
                Text("Logout").foregroundStyle(Color.red)
              })
              .skeleton(enabled: model.userData.skeleton ?? false)
#if os(macOS)
              .buttonStyle(PlainButtonStyle())
#endif
            }
          }
          .scrollContentBackground(.hidden)
          .background(Color.KinoPub.background)
        }
      }
      .kinoScreen("Profile".localized)
      .onAppear(perform: {
        model.fetch()
      })
      .sheet(isPresented: $showStorage) {
        StorageBreakdownView()
      }
      .alert("Are you sure?", isPresented: $showLogoutAlert) {
        Button("Logout", role: .destructive) { model.logout() }
        Button("Cancel", role: .cancel) { }
      }
      .alert(isPresented: $model.shouldShowExitAlert) {
        Alert(
          title: Text("Restarting the app"),
          message: Text("The app will restart to apply the language change."),
          primaryButton: .default(Text("OK")) {
            exit(0)
          },
          secondaryButton: .cancel()
        )
      }
  }
  private var videoQualitySection: some View {
    Section(header: Text("Video Quality"),
            footer: Text("Caps streaming quality. Auto lets the player adapt to your connection.".localized)) {
      Picker("Maximum Quality".localized, selection: $streamQuality) {
        ForEach(StreamQuality.allCases) { quality in
          Text(quality.title).tag(quality)
        }
      }
      .pickerStyle(MenuPickerStyle())
    }
  }

    private var languageSection: some View {
        Section(header: Text("Language")) {
            Picker("Select Language", selection: $selectedLanguage) {
                ForEach(model.availableLanguages.keys.sorted(), id: \.self) { key in
                    Text(model.availableLanguages[key] ?? key).tag(key)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedLanguage) { newLanguage in
                model.changeLanguage(to: newLanguage)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
  static var previews: some View {
    ProfileView(model: ProfileModel(userService: UserServiceMock(),
                                    errorHandler: ErrorHandler(),
                                    authState: AuthState(authService: AuthorizationServiceMock(),
                                                         accessTokenService: AccessTokenServiceMock())))
  }
}
