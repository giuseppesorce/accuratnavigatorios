import MapboxNavigation
import MapboxCoreNavigation
import SwiftUI
import Combine
import SnapKit

// MARK: - Updated API Error Model
struct APIError: Decodable {
    let message: String
    let code: String

    init(from decoder: Decoder) throws {
        // Try to decode as dictionary first (most common case based on your response)
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let code = try? container.decode(String.self, forKey: .code),
           let description = try? container.decode(String.self, forKey: .description) {
            self.code = code
            self.message = description
            return
        }

        // Fallback to single value decoding
        let singleContainer = try decoder.singleValueContainer()
        do {
            let stringValue = try singleContainer.decode(String.self)
            self.message = stringValue
            self.code = "unknown"
        } catch {
            // If all decoding attempts fail
            self.message = "Unknown error format"
            self.code = "decode_error"
        }
    }

    enum CodingKeys: String, CodingKey {
        case code
        case description
    }
}

// MARK: - Road API Models (/roadweather/analytics/ endpoint)
struct RoadApiResponse: Decodable {
    let success: Bool
    let error: APIError?
    let response: [RoadLocationData]

    // Custom decoding to handle potential null response
    enum CodingKeys: String, CodingKey {
        case success, error, response
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decode(Bool.self, forKey: .success)
        error = try container.decodeIfPresent(APIError.self, forKey: .error)

        // Handle empty response arrays
        if let responseArray = try? container.decode([RoadLocationData].self, forKey: .response) {
            response = responseArray
        } else {
            response = []
        }
    }
}

struct RoadLocationData: Decodable {
    let id: String
    let dataSource: String
    let road: RoadInfo?
    let loc: RoadLocation
    let place: RoadPlace?
    let periods: [RoadPeriod]
    let profile: RoadProfile?
}

struct RoadInfo: Decodable {
    let type: String?
    let name: String?
}

struct RoadLocation: Decodable {
    let lat: Double
    let long: Double
}

struct RoadPlace: Decodable {
    let name: String?
    let state: String?
    let country: String?
}

struct RoadProfile: Decodable {
    let elevM: Double?
    let elevFT: Double?
    let tz: String?
}

// Aggiunto il protocollo Decodable a RoadPeriod
struct RoadPeriod: Decodable {
    // Campi obbligatori
    let timestamp: Int
    let dateTimeISO: String
    let summary: String?
    let summaryIndex: Int?
    let roadSurface: RoadSurfaceData?
    let riskProbability: [String: Double]?

    // Per gestire weatherConditions come dizionario generico
    let weatherConditions: [String: Any]?

    // Implementazione del protocollo Decodable per weatherConditions
    enum CodingKeys: String, CodingKey {
        case timestamp, dateTimeISO, summary, summaryIndex, roadSurface, riskProbability, weatherConditions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        timestamp = try container.decode(Int.self, forKey: .timestamp)
        dateTimeISO = try container.decode(String.self, forKey: .dateTimeISO)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        summaryIndex = try container.decodeIfPresent(Int.self, forKey: .summaryIndex)
        roadSurface = try container.decodeIfPresent(RoadSurfaceData.self, forKey: .roadSurface)
        riskProbability = try container.decodeIfPresent([String: Double].self, forKey: .riskProbability)

        // Per weatherConditions, che può essere null o un oggetto complesso
        if let weatherContainer = try? container.decodeNil(forKey: .weatherConditions), weatherContainer {
            weatherConditions = nil
        } else {
            // Poiché non possiamo decodificare direttamente in [String: Any],
            // lo gestiamo come null e ignoriamo il suo contenuto
            weatherConditions = nil
        }
    }
}

struct RoadSurfaceData: Decodable {
    let condition: String?
    let tempC: Double?
    let tempF: Double?
    let waterFilmThicknessMM: Double?
    let waterFilmThicknessIN: Double?
    let snowThicknessCM: Double?
    let snowThicknessIN: Double?
    let iceThicknessMM: Double?
    let iceThicknessIN: Double?
    let conditionProbability: [String: Double]
}

// MARK: - BatchResponse per le richieste batch
struct RoadBatchResponse: Decodable {
    let response: [RoadBatchItemResponse]
}

struct RoadBatchItemResponse: Decodable {
    let response: [RoadLocationData]?
    let error: String?
}

struct RoadCondition {
   enum RoadSurface: String {
       case dry = "Caution! Dry roads, potential hidden risks"
       case wet = "Warning! Wet roads increase skidding risk"
       case snow = "Hazard! Snow-covered roads are unsafe for biking"
       case ice = "Extreme Danger! Avoid riding on icy roads"

       // Metodo adattato per funzionare con i descrittori personalizzati
       static func fromProbabilities(_ probabilities: [String: Double]) -> RoadSurface? {
           // Trova la condizione con la probabilità più alta
           guard let maxEntry = probabilities.max(by: { $0.value < $1.value }),
                 maxEntry.value > 0 else {
               return nil
           }

           // Identificazione della condizione in base alla chiave
           let condition = maxEntry.key.lowercased()

           switch condition {
           case "dry":
               return .dry
           case "wet":
               return .wet
           case "snow":
               return .snow
           case "ice":
               return .ice
           default:
               return nil
           }
       }
   }

   enum RiskType: String {
       case hydroplane = "Hydroplaning risk"
       case lowVisFog = "Fog reducing visibility"
       case lowVisBlowingSnow = "Snow reducing visibility"
       case truckRollover = "Truck rollover risk"

       // Metodo adattato per utilizzare max invece del loop manuale
       static func fromProbabilities(_ probabilities: [String: Double]) -> RiskType? {
           // Trova il rischio con la probabilità più alta
           guard let maxEntry = probabilities.max(by: { $0.value < $1.value }),
                 maxEntry.value > 40 else { // Manteniamo la soglia del 40%
               return nil
           }

           // Verifica se la chiave corrisponde a uno dei casi dell'enum
           return RiskType(rawValue: maxEntry.key)
       }
   }

   let summaryIndex: Int
   let surfaceCondition: RoadSurface?
   let riskType: RiskType?
}
