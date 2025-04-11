import MapboxNavigation
import MapboxCoreNavigation
import UIKit
import Combine
import Alamofire
import CoreLocation

// MARK: - XWeather Service
class XWeatherService {
    private let dateFormatter: ISO8601DateFormatter

    init() {
        dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    // MARK: - Weather Conditions
    func fetchWeatherConditions(for coordinate: CLLocationCoordinate2D, completion: @escaping (Result<WeatherCondition, Error>) -> Void) {
        let isoDate = dateFormatter.string(from: Date())
        let coordinateString = String(format: "%.7f,%.7f", coordinate.latitude, coordinate.longitude)

        let parameters: [String: Any] = [
            "client_id": XWeatherConfig.clientID,
            "client_secret": XWeatherConfig.clientSecret,
            "p": coordinateString,
            "from": isoDate
        ]

        print("🌤️ Fetching weather conditions for \(coordinateString)")

        var urlComponents = URLComponents(string: "\(XWeatherConfig.baseURL)/conditions/")!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }

        AF.request(urlComponents.url!, method: .get)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let weatherResponse = try decoder.decode(WeatherApiResponse.self, from: data)

                        guard let locationResponse = weatherResponse.response.first,
                              let periodData = locationResponse.periods.first else {
                            throw NSError(domain: "XWeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No weather data found"])
                        }

                        let weatherCode = periodData.weatherCoded ?? periodData.weatherPrimaryCoded ?? ""
                        let isDay = periodData.isDay ?? false
                        let temperatureC = periodData.tempC ?? 0
                        let precipitationProbability = periodData.pop ?? 0

                        let weatherCondition = WeatherCondition(
                            weatherCode: weatherCode,
                            isDay: isDay,
                            temperatureC: temperatureC,
                            precipitationProbability: precipitationProbability
                        )

                        completion(.success(weatherCondition))

                    } catch {
                        print("❌ Errore di decodifica JSON: \(error)")
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("❌ Errore di rete: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }

    // MARK: - Road Conditions
    func fetchRoadConditions(for coordinate: CLLocationCoordinate2D, completion: @escaping (Result<RoadCondition?, Error>) -> Void) {
        let now = Date()
        let fromDate = dateFormatter.string(from: now)
        let toDate = dateFormatter.string(from: now.addingTimeInterval(15 * 60))
        let coordinateString = String(format: "%.7f,%.7f", coordinate.latitude, coordinate.longitude)

        let parameters: [String: Any] = [
            "client_id": XWeatherConfig.clientID,
            "client_secret": XWeatherConfig.clientSecret,
            "p": coordinateString,
            "from": fromDate,
            "to": toDate
        ]

        print("🛣️ Fetching road conditions for \(coordinateString)")

        var urlComponents = URLComponents(string: "\(XWeatherConfig.baseURL)/roadweather/analytics/")!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }

        AF.request(urlComponents.url!, method: .get)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        // For debugging purposes
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("📊 Raw JSON response: \(jsonString)")
                        }

                        let decoder = JSONDecoder()
                        let roadResponse = try decoder.decode(RoadApiResponse.self, from: data)

                        // Handle the case where there's a warning but success is true
                        if roadResponse.response.isEmpty {
                            if let error = roadResponse.error {
                                print("⚠️ Warning: \(error.message)")

                                // Check for specific warning about no nearby roads
                                if error.code == "warn_no_data" {
                                    // Return nil instead of throwing an error
                                    completion(.success(nil))
                                    return
                                }
                            }

                            // For other cases with empty response
                            completion(.success(nil))
                            return
                        }

                        guard let locationResponse = roadResponse.response.first,
                              !locationResponse.periods.isEmpty,
                              let periodData = locationResponse.periods.first else {
                            throw NSError(domain: "XWeatherService",
                                          code: 2,
                                          userInfo: [NSLocalizedDescriptionKey: "No road data found"])
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

                    } catch {
                        print("❌ Errore di decodifica JSON: \(error)")
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("❌ Errore di rete: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }


    // MARK: - Batch Road Conditions
    func batchFetchRoadConditions(for coordinates: [CLLocationCoordinate2D], timeIntervals: [TimeInterval], completion: @escaping (Result<[RoadCondition], Error>) -> Void) {
        let now = Date()
        var requests = [String]()

        for (index, coordinate) in coordinates.enumerated() {
            let startTime = now.addingTimeInterval(timeIntervals[index])
            let endTime = startTime.addingTimeInterval(90 * 60)

            let fromDate = dateFormatter.string(from: startTime)
            let toDate = dateFormatter.string(from: endTime)

            let encodedCoordinate = String(format: "%.7f%%2C%.7f", coordinate.latitude, coordinate.longitude)
            let encodedFrom = fromDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fromDate
            let encodedTo = toDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toDate

            let request = "/roadweather/analytics/\(encodedCoordinate)?from=\(encodedFrom)&to=\(encodedTo)"
            requests.append(request)
        }

        let parameters: [String: Any] = [
            "client_id": XWeatherConfig.clientID,
            "client_secret": XWeatherConfig.clientSecret,
            "requests": requests.joined(separator: ",")
        ]

        AF.request(XWeatherConfig.batchURL, parameters: parameters)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let batchResponse = try decoder.decode(RoadBatchResponse.self, from: data)

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

                            roadConditions.append(RoadCondition(
                                summaryIndex: summaryIndex,
                                surfaceCondition: surfaceCondition,
                                riskType: riskType
                            ))
                        }

                        completion(.success(roadConditions))

                    } catch {
                        print("❌ Errore di decodifica JSON batch: \(error)")
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("❌ Errore di rete batch: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
}
