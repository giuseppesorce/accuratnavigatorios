//
//  ViewModel.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 03/04/25.
//

import Foundation
import UIKit

class StatusBarViewModel {
    // Valori
    var weatherStatus: String = "Rainy" {
        didSet {
            onDataChanged?()
        }
    }

    var distanceInfo: String = "In 50 km" {
        didSet {
            onDataChanged?()
        }
    }

    var humidityPercentage: Int = 56 {
        didSet {
            onDataChanged?()
        }
    }

    // Callback per notificare i cambiamenti
    var onDataChanged: (() -> Void)?

    init() {
        setupHumidityMonitoring()
    }

    func updateWeather(status: String) {
        weatherStatus = status
    }

    func updateDistance(distance: String) {
        distanceInfo = distance
    }

    func updateHumidity(percentage: Int) {
        humidityPercentage = percentage
    }

    private func setupHumidityMonitoring() {
        
    }
}
