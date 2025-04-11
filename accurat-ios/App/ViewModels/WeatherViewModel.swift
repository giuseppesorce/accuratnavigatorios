import MapboxNavigation
import MapboxCoreNavigation
import UIKit
import CoreLocation
import Combine
import MapboxDirections

class WeatherViewModel: ObservableObject {
    // Published properties using Combine
    @Published var currentWeather: WeatherCondition?
    @Published var currentRoadCondition: RoadCondition?
    @Published var routeRoadConditions: [RoadCondition] = []
    @Published var distanceRemaining: String?

    @Published var isLoading: Bool = false
    @Published var weatherErrorMessage: String?
    @Published var roadErrorMessage: String?

    private let weatherService = XWeatherService()
    
    func updateDistance(distance: String) {
        self.distanceRemaining = distance
    }
    
    // Fetch both weather and road conditions at once
    func updateConditions(at coordinate: CLLocationCoordinate2D) {
        isLoading = true
        weatherErrorMessage = nil
        roadErrorMessage = nil

        let group = DispatchGroup()

        // Fetch weather
        group.enter()
        weatherService.fetchWeatherConditions(for: coordinate) { [weak self] result in
            defer { group.leave() }
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let weather):
                    self.currentWeather = weather
                case .failure(let error):
                    self.weatherErrorMessage = "Weather: \(error.localizedDescription)"
                }
            }
        }


        // Fetch road conditions
        group.enter()
        weatherService.fetchRoadConditions(for: coordinate) { [weak self] result in
            defer { group.leave() }
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let road):

                    if let road = road {
                        self.currentRoadCondition = road
                    } else {
                        print("No Road Available")
                        // No road data available
                        // self.showNoRoadDataMessage()
                    }
                 case .failure(let error):
                    if self.roadErrorMessage == nil {
                        self.roadErrorMessage = "Road: \(error.localizedDescription)"
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    // Fetch road conditions for points along a route
    func updateRouteRoadConditions(for route: Route) {
        // Get sampling points based on route duration
        let samplingPoints = getSamplingPoints(for: route)
        guard !samplingPoints.isEmpty else { return }

        isLoading = true
        weatherService.batchFetchRoadConditions(
            for: samplingPoints.map { $0.coordinate },
            timeIntervals: samplingPoints.map { $0.timeInterval }
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let conditions):
                    self.routeRoadConditions = conditions
                case .failure(let error):
                    self.roadErrorMessage = "Route conditions: \(error.localizedDescription)"
                }
            }
        }
    }

    // Helper method to determine points to check along route
    private func getSamplingPoints(for route: Route) -> [(coordinate: CLLocationCoordinate2D, timeInterval: TimeInterval)] {
        let routeDuration = route.expectedTravelTime
        let pointCount = min(max(Int(routeDuration / 3600), 1), 5) // 1-5 points (1 per hour)
        var samplingPoints: [(CLLocationCoordinate2D, TimeInterval)] = []

        if pointCount == 1, let midpoint = route.legs.first?.steps[route.legs.first!.steps.count / 2].maneuverLocation {
            // For short routes, just use the midpoint
            samplingPoints.append((midpoint, routeDuration / 2))
        } else {
            // For longer routes, distribute points evenly
            for i in 0..<pointCount {
                let progress = Double(i) / Double(pointCount - 1)
                let timeInterval = progress * routeDuration

                if let coordinate = getCoordinateAlongRoute(route: route, at: progress) {
                    samplingPoints.append((coordinate, timeInterval))
                }
            }
        }

        return samplingPoints
    }

    // Find a coordinate at a specific percentage along the route
    private func getCoordinateAlongRoute(route: Route, at progress: Double) -> CLLocationCoordinate2D? {
        let targetDistance = route.distance * progress
        var currentDistance: Double = 0

        for leg in route.legs {
            for step in leg.steps {
                let stepDistance = step.distance

                if currentDistance + stepDistance >= targetDistance {
                    // Found the step containing our target point
                    let stepProgress = (targetDistance - currentDistance) / stepDistance

                    if let coordinates = step.shape?.coordinates {
                        let index = Int(Double(coordinates.count - 1) * stepProgress)
                        if index < coordinates.count {
                            return coordinates[index]
                        }
                    }

                    return step.maneuverLocation // Fallback
                }

                currentDistance += stepDistance
            }
        }

        return route.legs.last?.steps.last?.maneuverLocation
    }
}
