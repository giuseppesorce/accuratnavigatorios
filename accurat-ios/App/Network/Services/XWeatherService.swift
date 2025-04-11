//
//  XWeatherService.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 10/04/25.
//

import MapboxNavigation
import MapboxCoreNavigation
import SwiftUI
import Combine
import SnapKit
import Alamofire
import CoreLocation

// MARK: - XWeather Service

class XWeatherService {
    private let dateFormatter = ISO8601DateFormatter()

    // Fetch current weather conditions for a specific location
    func fetchWeatherConditions(for coordinate: CLLocationCoordinate2D, completion: @escaping (Result<WeatherCondition, Error>) -> Void) {
        let now = Date()
        let isoDate = dateFormatter.string(from: now)

        let parameters: [String: Any] = [
            "client_id": XWeatherConfig.clientID,
            "client_secret": XWeatherConfig.clientSecret,
            "p": "\(coordinate.latitude),\(coordinate.longitude)",
            "from": isoDate
        ]

        AF.request("\(XWeatherConfig.baseURL)/conditions/", parameters: parameters)
            .validate()
            .responseDecodable(of: WeatherResponse.self) { response in
                switch response.result {
                case .success(let weatherResponse):
                    guard let locationResponse = weatherResponse.response.first,
                          let periodData = locationResponse.periods.first else {
                        completion(.failure(NSError(domain: "XWeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No weather data found"])))
                        return
                    }

                    let weatherCondition = WeatherCondition(
                        weatherCode: periodData.weatherCoded,
                        isDay: periodData.isDay,
                        temperatureC: periodData.tempC,
                        precipitationProbability: periodData.pop
                    )

                    completion(.success(weatherCondition))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    // Fetch road conditions for a specific location
    func fetchRoadConditions(for coordinate: CLLocationCoordinate2D, completion: @escaping (Result<RoadCondition, Error>) -> Void) {
        let now = Date()
        let fromDate = dateFormatter.string(from: now)
        let toDate = dateFormatter.string(from: now.addingTimeInterval(15 * 60)) // 15 minutes from now

        let parameters: [String: Any] = [
            "client_id": XWeatherConfig.clientID,
            "client_secret": XWeatherConfig.clientSecret,
            "p": "\(coordinate.latitude),\(coordinate.longitude)",
            "from": fromDate,
            "to": toDate
        ]

        AF.request("\(XWeatherConfig.baseURL)/roadweather/analytics/", parameters: parameters)
            .validate()
            .responseDecodable(of: WeatherResponse.self) { response in
                switch response.result {
                case .success(let roadResponse):
                    guard let locationResponse = roadResponse.response.first,
                          let periodData = locationResponse.periods.first else {
                        completion(.failure(NSError(domain: "XWeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No road data found"])))
                        return
                    }

                    let summaryIndex = periodData.summaryIndex ?? 0

                    var surfaceCondition: RoadCondition.RoadSurface? = nil
                    var riskType: RoadCondition.RiskType? = nil

                    if let roadSurface = periodData.roadSurface {
                        surfaceCondition = RoadCondition.RoadSurface.fromProbabilities(roadSurface.conditionProbability)
                    }

                    if let riskProbability = periodData.riskProbability {
                        riskType = RoadCondition.RiskType.fromProbabilities(riskProbability)
                    }

                    let roadCondition = RoadCondition(
                        summaryIndex: summaryIndex,
                        surfaceCondition: surfaceCondition,
                        riskType: riskType
                    )

                    completion(.success(roadCondition))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    // Batch fetch road conditions for multiple route points
    func batchFetchRoadConditions(for coordinates: [CLLocationCoordinate2D], timeIntervals: [TimeInterval], completion: @escaping (Result<[RoadCondition], Error>) -> Void) {
        let now = Date()

        var requests = [String]()

        for (index, coordinate) in coordinates.enumerated() {
            let startTime = now.addingTimeInterval(timeIntervals[index])
            let endTime = startTime.addingTimeInterval(90 * 60) // 90 minutes window

            let fromDate = dateFormatter.string(from: startTime)
            let toDate = dateFormatter.string(from: endTime)

            // Format the request as required by the batch API
            let encodedCoordinate = String(format: "%f%%2C%f", coordinate.latitude, coordinate.longitude)
            let encodedFrom = fromDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fromDate
            let encodedTo = toDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toDate

            let request = "/roadweather/analytics/\(encodedCoordinate)?from=\(encodedFrom)&to=\(encodedTo)"
            requests.append(request)
        }

        let requestsParam = requests.joined(separator: ",")

        let parameters: [String: Any] = [
            "client_id": XWeatherConfig.clientID,
            "client_secret": XWeatherConfig.clientSecret,
            "requests": requestsParam
        ]

        AF.request(XWeatherConfig.batchURL, parameters: parameters)
            .validate()
            .responseDecodable(of: BatchResponse.self) { response in
                switch response.result {
                case .success(let batchResponse):
                    var roadConditions = [RoadCondition]()

                    for batchItem in batchResponse.response {
                        guard let locationResponses = batchItem.response,
                              let locationResponse = locationResponses.first,
                              let periodData = locationResponse.periods.first else {
                            continue
                        }

                        let summaryIndex = periodData.summaryIndex ?? 0

                        var surfaceCondition: RoadCondition.RoadSurface? = nil
                        var riskType: RoadCondition.RiskType? = nil

                        if let roadSurface = periodData.roadSurface {
                            surfaceCondition = RoadCondition.RoadSurface.fromProbabilities(roadSurface.conditionProbability)
                        }

                        if let riskProbability = periodData.riskProbability {
                            riskType = RoadCondition.RiskType.fromProbabilities(riskProbability)
                        }

                        let roadCondition = RoadCondition(
                            summaryIndex: summaryIndex,
                            surfaceCondition: surfaceCondition,
                            riskType: riskType
                        )

                        roadConditions.append(roadCondition)
                    }

                    completion(.success(roadConditions))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
