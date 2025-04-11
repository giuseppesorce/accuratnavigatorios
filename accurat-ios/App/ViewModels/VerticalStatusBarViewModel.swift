//
//  VerticalStatusBarViewModel.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 07/04/25.
//

import Foundation

class VerticalStatusBarViewModel {
    var weatherStatus: String = "sunny" {
          didSet { notifyObservers() }
      }

      var hasWarning: Bool = false {
          didSet { notifyObservers() }
      }

      var distanceRemaining: String = "" {
          didSet { notifyObservers() }
      }

      var onDataChanged: (() -> Void)?

      func updateDistance(distance: String) {
          self.distanceRemaining = distance
      }

      private func notifyObservers() {
          onDataChanged?()
      }
}
