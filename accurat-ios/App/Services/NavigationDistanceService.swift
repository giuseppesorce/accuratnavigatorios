import Foundation
import UIKit
import SwiftUI
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Combine

class NavigationDistanceService {
    private var cancellables = Set<AnyCancellable>()
    private weak var weatherViewModel: WeatherViewModel?
    private weak var verticalViewModel: VerticalStatusBarViewModel?

    init(horizontalViewModel: WeatherViewModel? = nil, verticalViewModel: VerticalStatusBarViewModel? = nil) {
        self.weatherViewModel = horizontalViewModel
        self.verticalViewModel = verticalViewModel
    }

    func startObserving() {
        // Observe route progress changes
        NotificationCenter.default.publisher(for: .routeControllerProgressDidChange)
            .compactMap { notification -> RouteProgress? in
                return notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            }
            .sink { [weak self] progress in
                self?.handleRouteProgress(progress)
            }
            .store(in: &cancellables)

        // Observe route alerts and warnings
        NotificationCenter.default.publisher(for: .routeControllerDidPassSpokenInstructionPoint)
            .compactMap { notification -> SpokenInstruction? in
                return notification.userInfo?[RouteController.NotificationUserInfoKey.spokenInstructionKey] as? SpokenInstruction
            }
            .sink { [weak self] instruction in
                // self?.handleSpokenInstruction(instruction)
            }
            .store(in: &cancellables)
    }

    private func handleRouteProgress(_ progress: RouteProgress) {
        let formatter = DistanceFormatter()
        let distance = formatter.string(from: progress.distanceRemaining)
        let formattedDistance = "In \(distance)"

        // Update horizontal view model
        weatherViewModel?.updateDistance(distance: formattedDistance)
        
        // Check for congestion or other conditions that might require warnings
        // updateWarningStatus(for: progress)
    }
}

// Extension to create a combined service
extension NavigationDistanceService {
    static func createCombinedService(horizontalViewModel: WeatherViewModel,
                                     verticalViewModel: VerticalStatusBarViewModel) -> NavigationDistanceService {
        return NavigationDistanceService(horizontalViewModel: horizontalViewModel,
                                        verticalViewModel: verticalViewModel)
    }
}
