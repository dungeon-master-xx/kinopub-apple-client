//
//  FilterView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 4.08.2023.
//

import Foundation
import SwiftUI
import KinoPubBackend
import KinoPubUI

struct FilterView: View {

  @Environment(\.dismiss) private var dismiss
  @StateObject private var model: FilterModel

  private let onApply: (MediaItemsFilter) -> Void
  private let onClear: () -> Void

  private let yearRange = Array(1950...2026)

  init(model: @autoclosure @escaping () -> FilterModel = FilterModel(),
       onApply: @escaping (MediaItemsFilter) -> Void = { _ in },
       onClear: @escaping () -> Void = {}) {
    _model = StateObject(wrappedValue: model())
    self.onApply = onApply
    self.onClear = onClear
  }

  var body: some View {
    NavigationStack {
      Form {
        typeSection
        yearSection
        imdbRatingSection
      }
      .formStyle(.grouped)
      .scrollContentBackground(.hidden)
      .background(Color.KinoPub.background)
      .navigationTitle("Filter".localized)
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Clear".localized, role: .destructive) {
            model.clear()
            onClear()
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Apply".localized) {
            onApply(model.makeFilter())
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }

  var typeSection: some View {
    Section {
      Picker("Type".localized, selection: $model.mediaType) {
        ForEach(MediaType.allCases) { type in
          Text(type.title.localized)
            .tag(type)
        }
      }
      .pickerStyle(.menu)
    }
  }

  var yearSection: some View {
    Section {
      Toggle("Release Year".localized, isOn: $model.yearFilterEnabled)
      if model.yearFilterEnabled {
        yearPicker(title: "From".localized, selection: $model.yearMin)
        yearPicker(title: "To".localized, selection: $model.yearMax)
      }
    }
  }

  var imdbRatingSection: some View {
    Section {
      Toggle("IMDB Rating".localized, isOn: $model.imdbFilterEnabled)
      if model.imdbFilterEnabled {
        Stepper(value: $model.imdbMin, in: 0...10) {
          HStack {
            Text("From".localized)
            Spacer()
            Text("\(model.imdbMin)")
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }

  func yearPicker(title: String, selection: Binding<Int>) -> some View {
    Picker(title, selection: selection) {
      ForEach(yearRange, id: \.self) { year in
        Text(verbatim: "\(year)").tag(year)
      }
    }
    .pickerStyle(.menu)
  }
}

struct FilterView_Previews: PreviewProvider {
  static var previews: some View {
    FilterView(model: FilterModel(), onApply: { _ in }, onClear: {})
  }
}
