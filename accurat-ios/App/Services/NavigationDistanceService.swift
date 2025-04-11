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
                self?.handleSpokenInstruction(instruction)
            }
            .store(in: &cancellables)
    }

    private func handleRouteProgress(_ progress: RouteProgress) {
        let formatter = DistanceFormatter()
        let distance = formatter.string(from: progress.distanceRemaining)
        let formattedDistance = "In \(distance)"

        // Update horizontal view model
        weatherViewModel?.updateDistance(distance: formattedDistance)

        // Update vertical view model
        verticalViewModel?.updateDistance(distance: formattedDistance)

        // Check for congestion or other conditions that might require warnings
        updateWarningStatus(for: progress)
    }

    private func handleSpokenInstruction(_ instruction: SpokenInstruction) {
        // Check if instruction contains warning words
        let instructionText = instruction.text.lowercased()
        let warningKeywords = ["caution", "warning", "alert", "slow", "traffic", "congestion"]

        let containsWarning = warningKeywords.contains { instructionText.contains($0) }
        verticalViewModel?.hasWarning = containsWarning
    }

    private func updateWarningStatus(for progress: RouteProgress) {
        // Corretto: currentLegProgress è già una proprietà non opzionale
        let legProgress = progress.currentLegProgress

        // Corretto: upcomingStep è opzionale
        if let upcomingStep = legProgress.upcomingStep {
            // Corretto: Verifichiamo le condizioni di congestione in un modo diverso
            // poiché segmentCongestionLevels non è disponibile direttamente

            // Alternativa 1: Utilizzare altre proprietà per determinare la congestione
            let expectedTravelTime = upcomingStep.expectedTravelTime
            guard let typicalTravelTime = upcomingStep.typicalTravelTime else { return }

            // Se il tempo di percorrenza previsto è significativamente maggiore di quello tipico,
            // potrebbe esserci congestione
            let hasSevereCongestion = expectedTravelTime > (typicalTravelTime * 1.5)

            verticalViewModel?.hasWarning = hasSevereCongestion
        }
    }

    // Update weather status based on current conditions (example)
    func updateWeatherStatus(weatherCondition: String) {
        verticalViewModel?.weatherStatus = weatherCondition
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
