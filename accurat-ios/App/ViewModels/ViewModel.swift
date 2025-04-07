//
//  ViewModel.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 03/04/25.
//

import Foundation
import Combine
import UIKit

class StatusBarViewModel: ObservableObject {
    @Published var weatherStatus: String = "Rainy"
    @Published var distanceInfo: String = "In 50 km"
    @Published var humidityPercentage: Int = 56

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupHumidityMonitoring()
    }

    func updateWeather(status: String) {
        weatherStatus = status
    }

    func updateDistance(distance: String) {
        distanceInfo = distance
    }

    private func setupHumidityMonitoring() {
        
    }
}
