
//
//  WeatherCondition+UI.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 18/04/25.
//

import UIKit

extension WeatherCondition {

    var precipitationProbabilityOffSet: Int {
        // Default 50
        return -1
    }

    // Returns the appropriate background color based on weather conditions
    func getBackgroundColor() -> UIColor {
        // High precipitation probability takes priority
        if shouldShowPrecipitation {
            return UIStyleKit.Colors.precipitationPurple // #6F3CFF
        }

        // Parse the weather code to get the main component
        let weatherComponent = weatherCode.split(separator: ":").last?.uppercased() ?? ""
        let code = String(weatherComponent)

        // Handle clear weather differently for day and night
        if code == "CL" || code == "FW" {
            return isDay ? UIStyleKit.Colors.weatherYellow : UIColor(hex: "#5A4734") // Day: #FAC608, Night: #5A4734
        }

        // Colors based on Figma design
        switch code {
            // Purple background (#6F3CFF)
        case "A", "BS", "BY", "FR", "IC", "IF", "IP", "L", "R", "RW", "RS", "SI", "WM", "S", "SW", "T", "UP", "WP", "ZL", "ZR", "ZY":
            return UIStyleKit.Colors.precipitationPurple

            // Gray background (#767676)
        case "BD", "BN", "BR", "F", "FC", "H", "K", "TO", "VA", "ZF":
            return UIColor(hex: "#767676")

            // Default case
        default:
            return UIColor(hex: "#767676") // Gray as fallback
        }
    }

    // Get the icon name for this weather condition
    var iconName: String {
        if shouldShowPrecipitation {
            return "drop"
        }
        let weatherComponent = weatherCode.split(separator: ":").last?.uppercased() ?? ""
        let code = String(weatherComponent)

        // For certain weather conditions, we need to differentiate between day and night
        if !isDay && (code == "CL" || code == "FW" || code == "SC" || code == "BK" || code == "OV" || code == "H") {
            return "\(code)-night"
        }

        return code
    }
    var shouldShowPrecipitation: Bool {
        return precipitationProbability > precipitationProbabilityOffSet
    }
}
