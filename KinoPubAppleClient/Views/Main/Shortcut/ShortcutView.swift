//
//  ShortcutView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 28.07.2023.
//

import Foundation
import SwiftUI
import KinoPubBackend
import KinoPubUI

/// The catalog sort picker (moved out of the filter modal — it's now the primary sort control).
struct SortSelectionView: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var sort: SortOption

  var body: some View {
    NavigationStack {
      Form {
        Section("Sort".localized) {
          Picker("Sort".localized, selection: $sort) {
            ForEach(SortOption.allCases) { option in
              Text(option.titleKey.localized)
                .tag(option)
            }
          }
          .pickerStyle(.inline)
        }
      }
      .formStyle(.grouped)
      .scrollContentBackground(.hidden)
      .background(Color.KinoPub.background)
      .navigationTitle("Sort".localized)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done".localized) {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium])
  }
}

struct SortSelectionView_Previews: PreviewProvider {
  static var previews: some View {
    SortSelectionView(sort: .constant(.updated))
  }
}
