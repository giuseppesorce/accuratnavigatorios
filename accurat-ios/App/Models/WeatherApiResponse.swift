//
//  WeatherApiResponse.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 11/04/25.
//

import MapboxNavigation
import MapboxCoreNavigation
import SwiftUI
import Combine
import SnapKit

// MARK: - Weather API Models (/conditions/ endpoint)
struct WeatherApiResponse: Decodable {
    let success: Bool
    let error: String?
    let response: [WeatherLocationData]
}

struct WeatherLocationData: Decodable {
    let loc: WeatherLocation
    let place: WeatherPlace?
    let periods: [WeatherPeriod]
    let profile: WeatherProfile?
}

struct WeatherLocation: Decodable {
    let lat: Double
    let long: Double
}

struct WeatherPlace: Decodable {
    let name: String?
    let state: String?
    let country: String?
}

struct WeatherProfile: Decodable {
    let tz: String?
    let tzname: String?
    let tzoffset: Int?
    let isDST: Bool?
    let elevM: Double?
    let elevFT: Double?
}

struct WeatherPeriod: Decodable {
    // Campi base di timestamp e data
    let timestamp: Int
    let dateTimeISO: String

    // Temperatura e sensazione
    let tempC: Double?
    let tempF: Double?
    let feelslikeC: Double?
    let feelslikeF: Double?
    let dewpointC: Double?
    let dewpointF: Double?
    let humidity: Int?

    // Pressione
    let pressureMB: Double?
    let pressureIN: Double?
    let spressureMB: Double?
    let spressureIN: Double?
    let altimeterMB: Double?
    let altimeterIN: Double?

    // Vento
    let windDir: String?
    let windDirDEG: Int?
    let windSpeedKTS: Double?
    let windSpeedKPH: Double?
    let windSpeedMPH: Double?
    let windSpeedMPS: Double?
    let windGustKTS: Double?
    let windGustKPH: Double?
    let windGustMPH: Double?
    let windGustMPS: Double?

    // Precipitazioni
    let precipMM: Double?
    let precipIN: Double?
    let precipRateMM: Double?
    let precipRateIN: Double?
    let pop: Int?

    // Neve
    let snowCM: Double?
    let snowIN: Double?
    let snowRateCM: Double?
    let snowRateIN: Double?
    let snowDepthCM: Double?
    let snowDepthIN: Double?

    // Visibilità e cielo
    let visibilityKM: Double?
    let visibilityMI: Double?
    let sky: Int?
    let cloudsCoded: String?

    // Descrizione meteo
    let weather: String?
    let weatherCoded: String?
    let weatherPrimary: String?
    let weatherPrimaryCoded: String?
    let icon: String?

    // Dati solari
    let solradWM2: Int?
    let uvi: Int?
    let isDay: Bool?
    let solrad: WeatherSolarData?
}

struct WeatherSolarData: Decodable {
    let azimuthDEG: Double?
    let zenithDEG: Double?
    let ghiWM2: Double?
    let dniWM2: Double?
    let dhiWM2: Double?
    let version: String?
}

// MARK: - Modello interno per le condizioni meteo
struct WeatherCondition {
    let weatherCode: String
    let isDay: Bool
    let temperatureC: Double
    let precipitationProbability: Int

    var weatherDescription: String {
        let weatherComponent = weatherCode.split(separator: ":").last ?? ""
        let weatherKey = String(weatherComponent)

        if isDay {
            switch weatherKey {
            case "CL": return "Sunny"
            case "FW": return "Sunny" // "Fair/mostly sunny"
            case "SC": return "Partly cloudy"
            case "BK": return "Mostly cloudy"
            case "OV": return "Cloudy/overcast"
            case "A": return "Hail"
            case "BD": return "Blowing dust"
            case "BN": return "Blowing sand"
            case "BR": return "Mist"
            case "BS": return "Blowing snow"
            case "BY": return "Blowing spray"
            case "F": return "Fog"
            case "FC": return "Funnel Cloud"
            case "FR": return "Frost"
            case "H": return "Haze"
            case "IC": return "Ice crystals"
            case "IF": return "Ice fog"
            case "IP": return "Ice pellets / Sleet"
            case "K": return "Smoke"
            case "L": return "Drizzle"
            case "R": return "Rain"
            case "RW": return "Rain showers"
            case "RS": return "Rain/snow mix"
            case "SI": return "Snow/sleet mix"
            case "WM": return "Wintry mix (snow, sleet, rain)"
            case "S": return "Snow"
            case "SW": return "Snow showers"
            case "T": return "Thunderstorms"
            case "TO": return "Tornado"
            case "UP": return "Unknown precipitation"
            case "VA": return "Volcanic ash"
            case "WP": return "Waterspouts"
            case "ZF": return "Freezing fog"
            case "ZL": return "Freezing drizzle"
            case "ZR": return "Freezing rain"
            case "ZY": return "Freezing spray"
            default: return "Unknown"
            }
        } else {
            switch weatherKey {
            case "CL": return "Clear"
            case "FW": return "Fair/mostly clear"
            case "SC", "BK", "OV": return "Cloudy"
            default: return weatherDescription
            }
        }
    }

    var iconName: String {
        let weatherComponent = weatherCode.split(separator: ":").last ?? ""
        let weatherKey = String(weatherComponent)

        return isDay ? weatherKey : "\(weatherKey)-night"
    }
}
