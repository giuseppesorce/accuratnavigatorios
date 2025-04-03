import SwiftUI
import UIKit

struct StatusBarView: View {
    var weatherStatus: String
    var distanceInfo: String
    var humidityPercentage: Int
    
    var body: some View {
        HStack {
            // Weather info (left side)
            HStack(spacing: 6) {
                Text(weatherIcon)
                    .font(.system(size: 18))
                Text(weatherStatus)
                    .font(.system(size: 18, weight: .medium))
            }
            .padding(.leading, 8)

            Spacer()

            // Distance (center)
            Text(distanceInfo)
                .font(.system(size: 18))

            Spacer()

            // Battery info (right side)
            HStack(spacing: 6) {
                Text("⚡")
                Text("\(humidityPercentage)%")
                    .font(.system(size: 18, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.4, green: 0.3, blue: 0.9))
            .cornerRadius(16)
            .padding(.trailing, 8)
        }
        .padding(.vertical, 10)
        .frame(height: 44)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .foregroundColor(.white)
        .cornerRadius(18)
    }

    private var weatherIcon: String {
        switch weatherStatus.lowercased() {
        case "rainy":
            return "🌧"
        case "sunny":
            return "☀️"
        case "cloudy":
            return "☁️"
        default:
            return "🌤"
        }
    }
}

struct StatusBarContainerView: UIViewRepresentable {
    @ObservedObject var viewModel: StatusBarViewModel

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Nessun aggiornamento necessario in questo caso
    }
}
