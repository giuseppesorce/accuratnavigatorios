//
//  Weather+Extensions.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 17/04/25.
//

import Foundation
import UIKit

// MARK: - Extensions for WeatherCondition
extension WeatherCondition {
    // Helper computed properties for weather icon handling

    // Get friendly weather description
    var description: String {
        let weatherComponent = weatherCode.split(separator: ":").last ?? ""
        let weatherKey = String(weatherComponent)

        if isDay {
            switch weatherKey {
            case "CL": return "Sunny"
            case "FW": return "Mostly Sunny"
            case "SC": return "Partly Cloudy"
            case "BK": return "Mostly Cloudy"
            case "OV": return "Overcast"
            case "A": return "Hail"
            case "BD": return "Blowing Dust"
            case "BN": return "Blowing Sand"
            case "BR": return "Mist"
            case "BS": return "Blowing Snow"
            case "BY": return "Blowing Spray"
            case "F": return "Fog"
            case "FC": return "Funnel Cloud"
            case "FR": return "Frost"
            case "H": return "Haze"
            case "IC": return "Ice Crystals"
            case "IF": return "Ice Fog"
            case "IP": return "Sleet"
            case "K": return "Smoke"
            case "L": return "Drizzle"
            case "R": return "Rain"
            case "RW": return "Rain Showers"
            case "RS": return "Rain/Snow Mix"
            case "SI": return "Snow/Sleet Mix"
            case "WM": return "Wintry Mix"
            case "S": return "Snow"
            case "SW": return "Snow Showers"
            case "T": return "Thunderstorms"
            case "TO": return "Tornado"
            case "UP": return "Unknown Precipitation"
            case "VA": return "Volcanic Ash"
            case "WP": return "Waterspouts"
            case "ZF": return "Freezing Fog"
            case "ZL": return "Freezing Drizzle"
            case "ZR": return "Freezing Rain"
            case "ZY": return "Freezing Spray"
            default: return "Unknown"
            }
        } else {
            switch weatherKey {
            case "CL": return "Clear"
            case "FW": return "Mostly Clear"
            case "SC": return "Partly Cloudy"
            case "BK": return "Mostly Cloudy"
            case "OV": return "Overcast"
            // For night, return the same descriptions for other weather conditions
            default: return description
            }
        }
    }

    // Get the icon name for this weather condition
    var iconName: String {
        let weatherComponent = weatherCode.split(separator: ":").last ?? ""
        let weatherKey = String(weatherComponent)

        // Return night version if it's not daytime
        return isDay ? weatherKey : "\(weatherKey)-night"
    }

    // Determine if the weather condition is severe (for warning indicators)
    var isSevere: Bool {
        let weatherComponent = weatherCode.split(separator: ":").last ?? ""
        let weatherKey = String(weatherComponent)

        // Weather codes that indicate severe conditions
        let severeWeatherCodes = ["T", "TO", "A", "BS", "FC", "WP", "RS", "WM", "ZR"]
        return severeWeatherCodes.contains(weatherKey)
    }

    // Get temperature description
    var temperatureDescription: String {
        return "\(Int(temperatureC))°C"
    }

    // Get precipitation description if applicable
    var precipitationDescription: String? {
        if precipitationProbability > 0 {
            return "\(precipitationProbability)%"
        }
        return nil
    }

    // Get color associated with this weather
    var color: UIColor {
        let weatherComponent = weatherCode.split(separator: ":").last ?? ""
        let weatherKey = String(weatherComponent).lowercased()

        // Determine color based on weather type
        switch weatherKey {
        case "cl", "fw": // Clear or fair/mostly sunny
            return UIColor(hex: "#FAC608") // Yellow

        case "sc", "bk", "ov": // Partly cloudy, mostly cloudy, overcast
            return UIColor(hex: "#3C7BF7") // Blue

        case "r", "rw", "l", "zr", "zl": // Rain, rain showers, drizzle, freezing rain/drizzle
            return UIColor(hex: "#6F3CFF") // Purple

        case "s", "sw", "ip", "si": // Snow, snow showers, sleet, snow/sleet mix
            return UIColor(hex: "#3C7BF7") // Blue

        case "t": // Thunderstorms
            return UIColor(hex: "#F45118") // Orange

        case "f", "h", "br", "if", "zf": // Fog, haze, mist, ice fog, freezing fog
            return UIColor(hex: "#6F3CFF") // Purple

        default:
            return UIColor(hex: "#FAC608") // Default yellow
        }
    }
}
