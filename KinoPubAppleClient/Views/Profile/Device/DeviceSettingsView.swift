//
//  DeviceSettingsView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 25.06.2026.
//

import SwiftUI
import KinoPubBackend
import KinoPubUI

struct DeviceSettingsView: View {

  @StateObject private var model: DeviceSettingsModel

  init(model: @autoclosure @escaping () -> DeviceSettingsModel) {
    _model = StateObject(wrappedValue: model())
  }

  var body: some View {
    ZStack {
      Color.KinoPub.background.edgesIgnoringSafeArea(.all)
      if model.isLoading {
        ProgressView()
      } else {
        form
      }
    }
    .navigationTitle("Device settings".localized)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save".localized) {
          Task { await model.save() }
        }
        .disabled(model.isLoading || model.isSaving)
      }
    }
    .task {
      await model.load()
    }
  }

  private var form: some View {
    Form {
      if !model.deviceTitle.isEmpty {
        Section {
          LabeledContent("Device".localized, value: model.deviceTitle)
        }
      }

      Section {
        // Stream-type and server options come straight from the server (ids + labels).
        Picker("Stream type".localized, selection: $model.settings.streamingType) {
          ForEach(model.settings.streamingTypeOptions) { option in
            Text(option.label).tag(option.id)
          }
        }

        Picker("Server location".localized, selection: $model.settings.serverLocation) {
          ForEach(model.settings.serverLocationOptions) { option in
            Text(option.label).tag(option.id)
          }
        }
      }

      Section {
        Toggle("4K".localized, isOn: $model.settings.support4k)
        Toggle("HEVC".localized, isOn: $model.settings.supportHevc)
      } footer: {
        Text("Changes take effect within a minute".localized)
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.KinoPub.background)
  }
}

struct DeviceSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DeviceSettingsView(model: DeviceSettingsModel(deviceService: DeviceServiceMock(),
                                                    errorHandler: ErrorHandler()))
    }
  }
}
